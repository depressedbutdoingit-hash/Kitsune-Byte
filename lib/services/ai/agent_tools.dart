import 'dart:convert';

/// Tool definitions for OpenRouter / OpenAI-compatible function calling.
class AgentTools {
  static const List<Map<String, dynamic>> definitions = [
    {
      'type': 'function',
      'function': {
        'name': 'run_shell',
        'description':
            'Run a shell command on the device (Termux bridge or simulated). '
            'Use for ls, git, flutter, pwd, etc. Prefer short non-destructive commands.',
        'parameters': {
          'type': 'object',
          'properties': {
            'command': {
              'type': 'string',
              'description': 'Shell command to execute',
            },
          },
          'required': ['command'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_screen',
        'description': 'Navigate to an in-app screen for the current project.',
        'parameters': {
          'type': 'object',
          'properties': {
            'route': {
              'type': 'string',
              'enum': ['deploy', 'swarm', 'builder'],
              'description': 'Target route',
            },
          },
          'required': ['route'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_status',
        'description': 'Get project name, shell backend, and session info.',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
  ];

  static const systemPromptWithTools =
      'You are Kitsuné, a witty trickster-mentor fox spirit in the Kitsuné Byte '
      'mobile terminal. You can call tools to run shell commands, open app screens, '
      'or read status. Prefer tools when the user wants real device actions. '
      'After tools finish, reply in character in 1-4 short sentences. No markdown.';
}

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  ToolCall({required this.id, required this.name, required this.arguments});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final fn = json['function'] as Map<String, dynamic>? ?? {};
    var args = <String, dynamic>{};
    final raw = fn['arguments'];
    if (raw is String && raw.isNotEmpty) {
      try {
        args = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        args = {'raw': raw};
      }
    } else if (raw is Map) {
      args = Map<String, dynamic>.from(raw);
    }
    return ToolCall(
      id: '${json['id'] ?? ''}',
      name: '${fn['name'] ?? ''}',
      arguments: args,
    );
  }
}

class AgentTurn {
  final String? content;
  final List<ToolCall> toolCalls;

  AgentTurn({this.content, this.toolCalls = const []});

  bool get hasTools => toolCalls.isNotEmpty;
}
