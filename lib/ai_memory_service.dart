import 'dart:convert';

class AIMemoryService {
  static final AIMemoryService _instance = AIMemoryService._internal();
  factory AIMemoryService() => _instance;
  AIMemoryService._internal();
  
  final Map<String, UserMemory> _memories = {};

  void learn(String userId, MemoryEvent event) {
    _memories.putIfAbsent(userId, () => UserMemory(userId: userId)).addEvent(event);
  }

  UserMemory? getMemory(String userId) => _memories[userId];

  String buildSystemPrompt(String userId, {String? context}) {
    final m = _memories[userId];
    if (m == null) return '';
    return 'PACKAGES: ' + m.preferredPackages.join(', ') + 
           '\nPATTERNS: ' + m.preferredPatterns.join(', ') + 
           '\nARCH: ' + jsonEncode(m.architectureChoices) + 
           (context != null ? '\nCTX: ' + context : '');
  }
}

class UserMemory {
  final String userId;
  final List<<MemoryEvent> events = [];
  final Set<String> preferredPackages = {};
  final Set<String> preferredPatterns = {};
  final Map<String, String> architectureChoices = {};
  final Map<String, dynamic> codingStyle = {};
  final List<String> recentProjects = [];
  
  UserMemory({required this.userId});

  void addEvent(MemoryEvent e) {
    events.add(e);
    if (e.type == MemoryEventType.packageUsed) preferredPackages.add(e.data['package'] as String);
    else if (e.type == MemoryEventType.patternUsed) preferredPatterns.add(e.data['pattern'] as String);
    else if (e.type == MemoryEventType.architectureChoice) architectureChoices[e.data['key'] as String] = e.data['value'] as String;
    else if (e.type == MemoryEventType.stylePreference) codingStyle[e.data['key']] = e.data['value'];
    else if (e.type == MemoryEventType.projectCreated) recentProjects.add(e.data['name'] as String);
  }
}

enum MemoryEventType { 
  packageUsed, patternUsed, architectureChoice, stylePreference, 
  projectCreated, codeGenerated, errorEncountered, fixApplied 
}

class MemoryEvent {
  final MemoryEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  MemoryEvent({required this.type, required this.data}) : timestamp = DateTime.now();
}
