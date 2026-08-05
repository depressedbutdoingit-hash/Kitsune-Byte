import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';
import 'openrouter_service.dart';

enum AgentState { idle, working, done }

class AISwarmScreen extends StatefulWidget {
  final String projectId;
  const AISwarmScreen({super.key, required this.projectId});

  @override
  State<AISwarmScreen> createState() => _AISwarmScreenState();
}

class _AISwarmScreenState extends State<AISwarmScreen> {
  final _openRouter = OpenRouterService();
  final Map<String, AgentState> _states = {
    for (final key in OpenRouterService.agentConfigs.keys) key: AgentState.idle,
  };
  bool _running = false;
  String? _leadOutput;

  Future<void> _runSwarm() async {
    if (_running) return;
    setState(() {
      _running = true;
      _leadOutput = null;
      for (final key in _states.keys) {
        _states[key] = AgentState.idle;
      }
    });

    final agents = OpenRouterService.agentConfigs.keys.toList();
    for (var i = 0; i < agents.length; i++) {
      final key = agents[i];
      setState(() => _states[key] = AgentState.working);
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _states[key] = AgentState.done);
    }

    // Real call: ask the lead ('skeleton'/Architect-equivalent) agent for a plan.
    try {
      final config = OpenRouterService.agentConfigs['skeleton']!;
      final response = await _openRouter.chatCompletion(
        model: config.primaryModel,
        messages: <Map<String, dynamic>>[
          {
            'role': 'system',
            'content':
                'You are the Architect agent in a multi-agent app-building swarm. In 2 sentences, summarize the next structural step for the current project.',
          },
          {
            'role': 'user',
            'content':
                'Project id: ${widget.projectId}. Propose the next build step.',
          },
        ],
        userId: widget.projectId,
      );
      setState(() => _leadOutput = response.content);
    } catch (e) {
      setState(() => _leadOutput = "Couldn't reach the cloud bridge (${e.runtimeType}). Running in offline/simulated mode.");
    } finally {
      setState(() => _running = false);
    }
  }

  Color _stateColor(AgentState s) {
    switch (s) {
      case AgentState.working:
        return KitsuneTheme.foxOrange;
      case AgentState.done:
        return Colors.greenAccent;
      case AgentState.idle:
        return KitsuneTheme.mistSilver.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agents = OpenRouterService.agentConfigs.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('AI Swarm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _running ? null : _runSwarm,
                icon: _running
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? 'Swarm running…' : 'Dispatch swarm'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: agents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final key = agents[i].key;
                  final config = agents[i].value;
                  final state = _states[key]!;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: KitsuneTheme.glassCard,
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: _stateColor(state), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(key, style: KitsuneTheme.bodyLarge(color: KitsuneTheme.warmCream)),
                              Text(config.purpose, style: KitsuneTheme.label()),
                            ],
                          ),
                        ),
                        if (state == AgentState.working)
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: KitsuneTheme.foxGlow),
                          )
                        else if (state == AgentState.done)
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_leadOutput != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KitsuneTheme.shadowAuburn.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🦊 Architect', style: KitsuneTheme.label(color: KitsuneTheme.foxGlow)),
                    const SizedBox(height: 4),
                    Text(_leadOutput!, style: KitsuneTheme.bodyLarge()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
