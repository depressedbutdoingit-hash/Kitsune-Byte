import 'package:flutter/material.dart';
import '../services/ai/ai_time_travel.dart';
import '../models/ai_branch.dart';

class AITimeTravelScreen extends StatefulWidget {
  final String projectId;
  
  AITimeTravelScreen({required this.projectId});

  @override
  _AITimeTravelScreenState createState() => _AITimeTravelScreenState();
}

class _AITimeTravelScreenState extends State<<AITimeTravelScreen> {
  List<AIBranch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches = await AITimeTravel.instance.getProjectBranches(widget.projectId);
    setState(() {
      _branches = branches;
      _isLoading = false;
    });
  }

  Future<void> _activateBranch(String branchId) async {
    await AITimeTravel.instance.activateBranch(branchId);
    _loadBranches();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored to this branch')),
    );
  }

  Future<void> _deleteBranch(String branchId) async {
    await AITimeTravel.instance.deleteBranch(branchId);
    _loadBranches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Time Travel'),
        subtitle: Text('Branches: ${_branches.length}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No AI interactions yet'),
                      Text(
                        'Ask the AI to generate code — each response becomes a branch',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final time = '${branch.timestamp.hour}:${branch.timestamp.minute.toString().padLeft(2, '0')}';
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: branch.isActive ? Color(0xFF0F3460) : Color(0xFF16213E),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: branch.isActive ? Colors.green : Colors.grey,
                          child: Icon(
                            branch.isActive ? Icons.check : Icons.code,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          branch.prompt.length > 40 
                            ? '${branch.prompt.substring(0, 40)}...' 
                            : branch.prompt,
                          style: TextStyle(
                            fontWeight: branch.isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$time • ${branch.modelUsed ?? 'Unknown model'}'),
                            if (branch.tokensUsed != null)
                              Text('${branch.tokensUsed} tokens'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!branch.isActive)
                              IconButton(
                                icon: Icon(Icons.restore, color: Colors.blue),
                                onPressed: () => _activateBranch(branch.id),
                                tooltip: 'Restore this branch',
                              ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBranch(branch.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Show full prompt/response
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Branch Details'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Prompt:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(branch.prompt),
                                    SizedBox(height: 16),
                                    Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(branch.response.substring(0, 200) + '...'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
