import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kitsune_byte.db');
    return _database!;
  }

  Future<<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        git_remote_url TEXT,
        is_offline INTEGER DEFAULT 1,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        path TEXT NOT NULL,
        content TEXT,
        language TEXT,
        last_modified INTEGER,
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_conversations (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        prompt TEXT,
        response TEXT,
        model_used TEXT,
        tokens_used INTEGER,
        cost REAL,
        timestamp INTEGER,
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_branches (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        project_id TEXT,
        prompt TEXT,
        response TEXT,
        code_snapshot TEXT,
        timestamp INTEGER,
        is_active INTEGER DEFAULT 0,
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_preferences (
        key TEXT PRIMARY KEY,
        value TEXT,
        learned_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT,
        data TEXT,
        timestamp INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Project CRUD
  Future<String> createProject(Map<String, dynamic> project) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    project['id'] = id;
    project['created_at'] = DateTime.now().millisecondsSinceEpoch;
    project['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('projects', project);
    return id;
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query('projects', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>?> getProject(String id) async {
    final db = await database;
    final results = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('projects', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    await db.delete('files', where: 'project_id = ?', whereArgs: [id]);
    await db.delete('ai_conversations', where: 'project_id = ?', whereArgs: [id]);
  }

  // AI Conversation
  Future<void> logAIConversation(Map<String, dynamic> convo) async {
    final db = await database;
    convo['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('ai_conversations', convo);
  }

  Future<List<Map<String, dynamic>>> getProjectConversations(String projectId) async {
    final db = await database;
    return await db.query(
      'ai_conversations',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'timestamp DESC',
    );
  }

  // AI Memory
  Future<void> learnPreference(String key, String value) async {
    final db = await database;
    await db.insert('ai_preferences', {
      'key': key,
      'value': value,
      'learned_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final results = await db.query('ai_preferences', where: 'key = ?', whereArgs: [key]);
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  // Sync Queue
  Future<void> queueChange(String type, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedChanges() async {
    final db = await database;
    return await db.query('sync_queue', where: 'synced = 0', orderBy: 'timestamp ASC');
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update('sync_queue', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
