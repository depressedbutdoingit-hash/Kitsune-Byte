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

  @override
  void initState() {
    super.initState();
    _printWelcome();
  }

  void _printWelcome() {
    _addOutput('🦊 Kitsuné Terminal v4.0 — Sovereign Shell', type: LineType.info);
    _addOutput('The heart of Kitsuné Byte. Type "kit help" for power.', type: LineType.info);
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
          duration: const Duration(milliseconds: 300),
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

    // Echo the command
    _addOutput(input, type: LineType.command);

    final parts = input.trim().split(' ');
    final cmd = parts[0];

    // Simulate AI Pair Programmer (future hook)
    if (cmd == 'kit') {
      _handleKitCommand(parts.sublist(1));
    } else {
      _addOutput('Command not found: $cmd. Try "kit help"', type: LineType.error);
    }

    _addPrompt();
    _controller.clear();
  }

  void _handleKitCommand(List<String> args) {
    if (args.isEmpty) {
      _addOutput('Usage: kit <help|init|deploy|doctor|status|...>', type: LineType.info);
      return;
    }

    final subCmd = args[0];
    switch (subCmd) {
      case 'help':
        _addOutput('Available commands: init, deploy, doctor, status, optimize, voice...', type: LineType.info);
        break;
      case 'deploy':
        _addOutput('🚀 Deploying to Kitsuné Cloud...', type: LineType.success);
        _addOutput('SSL issued • Domain active • Live at https://myapp.kitsune.dev', type: LineType.success);
        break;
      case 'doctor':
        _addOutput('🔍 AI Project Doctor: No issues found. You\'re in great shape, builder.', type: LineType.success);
        break;
      default:
        _addOutput('🦊 Trickster Mode: "$subCmd" coming in v4.1', type: LineType.ai);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KitsuneTheme.deepCharcoal,
      appBar: AppBar(
        title: const Text('Kitsuné Terminal'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Output area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final line = _history[index];
                return Text(
                  line.text,
                  style: line.type == LineType.error 
                      ? const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')
                      : line.type == LineType.success
                          ? TextStyle(color: Kits