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
  final FocusNode _focusNode = FocusNode();

  String _currentDir = '~/myapp';
  String _hostname = 'kitsune@byte';
  bool _isExecuting = false;

  // Kit command registry
  final Map<String, KitCommand> _kitCommands = {
    'help': KitCommand(
      name: 'help',
      description: 'Show available commands',
      usage: 'kit help',
      handler: _cmdHelp,
    ),
    'init': KitCommand(
      name: 'init',
      description: 'Initialize a new project',
      usage: 'kit init <framework> <name>',
      handler: _cmdInit,
    ),
    'add': KitCommand(
      name: 'add',
      description: 'Add a feature to project',
      usage: 'kit add <feature>',
      handler: _cmdAdd,
    ),
    'install': KitCommand(
      name: 'install',
      description: 'Install package with offline cache',
      usage: 'kit install <package>',
      handler: _cmdInstall,
    ),
    'deploy': KitCommand(
      name: 'deploy',
      description: 'Deploy to Kitsuné Cloud',
      usage: 'kit deploy',
      handler: _cmdDeploy,
    ),
    'doctor': KitCommand(
      name: 'doctor',
      description: 'Run AI project health check',
      usage: 'kit doctor',
      handler: _cmdDoctor,
    ),
    'status': KitCommand(
      name: 'status',
      description: 'Show project and swarm status',
      usage: 'kit status',
      handler: _cmdStatus,
    ),
    'build': KitCommand(
      name: 'build',
      description: 'Build the project',
      usage: 'kit build',
      handler: _cmdBuild,
    ),
    'optimize': KitCommand(
      name: 'optimize',
      description: 'Auto-fix performance issues',
      usage: 'kit optimize',
      handler: _cmdOptimize,
    ),
    'git': KitCommand(
      name: 'git',
      description: 'Git operations (commit, push, pull)',
      usage: 'kit git <command>',
      handler: _cmdGit,
    ),
    'db': KitCommand(
      name: 'db',
      description: 'Database operations',
      usage: 'kit db <command>',
      handler: _cmdDb,
    ),
  };

  // Standard shell commands
  final Map<String, Function(List<String>)> _shellCommands = {
    'ls': _cmdLs,
    'cd': _cmdCd,
    'pwd': _cmdPwd,
    'clear': _cmdClear,
    'echo': _cmdEcho,
    'cat': _cmdCat,
    'mkdir': _cmdMkdir,
    'rm': _cmdRm,
    'whoami': _cmdWhoami,
    'date': _cmdDate,
  };

  @override
  void initState() {
    super.initState();
    _printWelcome();
  }

  void _printWelcome() {
    _addOutput('Kitsuné Shell v1.0.0 — Linux aarch64', type: LineType.info);
    _addOutput('Type "kit help" for available commands', type: LineType.info);
    _addOutput('Type "help" for shell commands', type: LineType.info);
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
        text: '$_hostname:$_currentDir\$',
        type: LineType.prompt,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeCommand(String input) {
    if (input.trim().isEmpty) {
      _addPrompt();
      return;
    }

    setState(() {
      _history.last = TerminalLine(
        text: '$_hostname:$_currentDir\$ $input',
        type: LineType.prompt,
      );
    });

    final parts = input.trim().split(' ');
    final command = parts[0];
    final args = parts.sublist(1);

    setState(() => _isExecuting = true);

    if (command == 'kit') {
      if (args.isEmpty) {
        _addOutput('Usage: kit <command>', type: LineType.error);
        _addOutput('Type "kit help" for available commands', type: LineType.info);
      } else {
        final kitCmd = args[0];
        final kitArgs = args.sublist(1);
        final kitCommand = _kitCommands[kitCmd];
        
        if (kitCommand != null) {
          final result = kitCommand.handler(kitArgs);
          _processCommandResult(result);
        } else {
          _addOutput('Unknown kit command: $kitCmd', type: LineType.error);
          _addOutput('Type "kit help" for available commands', type: LineType.info);
        }
      }
    } else if (_shellCommands.containsKey(command)) {
      final result = _shellCommands[command]!(args);
      _processCommandResult(result);
    } else {
      _addOutput('Command not found: $command', type: LineType.error);
      _addOutput('Type "kit help" or "help" for available commands', type: LineType.info);
    }

    setState(() => _isExecuting = false);
    _addPrompt();
    _controller.clear();
  }

  void _processCommandResult(List<String> output) {
    for (final line in output) {
      if (line.startsWith('✓')) {
        _addOutput(line, type: LineType.success);
      } else if (line.startsWith('⚠') || line.startsWith('!')) {
        _addOutput(line, type: LineType.warning);
      } else if (line.startsWith('✗') || line.startsWith('Error')) {
        _addOutput(line, type: LineType.error);
      } else if (line.startsWith('🚀') || line.startsWith('🦊')) {
        _addOutput(line, type: LineType.ai);
      } else {
        _addOutput(line, type: LineType.output);
      }
    }
  }

  // ============== KIT COMMANDS ==============

  static List<String> _cmdHelp(List<String> args) {
    return [
      'Available kit commands:',
      '',
      '  init <framework> <name>    Initialize a new project',
      '  add <feature>              Add feature (auth, db, api, etc.)',
      '  install <package>          Install package with offline cache',
      '  deploy                     Deploy to Kitsuné Cloud',
      '  doctor                     Run AI project health check',
      '  status                     Show project and swarm status',
      '  build                      Build the project',
      '  optimize                   Auto-fix performance issues',
      '  git <command>              Git operations',
      '  db <command>               Database operations',
      '',
      'Shell commands: ls, cd, pwd, clear, echo, cat, mkdir, rm, whoami, date',
    ];
  }

  static List<String> _cmdInit(List<String> args) {
    if (args.length < 2) {
      return ['Error: Usage: kit init <framework> <name>'];
    }
    final framework = args[0];
    final name = args[1];
    
    return [
      '✓ Project initialized with ${framework.toUpperCase()} + TypeScript',
      '✓ KitsunéDB configured (SQLite, local)',
      '✓ AI Swarm agents activated',
      '✓ Offline cache initialized',
      '',
      'Next steps:',
      '  cd $name',
      '  kit add auth',
      '  kit deploy',
    ];
  }

  static List<String> _cmdAdd(List<String> args) {
    if (args.isEmpty) {
      return ['Error: Usage: kit add <feature>'];
    }
    final feature = args[0];
    
    final features = {
      'auth': ['✓ Authentication flow generated', '✓ Security Agent: No vulnerabilities detected', '✓ JWT tokens configured'],
      'db': ['✓ Database schema generated', '✓ Migrations ready', '✓ Realtime subscriptions enabled'],
      'api': ['✓ REST API endpoints generated', '✓ OpenAPI spec created', '✓ Rate limiting configured'],
      'storage': ['✓ File storage configured', '✓ Image optimization enabled', '✓ CDN rules applied'],
      'payments': ['✓ Stripe integration configured', '✓ Webhook endpoints ready', '✓ Test mode enabled'],
    };

    if (features.containsKey(feature)) {
      return ['Adding $feature...', ...features[feature]!];
    }
    return ['Error: Unknown feature: $feature', 'Available: auth, db, api, storage, payments'];
  }

  static List<String> _cmdInstall(List<String> args) {
    if (args.isEmpty) {
      return ['Error: Usage: kit install <package>'];
    }
    final package = args[0];
    return [
      'Installing $package...',
      '✓ Downloaded from registry',
      '✓ Cached locally (offline ready)',
      '✓ Added to dependencies',
      '',
      '🦊 Swarm: "$package" has 3 known vulnerabilities. Update available.',
      '  Run "kit audit" to review',
    ];
  }

  static List<String> _cmdDeploy(List<String> args) {
    return [
      'Building project...',
      '✓ Dependencies resolved',
      '✓ Type check passed',
      '✓ Bundle optimized (142KB)',
      '',
      'Deploying to Kitsuné Cloud...',
      '✓ Container built',
      '✓ Database migrated',
      '✓ SSL certificate issued',
      '✓ Domain configured',
      '',
      '🚀 Live at https://myapp.kitsune.io',
      '',
      '🦊 Swarm: "Your image uploads are costing \$18/month. Use WebP conversion?"',
      '  [Fix Now] [Ignore]',
    ];
  }

  static List<String> _cmdDoctor(List<String> args) {
    return [
      '🔍 AI Project Doctor',
      '',
      '✓ No security vulnerabilities found',
      '✓ Bundle size: 142KB (healthy)',
      '⚠ 3 unused dependencies detected',
      '  - lodash (use native methods)',
      '  - moment (use date-fns)',
      '  - axios (use fetch)',
      '',
      '💡 Run "kit optimize" to auto-fix',
    ];
  }

  static List<String> _cmdStatus(List<String> args) {
    return [
      '🦊 Swarm Status:',
      '  UI Agent:        idle',
      '  Code Agent:      idle',
      '  Security Agent:  idle',
      '  Performance Agent: idle',
      '  Deploy Agent:    idle',
      '',
      'Project: myapp (React + TypeScript)',
      'Database: SQLite (local)',
      'Sync:     Last synced 2 min ago',
      'Mode:     Offline-ready',
    ];
  }

  static List<String> _cmdBuild(List<String> args) {
    return [
      'Building...',
      '✓ Cleaning build directory',
      '✓ Compiling TypeScript',
      '✓ Optimizing assets',
      '✓ Minifying bundle',
      '',
      'Build complete in 4.2s',
      'Output: build/web/',
      '',
      '💡 Run "kit deploy" to publish',
    ];
  }

  static List<String> _cmdOptimize(List<String> args) {
    return [
      '🔧 Optimizing...',
      '✓ Removed 3 unused dependencies',
      '✓ Converted images to WebP',
      '✓ Enabled lazy loading',
      '✓ Minified CSS',
      '',
      'Estimated savings: \$18/month',
      'Bundle reduced: 142KB → 98KB',
    ];
  }

  static List<String> _cmdGit(List<String> args) {
    if (args.isEmpty) return ['Usage: kit git <commit|push|pull|status|log>'];
    final subcmd = args[0];
    
    switch (subcmd) {
      case 'status':
        return [
          'On branch main',
          'Your branch is up to date with origin/main',
          '',
          'Changes to be committed:',
          '  modified:   lib/main.dart',
          '  new file:   lib/screens/settings_screen.dart',
        ];
      case 'commit':
        return ['✓ Committed with message: "${args.sublist(1).join(' ')}"', '✓ SHA: a1b2c3d4'];
      case 'log':
        return [
          'a1b2c3d  feat: add settings screen',
          'e5f6g7h  fix: terminal scroll issue',
          'i8j9k0l  chore: update dependencies',
        ];
      default:
        return ['Git command: $subcmd completed'];
    }
  }

  static List<String> _cmdDb(List<String> args) {
    if (args.isEmpty) return ['Usage: kit db <migrate|seed|backup|restore>'];
    return ['✓ Database operation completed: ${args[0]}'];
  }

  // ============== SHELL COMMANDS ==============

  static List<String> _cmdLs(List<String> args) {
    return [
      'drwxr-xr-x  lib/',
      'drwxr-xr-x  assets/',
      '-rw-r--r--  pubspec.yaml',
      '-rw-r--r--  README.md',
      '-rw-r--r--  .gitignore',
    ];
  }

  static List<String> _cmdCd(List<String> args) {
    if (args.isEmpty) return ['Error: Usage: cd <directory>'];
    return ['Changed directory to ${args[0]}'];
  }

  static List<String> _cmdPwd(List<String> args) => ['/home/kitsune/myapp'];
  static List<String> _cmdClear(List<String> args) => ['__CLEAR__'];
  static List<String> _cmdEcho(List<String> args) => [args.join(' ')];
  static List<String> _cmdCat(List<String> args) => ['File contents...'];
  static List<String> _cmdMkdir(List<String> args) => ['✓ Created directory ${args[0]}'];
  static List<String> _cmdRm(List<String> args) => ['✓ Removed ${args[0]}'];
  static List<String> _cmdWhoami(List<String> args) => ['kitsune'];
  static List<String> _cmdDate(List<String> args) => [DateTime.now().toString()];

  // ============== UI ==============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.background,
      appBar: AppBar(
        backgroundColor: KitsuneTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KitsuneTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.terminal, color: KitsuneTheme.kitsuneOrange, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Kitsuné Shell',
              style: TextStyle(
                color: KitsuneTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KitsuneTheme.kitsuneTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: KitsuneTheme.kitsuneTeal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: KitsuneTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: KitsuneTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0D0D0D),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final line = _history[index];
                  return _buildLine(line);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KitsuneTheme.surface,
              border: Border(
                top: BorderSide(color: KitsuneTheme.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: KitsuneTheme.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: const TextStyle(color: KitsuneTheme.textTertiary),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          '❯',
                          style: TextStyle(
                            color: KitsuneTheme.kitsuneTeal,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 0),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _executeCommand,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: KitsuneTheme.kitsuneViolet),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: KitsuneTheme.kitsuneTeal),
                  onPressed: () => _executeCommand(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(TerminalLine line) {
    Color textColor;
    switch (line.type) {
      case LineType.prompt:
        textColor = KitsuneTheme.kitsuneTeal;
        break;
      case LineType.success:
        textColor = KitsuneTheme.kitsuneTeal;
        break;
      case LineType.error:
        textColor = KitsuneTheme.error;
        break;
      case LineType.warning:
        textColor = KitsuneTheme.warning;
        break;
      case LineType.ai:
        textColor = KitsuneTheme.kitsuneViolet;
        break;
      case LineType.info:
        textColor = KitsuneTheme.textSecondary;
        break;
      default:
        textColor = KitsuneTheme.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        line.text,
        style: TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

// ============== TYPES ==============

enum LineType {
  output,
  prompt,
  success,
  error,
  warning,
  ai,
  info,
}

class TerminalLine {
  final String text;
  final LineType type;

  TerminalLine({required this.text, this.type = LineType.output});
}

class KitCommand {
  final String name;
  final String description;
  final String usage;
  final List<String> Function(List<String>) handler;

  KitCommand({
    required this.name,
    required this.description,
    required this.usage,
    required this.handler,
  });
}
