class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gitRemoteUrl;
  final bool isOffline;
  final Map<String, dynamic> metadata;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.gitRemoteUrl,
    this.isOffline = true,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'git_remote_url': gitRemoteUrl,
      'is_offline': isOffline ? 1 : 0,
      'metadata': metadata.toString(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      gitRemoteUrl: map['git_remote_url'],
      isOffline: map['is_offline'] == 1,
      metadata: {},
    );
  }
}
