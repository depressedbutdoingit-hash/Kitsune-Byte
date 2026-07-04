import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/project.dart';

class ProjectsScreen extends StatefulWidget {
  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<<ProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Project Name'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.createProject({
                  'name': nameController.text,
                  'description': descController.text,
                });
                Navigator.pop(context);
                _loadProjects();
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    await DatabaseHelper.instance.deleteProject(id);
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitsuné Byte'),
        subtitle: Text('Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_off),
            onPressed: () {
              // Toggle offline mode indicator
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No projects yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Tap + to create your first app',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.code),
                          backgroundColor: project['is_offline'] == 1
                              ? Colors.green
                              : Colors.blue,
                        ),
                        title: Text(project['name']),
                        subtitle: Text(
                          project['description'] ?? 'No description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (project['is_offline'] == 1)
                              Icon(Icons.offline_bolt, color: Colors.green, size: 16),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProject(project['id']),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Open project editor
                          Navigator.pushNamed(
                            context,
                            '/editor',
                            arguments: project['id'],
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: Icon(Icons.add),
        tooltip: 'New Project',
      ),
    );
  }
}
appBar: AppBar(
  title: Text('Kitsuné Byte'),
  subtitle: Text('Projects'),
  actions: [
    IconButton(
      icon: Icon(Icons.cloud_off),
      onPressed: () {
        // Toggle offline mode indicator
      },
    ),
    IconButton( // ADD THIS
      icon: Icon(Icons.rocket_launch, color: Colors.green),
      onPressed: () {
        Navigator.pushNamed(context, '/deploy');
      },
      tooltip: 'Deploy',
    ),
  ],
),
