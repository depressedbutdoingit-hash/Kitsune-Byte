import 'dart:convert';
import '../../db/database_helper.dart';
import '../../models/ai_branch.dart';

class AITimeTravel {
  static final AITimeTravel instance = AITimeTravel._init();
  AITimeTravel._init();

  // Create a new branch from an AI interaction
  Future<String> createBranch({
    required String projectId,
    required String prompt,
    required String response,
    String? codeSnapshot,
    String? parentId,
    String? modelUsed,
    int? tokensUsed,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final branch = AIBranch(
      id: id,
      parentId: parentId,
      projectId: projectId,
      prompt: prompt,
      response: response,
      codeSnapshot: codeSnapshot,
      timestamp: DateTime.now(),
      isActive: false,
      modelUsed: modelUsed,
      tokensUsed: tokensUsed,
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('ai_branches', branch.toMap());
    
    return id;
  }

  // Get all branches for a project
  Future<List<AIBranch>> getProjectBranches(String projectId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'ai_branches',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'timestamp DESC',
    );
    return results.map((m) => AIBranch.fromMap(m)).toList();
  }

  // Activate a branch (restore its state)
  Future<void> activateBranch(String branchId) async {
    final db = await DatabaseHelper.instance.database;
    
    // Deactivate all branches for this project
    final branch = await db.query(
      'ai_branches',
      where: 'id = ?',
      whereArgs: [branchId],
    );
    
    if (branch.isNotEmpty) {
      final projectId = branch.first['project_id'];
      
      await db.update(
        'ai_branches',
        {'is_active': 0},
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      
      await db.update(
        'ai_branches',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [branchId],
      );
    }
  }

  // Get the active branch
  Future<AIBranch?> getActiveBranch(String projectId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'ai_branches',
      where: 'project_id = ? AND is_active = 1',
      whereArgs: [projectId],
    );
    return results.isNotEmpty ? AIBranch.fromMap(results.first) : null;
  }

  // Visual timeline data
  Future<List<Map<String, dynamic>>> getTimeline(String projectId) async {
    final branches = await getProjectBranches(projectId);
    return branches.map((b) => {
      'id': b.id,
      'prompt': b.prompt.length > 50 ? '${b.prompt.substring(0, 50)}...' : b.prompt,
      'timestamp': b.timestamp,
      'isActive': b.isActive,
      'model': b.modelUsed,
      'tokens': b.tokensUsed,
    }).toList();
  }

  // Delete a branch
  Future<void> deleteBranch(String branchId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('ai_branches', where: 'id = ?', whereArgs: [branchId]);
  }
}
