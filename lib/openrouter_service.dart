import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'monetization_engine.dart';

class OpenRouterService {
  // Never hardcode API keys in source — this file is public on GitHub.
  // Pass the key at build time instead:
  //   flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxxx
  // and rotate any key that was ever committed to git history.
  static const String _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const double markupMultiplier = 2.0;

  static final TokenUsageTracker _usageTracker = TokenUsageTracker();
  static TokenUsageTracker get usageTracker => _usageTracker;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ' + _apiKey,
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://kitsunebyte.app',
    'X-Title': 'Kitsune Byte',
  };

  static const Map<String, ModelTier> modelTiers = {
    'meta-llama/llama-3.1-8b-instruct:free': ModelTier.free,
    'meta-llama/llama-3.1-70b-instruct:free': ModelTier.free,
    'meta-llama/llama-3.1-405b-instruct:free': ModelTier.free,
    'google/gemini-flash-1.5': ModelTier.free,
    'microsoft/wizardlm-2-8x22b': ModelTier.free,
    'anthropic/claude-3.5-haiku': ModelTier.cheap,
    'deepseek/deepseek-coder': ModelTier.cheap,
    'google/gemini-pro-1.5': ModelTier.cheap,
    'anthropic/claude-3.5-sonnet': ModelTier.premium,
    'anthropic/claude-3-opus': ModelTier.premium,
    'openai/gpt-4o': ModelTier.premium,
    'openai/gpt-4o-mini': ModelTier.premium,
    'google/gemini-1.5-pro': ModelTier.premium,
  };

  static const Map<String, AgentConfig> agentConfigs = {
    'skeleton': AgentConfig(primaryModel: 'meta-llama/llama-3.1-70b-instruct:free', fallbackModel: 'google/gemini-flash-1.5', purpose: 'Structure generation'),
    'ui_polish': AgentConfig(primaryModel: 'anthropic/claude-3.5-haiku', fallbackModel: 'google/gemini-flash-1.5', purpose: 'Visual code'),
    'backend': AgentConfig(primaryModel: 'meta-llama/llama-3.1-405b-instruct:free', fallbackModel: 'deepseek/deepseek-coder', purpose: 'Schema design'),
    'state': AgentConfig(primaryModel: 'google/gemini-flash-1.5', fallbackModel: 'meta-llama/llama-3.1-70b-instruct:free', purpose: 'Pattern recognition'),
    'testing': AgentConfig(primaryModel: 'meta-llama/llama-3.1-8b-instruct:free', fallbackModel: 'microsoft/wizardlm-2-8x22b', purpose: 'Test generation'),
    'build': AgentConfig(primaryModel: 'google/gemini-flash-1.5', fallbackModel: 'anthropic/claude-3.5-haiku', purpose: 'Shell scripts'),
    'vision': AgentConfig(primaryModel: 'meta-llama/llama-3.1-70b-instruct:free', fallbackModel: 'google/gemini-flash-1.5', purpose: 'Error analysis'),
  };

  Future<OpenRouterResponse> chatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
    String? userId,
    List<Map<String, dynamic>>? tools,
  }) async {
    if (_apiKey.isEmpty) {
      throw OpenRouterException('No API key set. Run with --dart-define=OPENROUTER_API_KEY=your_key');
    }
    final tier = modelTiers[model] ?? ModelTier.premium;
    if (tier != ModelTier.free) {
      final balance = await _usageTracker.getBalance(userId);
      if (balance <= 0) {
        throw InsufficientBalanceException(
          'Insufficient token balance. Current: $balance',
        );
      }
    }

    final stopwatch = Stopwatch()..start();
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools;
      body['tool_choice'] = 'auto';
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode(body),
    );
    stopwatch.stop();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usage = data['usage'] ?? {};
      final promptTokens = usage['prompt_tokens'] ?? 0;
      final completionTokens = usage['completion_tokens'] ?? 0;
      final totalTokens =
          usage['total_tokens'] ?? (promptTokens + completionTokens);
      final rawCost = _calculateRawCost(model, promptTokens, completionTokens);
      final userCost = rawCost * markupMultiplier;

      if (tier != ModelTier.free && userId != null) {
        await _usageTracker.deductTokens(userId, userCost);
      }

      await _usageTracker.logUsage(
        userId: userId,
        model: model,
        tier: tier,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        rawCost: rawCost,
        userCost: userCost,
        latencyMs: stopwatch.elapsedMilliseconds,
        status: 'success',
      );

      final choices = data['choices'];
      String content = '';
      List<Map<String, dynamic>> toolCalls = [];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices[0]?['message'] as Map<String, dynamic>? ?? {};
        content = '${msg['content'] ?? ''}';
        final tc = msg['tool_calls'];
        if (tc is List) {
          toolCalls = tc.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      return OpenRouterResponse(
        content: content,
        model: data['model'] ?? model,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        rawCost: rawCost,
        userCost: userCost,
        latencyMs: stopwatch.elapsedMilliseconds,
        toolCalls: toolCalls,
      );
    } else {
      throw OpenRouterException(
        'API Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// SSE-style streaming chat. Yields text deltas as they arrive.
  Stream<String> chatCompletionStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
    String? userId,
  }) async* {
    if (_apiKey.isEmpty) {
      throw OpenRouterException('No API key set. Run with --dart-define=OPENROUTER_API_KEY=your_key');
    }
    final tier = modelTiers[model] ?? ModelTier.premium;
    if (tier != ModelTier.free) {
      final balance = await _usageTracker.getBalance(userId);
      if (balance <= 0) {
        throw InsufficientBalanceException('Insufficient token balance. Current: $balance');
      }
    }

    final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
    request.headers.addAll(_headers);
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    final client = http.Client();
    try {
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        throw OpenRouterException('API Error ${streamed.statusCode}: $body');
      }

      var buffer = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.isEmpty ? '' : lines.removeLast();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
          final data = trimmed.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data);
            final choices = json['choices'];
            if (choices is List && choices.isNotEmpty) {
              final delta = choices[0]?['delta']?['content'];
              if (delta is String && delta.isNotEmpty) yield delta;
            }
          } catch (_) {
            // skip malformed SSE frames
          }
        }
      }
    } finally {
      client.close();
    }
  }

  double _calculateRawCost(String model, int promptTokens, int completionTokens) {
    final pricing = _modelPricing[model];
    if (pricing == null) return 0.0;
    return (promptTokens / 1000000) * pricing.promptPerM + (completionTokens / 1000000) * pricing.completionPerM;
  }

  static final Map<String, ModelPricing> _modelPricing = {
    'meta-llama/llama-3.1-8b-instruct:free': ModelPricing(0.0, 0.0),
    'meta-llama/llama-3.1-70b-instruct:free': ModelPricing(0.0, 0.0),
    'meta-llama/llama-3.1-405b-instruct:free': ModelPricing(0.0, 0.0),
    'google/gemini-flash-1.5': ModelPricing(0.0, 0.0),
    'microsoft/wizardlm-2-8x22b': ModelPricing(0.0, 0.0),
    'anthropic/claude-3.5-haiku': ModelPricing(0.25, 1.25),
    'deepseek/deepseek-coder': ModelPricing(0.14, 0.28),
    'google/gemini-pro-1.5': ModelPricing(3.50, 10.50),
    'anthropic/claude-3.5-sonnet': ModelPricing(3.0, 15.0),
    'anthropic/claude-3-opus': ModelPricing(15.0, 75.0),
    'openai/gpt-4o': ModelPricing(5.0, 15.0),
    'openai/gpt-4o-mini': ModelPricing(0.15, 0.60),
    'google/gemini-1.5-pro': ModelPricing(3.50, 10.50),
  };
}

