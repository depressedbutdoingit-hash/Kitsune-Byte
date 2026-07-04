import 'package:flutter/material.dart';
import 'screens/projects_screen.dart';

void main() {
  runApp(KitsuneByteApp());
}

class KitsuneByteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitsuné Byte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        cardColor: Color(0xFF16213E),
        fontFamily: 'monospace',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0F3460),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE94560),
        ),
      ),
      home: ProjectsScreen(),
      routes: {
        '/editor': (context) => Scaffold(
          appBar: AppBar(title: Text('Code Editor')),
          body: Center(child: Text('Editor coming soon...')),
        ),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'screens/projects_screen.dart';
import 'screens/deploy_screen.dart'; // ADD THIS

void main() {
  runApp(KitsuneByteApp());
}

class KitsuneByteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitsuné Byte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        cardColor: Color(0xFF16213E),
        fontFamily: 'monospace',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0F3460),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE94560),
        ),
      ),
      home: ProjectsScreen(),
      routes: {
        '/editor': (context) => Scaffold(
          appBar: AppBar(title: Text('Code Editor')),
          body: Center(child: Text('Editor coming soon...')),
        ),
        '/deploy': (context) => DeployScreen(projectId: 'default'), // ADD THIS
      },
    );
  }
}
Map<String, WidgetBuilder> routes = {
  '/': (context) => const HomeScreen(),
  '/about': (context) => const AboutScreen(),
  '/pricing': (context) => const PricingScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/build': (context) => const BuildScreen(),
  '/terminal': (context) => const TerminalScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/ai-swarm': (context) => const AiSwarmScreen(),
  '/deploy': (context) => const DeployScreen(),
  '/visual-builder': (context) => const VisualBuilderScreen(),
};
