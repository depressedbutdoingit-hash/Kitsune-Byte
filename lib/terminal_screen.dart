import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';
import 'openrouter_service.dart';
import 'db/database_helper.dart';
import 'services/shell/shell_backend.dart';
import 'services/shell/shell_policy.dart';
import 'services/ai/agent_tools.dart';
import 'models/terminal_entry.dart';
import 'widgets/tool_card.dart';

class TerminalScreen extends StatefulWidget {
  final String projectId;
  const TerminalScreen({super.key, required this.projectId});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final List<TerminalEntry> _history = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenRouterService _openRouter = OpenRouterService();
  final ShellRouter _shell = ShellRouter();
  final ShellPolicy _policy = ShellPolicy.instance;
  /// OpenAI-style messages (may include tool role objects).
  final List<Map<String, dynamic>> _chatMemory = [];

  bool _busy = false;
  String _backendName = '…';
  int? _streamingIndex;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _backendName = await _shell.activeName();
    setState(() {
      _history.add(TerminalEntry(
        kind: TerminalEntryKind.system,
        text:
            '🦊 Kitsuné Terminal ready · backend: $_backendName\n'
            'Type `help`, `$ ls`, `deploy`, `swarm`, or just talk to me.',
      ));
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: KitsuneTheme.fast,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _push(TerminalEntry e) {
    setState(() => _history.add(e));
    _scrollToEnd();
  }

  void _updateAt(int index, TerminalEntry e) {
    setState(() => _history[index] = e);
    _scrollToEnd();
  }

  // ── Command router ──────────────────────────────────────────

  Future<void> _submit() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty || _busy) return;
    _inputController.clear();
    _push(TerminalEntry(kind: TerminalEntryKind.input, text: raw));

    final route = _classify(raw);
    setState(() => _busy = true);
    try {
      switch (route.type) {
        case _RouteType.builtin:
          await _runBuiltin(route.payload);
          break;
        case _RouteType.shell:
          await _runShell(route.payload);
          break;
        case _RouteType.action:
          await _runAction(route.payload);
          break;
        case _RouteType.ai:
          await _runAi(route.payload);
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _Route _classify(String raw) {
    final lc = raw.toLowerCase().trim();

    // Explicit shell prefix: `$ ls -la` or `!uname`
    if (raw.startsWith(r'$ ') || raw.startsWith('!')) {
      final cmd = raw.startsWith(r'$ ') ? raw.substring(2) : raw.substring(1);
      return _Route(_RouteType.shell, cmd.trim());
    }

    // Built-ins
    const builtins = {
      'help',
      'clear',
      'status',
      'backend',
      'history',
    };
    if (builtins.contains(lc)) {
      return _Route(_RouteType.builtin, lc);
    }

    // App actions
    if (lc == 'deploy' || lc.startsWith('deploy ')) {
      return _Route(_RouteType.action, 'deploy');
    }
    if (lc == 'swarm' || lc.startsWith('swarm ') || lc.startsWith('swarm:')) {
      return _Route(_RouteType.action, 'swarm');
    }
    if (lc == 'builder' || lc == 'open builder') {
      return _Route(_RouteType.action, 'builder');
    }
    if (lc == 'ship') {
      return _Route(_RouteType.action, 'ship');
    }

    // Common shell verbs without prefix → shell
    final first = lc.split(RegExp(r'\s+')).first;
    const shellVerbs = {
      'ls',
      'pwd',
      'cd',
      'cat',
      'echo',
      'uname',
      'whoami',
      'flutter',
      'dart',
      'git',
      'npm',
      'pip',
      'python',
      'python3',
      'mkdir',
      'rm',
      'cp',
      'mv',
      'touch',
      'grep',
      'find',
      'curl',
      'wget',
      'chmod',
      'proot-distro',
      'pkg',
      'apt',
    };
    if (shellVerbs.contains(first)) {
      return _Route(_RouteType.shell, raw);
    }

    return _Route(_RouteType.ai, raw);
  }

  Future<void> _runBuiltin(String name) async {
    switch (name) {
      case 'clear':
        setState(() {
          _history.clear();
          _streamingIndex = null;
        });
        break;
      case 'help':
        _push(TerminalEntry(
          kind: TerminalEntryKind.system,
          text: '''Commands
  help, clear, status, backend
  deploy · swarm · builder · ship
  \$ <cmd>   force shell (also: !cmd)
  ls, pwd, flutter, git, …  auto-shell
  anything else → Kitsuné AI (streamed)''',
        ));
        break;
      case 'status':
        final project =
            await DatabaseHelper.instance.getProject(widget.projectId);
        _push(TerminalEntry(
          kind: TerminalEntryKind.system,
          text:
              'project: ${project?['name'] ?? widget.projectId}\n'
              'backend: $_backendName\n'
              'memory turns: ${_chatMemory.length ~/ 2}',
        ));
        break;
      case 'backend':
        _backendName = await _shell.activeName();
        _push(TerminalEntry(
          kind: TerminalEntryKind.system,
          text: 'active shell backend → $_backendName',
        ));
        break;
      case 'history':
        _push(TerminalEntry(
          kind: TerminalEntryKind.system,
          text: _chatMemory.isEmpty
              ? '(empty AI memory)'
              : _chatMemory.map((m) {
                  final role = m['role'];
                  final content = m['content'];
                  final tools = m['tool_calls'];
                  if (tools != null) return '$role: (tool_calls)';
                  return '$role: $content';
                }).join('\n'),
        ));
        break;
    }
  }

  /// Returns false if the user denied or policy blocked.
  Future<bool> _ensureShellConsent(String command) async {
    final verdict = _policy.check(command);
    if (verdict == null) return true;
    if (verdict != 'NEEDS_CONSENT') {
      _push(TerminalEntry(
        kind: TerminalEntryKind.error,
        text: '🛡️ $verdict',
      ));
      return false;
    }
    if (!mounted) return false;
    final bin = _policy.binaryOf(command);
    final choice = await showModalBottomSheet<ShellConsent>(
      context: context,
      backgroundColor: KitsuneTheme.deepCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ShellConsentSheet(binary: bin, command: command),
    );
    switch (choice) {
      case ShellConsent.allowAlways:
        _policy.allowAlways(bin);
        return true;
      case ShellConsent.allowSession:
        _policy.allowSession(bin);
        return true;
      case ShellConsent.ask:
        // one-shot
        return true;
      case ShellConsent.deny:
      case null:
        _push(const TerminalEntry(
          kind: TerminalEntryKind.system,
          text: '🛡️ command cancelled',
        ));
        return false;
    }
  }

  Future<String> _runShell(String command) async {
    final allowed = await _ensureShellConsent(command);
    if (!allowed) return 'blocked by policy';

    final toolIdx = _history.length;
    final sw = Stopwatch()..start();
    _backendName = await _shell.activeName();
    _push(TerminalEntry(
      kind: TerminalEntryKind.tool,
      text: '',
      toolName: 'shell',
      toolStatus: 'running',
      toolMeta: {'cmd': command, 'backend': _backendName},
      expanded: true,
    ));

    final buf = StringBuffer();
    try {
      await for (final chunk in _shell.runStream(command)) {
        buf.write(chunk);
        _updateAt(
          toolIdx,
          TerminalEntry(
            kind: TerminalEntryKind.tool,
            text: buf.toString(),
            toolName: 'shell',
            toolStatus: 'running',
            toolMeta: {
              'cmd': command,
              'backend': _backendName,
              'ms': '${sw.elapsedMilliseconds}',
            },
            expanded: true,
          ),
        );
      }
      sw.stop();
      final out = buf.isEmpty ? '(no output)' : buf.toString();
      _updateAt(
        toolIdx,
        TerminalEntry(
          kind: TerminalEntryKind.tool,
          text: out,
          toolName: 'shell',
          toolStatus: 'ok',
          toolMeta: {
            'cmd': command,
            'backend': _backendName,
            'exit': '0',
            'ms': '${sw.elapsedMilliseconds}',
          },
          expanded: true,
        ),
      );
      return out;
    } catch (e) {
      sw.stop();
      final out = buf.isEmpty ? 'error: $e' : '${buf.toString()}\nerror: $e';
      _updateAt(
        toolIdx,
        TerminalEntry(
          kind: TerminalEntryKind.tool,
          text: out,
          toolName: 'shell',
          toolStatus: 'fail',
          toolMeta: {
            'cmd': command,
            'backend': _backendName,
            'exit': '1',
            'ms': '${sw.elapsedMilliseconds}',
          },
          expanded: true,
        ),
      );
      return out;
    }
  }

  Future<void> _runAction(String action) async {
    final toolIdx = _history.length;
    _push(TerminalEntry(
      kind: TerminalEntryKind.tool,
      text: '',
      toolName: action,
      toolStatus: 'running',
      toolMeta: {'project': widget.projectId},
    ));

    // Simulate work; real navigation / deploy hooks in next pass.
    await Future.delayed(const Duration(milliseconds: 400));

    String summary;
    switch (action) {
      case 'deploy':
        summary = 'Opening deploy flow for ${widget.projectId}…';
        if (mounted) {
          Navigator.pushNamed(context, '/deploy', arguments: widget.projectId);
        }
        break;
      case 'swarm':
        summary = 'Dispatching AI swarm…';
        if (mounted) {
          Navigator.pushNamed(context, '/swarm', arguments: widget.projectId);
        }
        break;
      case 'builder':
        summary = 'Opening visual builder…';
        if (mounted) {
          Navigator.pushNamed(context, '/builder', arguments: widget.projectId);
        }
        break;
      case 'ship':
        summary =
            'ship pipeline: analyze → test → build → deploy\n'
            '(wire real steps next — currently a staged preview)';
        break;
      default:
        summary = 'unknown action: $action';
    }

    _updateAt(
      toolIdx,
      TerminalEntry(
        kind: TerminalEntryKind.tool,
        text: summary,
        toolName: action,
        toolStatus: 'ok',
        toolMeta: {'project': widget.projectId},
        expanded: true,
      ),
    );
  }

  Future<void> _runAi(String prompt) async {
    _chatMemory.add({'role': 'user', 'content': prompt});

    // Agent loop: model may emit tool_calls → we run tools → feed results back.
    const maxRounds = 4;
    try {
      for (var round = 0; round < maxRounds; round++) {
        final messages = <Map<String, dynamic>>[
          {'role': 'system', 'content': AgentTools.systemPromptWithTools},
          ..._chatMemory,
        ];

        final turn = await _openRouter.chatCompletion(
          model: 'anthropic/claude-3.5-haiku',
          messages: messages,
          userId: widget.projectId,
          tools: AgentTools.definitions,
        );

        if (!turn.hasToolCalls) {
          // Final natural-language reply — stream for feel if we have content,
          // otherwise use the non-stream body we already got.
          final text = turn.content.trim();
          if (text.isEmpty) {
            _push(const TerminalEntry(
              kind: TerminalEntryKind.system,
              text: '🦊 (no reply)',
            ));
          } else {
            _push(TerminalEntry(
              kind: TerminalEntryKind.output,
              text: '🦊 $text',
            ));
            _chatMemory.add({'role': 'assistant', 'content': text});
          }
          return;
        }

        // Record assistant tool_calls message
        _chatMemory.add({
          'role': 'assistant',
          'content': turn.content,
          'tool_calls': turn.toolCalls,
        });

        for (final raw in turn.toolCalls) {
          final call = ToolCall.fromJson(raw);
          final result = await _executeAgentTool(call);
          _chatMemory.add({
            'role': 'tool',
            'tool_call_id': call.id,
            'content': result,
          });
        }
      }
      _push(const TerminalEntry(
        kind: TerminalEntryKind.system,
        text: '🦊 tool loop limit reached — tell me what to do next.',
      ));
    } catch (e) {
      _push(TerminalEntry(
        kind: TerminalEntryKind.error,
        text:
            '🦊 bridge hiccup (${e.runtimeType}). '
            'Check OPENROUTER_API_KEY or try `\$ ls` offline.',
      ));
    }
  }

  Future<String> _executeAgentTool(ToolCall call) async {
    switch (call.name) {
      case 'run_shell':
        final cmd = '${call.arguments['command'] ?? ''}';
        if (cmd.trim().isEmpty) return 'error: empty command';
        return _runShell(cmd);
      case 'open_screen':
        final route = '${call.arguments['route'] ?? ''}';
        await _runAction(route);
        return 'opened /$route';
      case 'get_status':
        final project =
            await DatabaseHelper.instance.getProject(widget.projectId);
        final text =
            'project: ${project?['name'] ?? widget.projectId}\n'
            'backend: $_backendName\n'
            'policy: ${_policy.toJson()}';
        _push(TerminalEntry(kind: TerminalEntryKind.system, text: text));
        return text;
      default:
        return 'unknown tool: ${call.name}';
    }
  }

  // ── UI ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kitsuné Terminal'),
            Text(
              _backendName,
              style: KitsuneTheme.label(color: KitsuneTheme.mistSilver),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(() {
              _history.clear();
              _streamingIndex = null;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _history.length + (_busy && _streamingIndex == null ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _history.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KitsuneTheme.foxGlow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'working…',
                          style: KitsuneTheme.bodyMono(
                            color: KitsuneTheme.mistSilver,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _buildEntry(_history[i], i);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: KitsuneTheme.mistSilver.withOpacity(0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '❯',
                    style: KitsuneTheme.bodyMono(color: KitsuneTheme.foxOrange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_busy,
                      style: KitsuneTheme.bodyMono(
                        color: KitsuneTheme.warmCream,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'help · \$ ls · deploy · talk to me',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _busy
                          ? KitsuneTheme.mistSilver
                          : KitsuneTheme.foxGlow,
                      size: 18,
                    ),
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(TerminalEntry e, int index) {
    switch (e.kind) {
      case TerminalEntryKind.input:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '❯ ',
                  style: KitsuneTheme.bodyMono(color: KitsuneTheme.foxOrange),
                ),
                TextSpan(
                  text: e.text,
                  style: KitsuneTheme.bodyMono(color: KitsuneTheme.warmCream),
                ),
              ],
            ),
          ),
        );
      case TerminalEntryKind.tool:
        return ToolUseCard(
          entry: e,
          onToggle: () {
            setState(() {
              _history[index] = e.copyWith(expanded: !e.expanded);
            });
          },
        );
      case TerminalEntryKind.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            e.text,
            style: KitsuneTheme.bodyMono(color: KitsuneTheme.emberRed),
          ),
        );
      case TerminalEntryKind.system:
      case TerminalEntryKind.output:
      case TerminalEntryKind.stream:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SelectableText(
            e.text,
            style: KitsuneTheme.bodyMono(
              color: e.kind == TerminalEntryKind.system
                  ? KitsuneTheme.mistSilver
                  : KitsuneTheme.mistPearl,
            ),
          ),
        );
    }
  }
}

enum _RouteType { builtin, shell, action, ai }

class _Route {
  final _RouteType type;
  final String payload;
  const _Route(this.type, this.payload);
}

/// Bottom sheet: allow once / session / always / deny for a binary.
class _ShellConsentSheet extends StatelessWidget {
  final String binary;
  final String command;
  const _ShellConsentSheet({required this.binary, required this.command});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allow shell?', style: KitsuneTheme.displayMedium()),
          const SizedBox(height: 8),
          Text(
            'Binary `$binary` is not on the allowlist yet.',
            style: KitsuneTheme.bodyLarge(),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              command,
              style: KitsuneTheme.bodyMono(color: KitsuneTheme.foxGlow),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, ShellConsent.ask),
                child: const Text('Once'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, ShellConsent.allowSession),
                child: const Text('This session'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, ShellConsent.allowAlways),
                child: const Text('Always'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, ShellConsent.deny),
                child: Text(
                  'Deny',
                  style: TextStyle(color: KitsuneTheme.emberRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