class AgentConfig {
  final String primaryModel;
  final String fallbackModel;
  final String purpose;
  const AgentConfig({required this.primaryModel, required this.fallbackModel, required this.purpose});
}

class ModelPricing {
  final double promptPerM;
  final double completionPerM;
  const ModelPricing(this.promptPerM, this.completionPerM);
}

class OpenRouterResponse {
  final String content;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double rawCost;
  final double userCost;
  final int latencyMs;
  final List<Map<String, dynamic>> toolCalls;

  OpenRouterResponse({
    required this.content,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.rawCost,
    required this.userCost,
    required this.latencyMs,
    this.toolCalls = const [],
  });

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

class OpenRouterException implements Exception {
  final String message;
  OpenRouterException(this.message);
  @override
  String toString() => 'OpenRouterException: ' + message;
}

class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);
  @override
  String toString() => 'InsufficientBalanceException: ' + message;
}

class TokenUsageTracker {
  static final TokenUsageTracker _instance = TokenUsageTracker._internal();
  factory TokenUsageTracker() => _instance;
  TokenUsageTracker._internal();

  final Map<String, double> _balances = {};

  Future<double> getBalance(String? userId) async {
    if (userId == null) return double.infinity;
    return _balances[userId] ?? 0.0;
  }

  Future<void> addBalance(String userId, double amount) async {
    _balances[userId] = (_balances[userId] ?? 0.0) + amount;
  }

  Future<void> deductTokens(String userId, double cost) async {
    final current = _balances[userId] ?? 0.0;
    if (current < cost) {
      throw InsufficientBalanceException('Need ' + cost.toStringAsFixed(4) + ', have ' + current.toStringAsFixed(4));
    }
    _balances[userId] = current - cost;
  }

  Future<void> logUsage({
    String? userId,
    required String model,
    required ModelTier tier,
    int promptTokens = 0,
    int completionTokens = 0,
    int totalTokens = 0,
    double rawCost = 0.0,
    double userCost = 0.0,
    int latencyMs = 0,
    required String status,
    String? errorMessage,
  }) async {}
}
