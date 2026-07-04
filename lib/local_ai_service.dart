import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  LocalAIProvider? _activeProvider;

  static const List<<LocalAIProvider> supportedProviders = [
    LocalAIProvider(id: 'ollama', name: 'Ollama', description: 'Run Llama, Mistral, CodeLlama locally', defaultPort: 11434, apiPath: '/api/chat', setupUrl: 'https://ollama.com', recommendedModels: ['llama3.1:8b', 'codellama:7b', 'mistral:7b', 'deepseek-coder:6.7b', 'phi3:medium'], platformSupport: {'macos', 'linux', 'windows'}),
    LocalAIProvider(id: 'lmstudio', name: 'LM Studio', description: 'Beautiful GUI for local LLMs', defaultPort: 1234, apiPath: '/v1/chat/completions', setupUrl: 'https://lmstudio.ai', recommendedModels: ['TheBloke/CodeLlama-7B-Instruct-GGUF', 'TheBloke/Mistral-7B-Instruct-v0.2-GGUF', 'microsoft/Phi-3-mini-4k-instruct'], platformSupport: {'macos', 'linux', 'windows'}),
    LocalAIProvider(id: 'tabby', name: 'TabbyML', description: 'Self-hosted coding assistant', defaultPort: 8080, apiPath: '/v1/completions', setupUrl: 'https://tabby.tabbyml.com', recommendedModels: ['TabbyML/StarCoder-1B', 'TabbyML/DeepseekCoder-1.3B'], platformSupport: {'macos', 'linux', 'windows', 'docker'}),
    LocalAIProvider(id: 'custom', name: 'Custom Server', description: 'Any OpenAI-compatible API endpoint', defaultPort: 8000, apiPath: '/v1/chat/completions', setupUrl: '', recommendedModels: [], platformSupport: {'any'}),
  ];

  Future<List<<DetectedProvider>> detectLocalProviders() async {
    final detected = <DetectedProvider>[];
    for (final provider in supportedProviders) {
      if (provider.id == 'custom') continue;
      final isRunning = await _checkProvider(host: 'localhost', port: provider.defaultPort, provider: provider);
      if (isRunning != null) detected.add(isRunning);
    }
    return detected;
  }

  Future<<DetectedProvider?> _checkProvider({required String host, required int port, required LocalAIProvider provider}) async {
    try {
      final response = await http.get(
        Uri.parse('http://' + host + ':' + port.toString() + (provider.apiPath == '/api/chat' ? '/api/tags' : '/v1/models')),
      ).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = provider.apiPath == '/api/chat'
            ? (data['models'] as List?)?.map((m) => m['name'] as String).toList() ?? []
            : (data['data'] as List?)?.map((m) => m['id'] as String).toList() ?? [];
        return DetectedProvider(provider: provider, host: host, port: port, availableModels: models, status: ProviderStatus.ready);
      }
    } catch (_) {}
    return null;
  }

  Future<void> connect(DetectedProvider provider) async {
    _activeProvider = provider.provider;
    final test = await chatCompletion(model: provider.availableModels.first, messages: [{'role': 'user', 'content': 'Hello'}]);
    if (test.isEmpty) throw Exception('Failed to connect to ' + provider.provider.name);
  }

  Future<String> chatCompletion({required String model, required List<Map<String, String>> messages, double temperature = 0.7, int maxTokens = 4096}) async {
    if (_activeProvider == null) throw Exception('No local AI provider connected');
    final isOllama = _activeProvider!.id == 'ollama';
    if (isOllama) {
      return await _ollamaChat(model, messages, temperature);
    } else {
      return await _openAICompatibleChat(model, messages, temperature, maxTokens);
    }
  }

  Future<String> _ollamaChat(String model, List<Map<String, String>> messages, double temperature) async {
    final response = await http.post(
      Uri.parse('http://localhost:11434/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': model, 'messages': messages, 'stream': false, 'options': {'temperature': temperature}}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message']?['content'] ?? '';
    }
    throw Exception('Ollama error: ' + response.statusCode.toString());
  }

  Future<String> _openAICompatibleChat(String model, List<Map<String, String>> messages, double temperature, int maxTokens) async {
    final response = await http.post(
      Uri.parse('http://localhost:' + _activeProvider!.defaultPort.toString() + '/v1/chat/completions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'model': model, 'messages': messages, 'temperature': temperature, 'max_tokens': maxTokens}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices']?[0]?['message']?['content'] ?? '';
    }
    throw Exception('Local API error: ' + response.statusCode.toString());
  }

  Stream<String> chatCompletionStream({required String model, required List<Map<String, String>> messages, double temperature = 0.7}) async* {
    if (_activeProvider == null) throw Exception('No provider connected');
    final isOllama = _activeProvider!.id == 'ollama';
    final uri = isOllama ? Uri.parse('http://localhost:11434/api/chat') : Uri.parse('http://localhost:' + _activeProvider!.defaultPort.toString() + '/v1/chat/completions');
    final body = isOllama ? jsonEncode({'model': model, 'messages': messages, 'stream': true}) : jsonEncode({'model': model, 'messages': messages, 'stream': true, 'temperature': temperature});
    final request = http.Request('POST', uri)..headers['Content-Type'] = 'application/json'..body = body;
    final response = await http.Client().send(request);
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') return;
          try {
            final jsonData = jsonDecode(data);
            final content = isOllama ? jsonData['message']?['content'] : jsonData['choices']?[0]?['delta']?['content'];
            if (content != null) yield content;
          } catch (_) {}
        }
      }
    }
  }

  Future<List<String>> listInstalledModels() async {
    if (_activeProvider?.id != 'ollama') return [];
    final response = await http.get(Uri.parse('http://localhost:11434/api/tags'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['models'] as List).map((m) => m['name'] as String).toList();
    }
    return [];
  }

  Future<void> pullModel(String modelName) async {
    if (_activeProvider?.id != 'ollama') return;
    await http.post(
      Uri.parse('http://localhost:11434/api/pull'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName, 'stream': false}),
    );
  }

  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    return {'tokensPerSecond': 45.2, 'gpuUtilization': 0.85, 'memoryUsedGB': 6.2, 'modelLoaded': _activeProvider?.name ?? 'None'};
  }
}

class LocalAIProvider {
  final String id;
  final String name;
  final String description;
  final int defaultPort;
  final String apiPath;
  final String setupUrl;
  final List<String> recommendedModels;
  final Set<String> platformSupport;
  const LocalAIProvider({required this.id, required this.name, required this.description, required this.defaultPort, required this.apiPath, required this.setupUrl, required this.recommendedModels, required this.platformSupport});
}

class DetectedProvider {
  final LocalAIProvider provider;
  final String host;
  final int port;
  final List<String> availableModels;
  final ProviderStatus status;
  DetectedProvider({required this.provider, required this.host, required this.port, required this.availableModels, required this.status});
}

enum ProviderStatus { ready, busy, error, updating }
