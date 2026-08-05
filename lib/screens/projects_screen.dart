import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../kitsune_theme_v3.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
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
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.createProject({
                  'name': nameController.text,
                  'description': descController.text,
                });
                if (context.mounted) Navigator.pop(context);
                _loadProjects();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(String id) async {
    await DatabaseHelper.instance.deleteProject(id);
    _loadProjects();
  }

  void _openAction(String route, String projectId) {
    Navigator.pushNamed(context, route, arguments: projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kitsuné Byte'),
            Text('Projects', style: KitsuneTheme.label()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_off),
            tooltip: 'Offline mode',
            onPressed: () {
              // Toggle offline mode indicator
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: KitsuneTheme.mistSilver),
                      const SizedBox(height: 16),
                      Text('No projects yet', style: KitsuneTheme.bodyLarge()),
                      Text(
                        'Tap + to create your first app',
                        style: KitsuneTheme.label(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    final id = project['id'] as String;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: project['is_offline'] == 1
                              ? Colors.green
                              : KitsuneTheme.cyanEyes,
                          child: const Icon(Icons.code),
                        ),
                        title: Text(project['name']),
                        subtitle: Text(
                          project['description'] ?? 'No description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'builder':
                                _openAction('/builder', id);
                                break;
                              case 'terminal':
                                _openAction('/terminal', id);
                                break;
                              case 'swarm':
                                _openAction('/swarm', id);
                                break;
                              case 'deploy':
                                _openAction('/deploy', id);
                                break;
                              case 'delete':
                                _deleteProject(id);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'builder', child: Text('Open Builder')),
                            PopupMenuItem(value: 'terminal', child: Text('Open Terminal')),
                            PopupMenuItem(value: 'swarm', child: Text('Run Swarm')),
                            PopupMenuItem(value: 'deploy', child: Text('Deploy')),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                        onTap: () => _openAction('/builder', id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        tooltip: 'New Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
