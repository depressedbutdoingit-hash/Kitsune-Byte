import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class KitsuneDB {
  static final KitsuneDB _instance = KitsuneDB._internal();
  factory KitsuneDB() => _instance;
  KitsuneDB._internal();

  Database? _db;
  final _changeController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get changes => _changeController.stream;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'kitsune.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE projects (id TEXT PRIMARY KEY, name TEXT, description TEXT, created_at INTEGER, updated_at INTEGER, config TEXT)');
        await db.execute('CREATE TABLE files (id TEXT PRIMARY KEY, project_id TEXT, path TEXT, content TEXT, language TEXT, created_at INTEGER, updated_at INTEGER)');
        await db.execute('CREATE TABLE sync_queue (id INTEGER PRIMARY KEY AUTOINCREMENT, operation TEXT, table_name TEXT, record_id TEXT, data TEXT, created_at INTEGER)');
      },
    );
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    await _db!.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    _changeController.add({'table': table, 'op': 'insert', 'data': data});
    await _queueSync('insert', table, data['id'], data);
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    await _db!.update(table, data, where: 'id = ?', whereArgs: [id]);
    _changeController.add({'table': table, 'op': 'update', 'data': data});
    await _queueSync('update', table, id, data);
  }

  Future<void> delete(String table, String id) async {
    await _db!.delete(table, where: 'id = ?', whereArgs: [id]);
    _changeController.add({'table': table, 'op': 'delete', 'id': id});
    await _queueSync('delete', table, id, null);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<<dynamic>? whereArgs}) async {
    return await _db!.query(table, where: where, whereArgs: whereArgs);
  }

  Future<void> _queueSync(String op, String table, String id, Map<String, dynamic>? data) async {
    await _db!.insert('sync_queue', {'operation': op, 'table_name': table, 'record_id': id, 'data': data != null ? jsonEncode(data) : null, 'created_at': DateTime.now().millisecondsSinceEpoch});
  }

  Future<List<Map<String, dynamic>>> getPendingSync() async {
    return await _db!.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> close() async {
    await _db?.close();
    await _changeController.close();
  }
}
