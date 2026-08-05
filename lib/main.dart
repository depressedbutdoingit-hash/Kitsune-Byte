import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';
import 'screens/projects_screen.dart';
import 'screens/deploy_screen.dart';
import 'terminal_screen.dart';
import 'visual_builder_screen.dart';
import 'ai_swarm_screen.dart';
import 'services/shell/shell_backend.dart';
import 'services/shell/termux_channel.dart';

void main() {
  // Wire Termux platform channel into ShellRouter backends.
  registerTermuxChannelBindings(
    isInstalled: () => TermuxChannel.instance.isTermuxInstalled(),
    runBash: (cmd, cwd) => TermuxChannel.instance.runBash(cmd, workdir: cwd),
  );
  runApp(const KitsuneByteApp());
}

class KitsuneByteApp extends StatelessWidget {
  const KitsuneByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitsuné Byte',
      debugShowCheckedModeBanner: false,
      theme: KitsuneTheme.darkTheme,
      home: const ProjectsScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/editor':
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Code Editor')),
                body: const Center(child: Text('Editor coming soon...')),
              ),
            );
          case '/deploy':
            final projectId = settings.arguments as String? ?? 'default';
            return MaterialPageRoute(
              builder: (_) => DeployScreen(projectId: projectId),
            );
          case '/terminal':
            final projectId = settings.arguments as String? ?? 'default';
            return MaterialPageRoute(
              builder: (_) => TerminalScreen(projectId: projectId),
            );
          case '/builder':
            final projectId = settings.arguments as String? ?? 'default';
            return MaterialPageRoute(
              builder: (_) => VisualBuilderScreen(projectId: projectId),
            );
          case '/swarm':
            final projectId = settings.arguments as String? ?? 'default';
            return MaterialPageRoute(
              builder: (_) => AISwarmScreen(projectId: projectId),
            );
          default:
            return null;
        }
      },
    );
  }
}
