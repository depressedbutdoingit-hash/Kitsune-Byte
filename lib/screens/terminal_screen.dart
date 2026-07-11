import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final List<TerminalLine> _history = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _currentDir = '\~/myapp';
  String _hostname = 'kitsune@byte';
  bool _isExecuting = false;
  bool _learningMode = true; // Explains commands

  @override
  void initState() {
    super.initState();
    _printWelcome();
  }

  void _printWelcome() {
    _addOutput('🦊 Welcome to Kitsuné Terminal v4.0 — Sovereign Shell', type: LineType.info);
    _addOutput('The heart of the platform. Never leave. Never need to.', type: LineType.info);
    _addOutput('Type "kit help" or just start typing.', type: LineType.info);
    _addPrompt();
  }

  void _addOutput(String text, {LineType type = LineType.output}) {
    setState(() {
      _history.add(TerminalLine(text: text, type: type));
    });
    _scrollToBottom();
  }

  void _addPrompt() {
    setState(() {
      _history.add(TerminalLine(
        text: '$_hostname:$_currentDir\$ ',
        type: LineType.prompt,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeCommand(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      _addPrompt();
      return;
    }

    _addOutput(input, type: LineType.command);

    final parts = input.split(' ');
    final cmd = parts[0];

    setState(() => _isExecuting = true);

    // AI Pair Programmer simulation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (cmd == 'kit') {
        _handleKitCommand(parts.sublist(1));
      } else {
        _addOutput('🦊 Unknown command. Try "kit help"', type: LineType.ai);
      }

      if (_learningMode && cmd != 'help') {
        _addOutput('💡 Tip: Use "kit doctor" to check project health.', type: LineType.info);
      }

      setState(() => _isExecuting = false);
      _addPrompt();
      _controller.clear();
    });
  }

  void _handleKitCommand(List<String> args) {
    if (args.isEmpty) {
      _addOutput('kit <help|deploy|doctor|status|optimize|voice>', type: LineType.info);
      return;
    }

    final sub = args[0];
    switch (sub) {
      case 'help':
        _addOutput('''Available Kit Commands:
  deploy     → One-tap sovereign deploy
  doctor     → AI Project Doctor
  status     → Swarm + project status
  optimize   → Auto-fix & performance
  voice      → Activate voice builder''', type: LineType.info);
        break;

      case 'deploy':
        _addOutput('🚀 Building container...', type: LineType.success);
        _addOutput('✓ SSL • Database • CDN ready', type: LineType.success);
        _addOutput('🌐 Live at https://yourapp.kitsune.dev', type: LineType.success);
        break;

      case 'doctor':
        _addOutput('🔍 AI Project Doctor running...', type: LineType.ai);
        _addOutput('✓ No security issues', type: LineType.success);
        _addOutput('⚠ Consider adding offline mode', type: LineType.warning);
        break;

      case 'voice':
        _addOutput('🎤 "Hey Kitsuné" wake word activated. Speak your command...', type: LineType.ai);
        break;

      default:
        _addOutput('🦊 Trickster: "$sub" is powerful... in the next tail.', type: LineType.ai);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('Kitsuné Terminal'),
        actions: [
          IconButton(
            icon: Icon(_learningMode ? Icons.school : Icons.school_outlined),
            onPressed: () => setState(() => _learningMode = !_learningMode),
            tooltip: 'Toggle Learning Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final line = _history[index];
                Color color = Colors.white;
                if (line.type == LineType.error) color = Colors.redAccent;
                if (line.type == LineType.success) color = KitsuneTheme.foxOrange;
                if (line.type == LineType.ai) color = Colors.amber;

                return Text(
                  line.text,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
          // Persistent input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black.withOpacity(0.7),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter command... (kit help)',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    onSubmitted: _executeCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none, color: Colors.amber),
                  onPressed: () => _addOutput('🎤 Voice mode ready — say "Hey Kitsuné"', type: LineType.ai),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LineType { prompt, command, output, error, success, info, ai, warning }

class TerminalLine {
  final String text;
  final LineType type;
  TerminalLine({required this.text, required this.type});
}