class AIBranch {
  final String id;
  final String? parentId;
  final String projectId;
  final String prompt;
  final String response;
  final String? codeSnapshot;
  final DateTime timestamp;
  final bool isActive;
  final String? modelUsed;
  final int? tokensUsed;

  AIBranch({
    required this.id,
    this.parentId,
    required this.projectId,
    required this.prompt,
    required this.response,
    this.codeSnapshot,
    required this.timestamp,
    this.isActive = false,
    this.modelUsed,
    this.tokensUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'project_id': projectId,
      'prompt': prompt,
      'response': response,
      'code_snapshot': codeSnapshot,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'model_used': modelUsed,
      'tokens_used': tokensUsed,
    };
  }

  factory AIBranch.fromMap(Map<String, dynamic> map) {
    return AIBranch(
      id: map['id'],
      parentId: map['parent_id'],
      projectId: map['project_id'],
      prompt: map['prompt'],
      response: map['response'],
      codeSnapshot: map['code_snapshot'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isActive: map['is_active'] == 1,
      modelUsed: map['model_used'],
      tokensUsed: map['tokens_used'],
    );
  }
}
