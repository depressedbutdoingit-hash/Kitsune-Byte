import 'package:flutter/material.dart';
import '../kitsune_theme_v3.dart';
import '../models/terminal_entry.dart';

/// Live tool-use card — Cursor/Claude-style status chip that expands
/// to show streaming stdout/stderr as the tool runs.
class ToolUseCard extends StatefulWidget {
  final TerminalEntry entry;
  final VoidCallback onToggle;

  const ToolUseCard({
    super.key,
    required this.entry,
    required this.onToggle,
  });

  @override
  State<ToolUseCard> createState() => _ToolUseCardState();
}

class _ToolUseCardState extends State<ToolUseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant ToolUseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.toolStatus != widget.entry.toolStatus) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.entry.toolStatus == 'running') {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.entry.toolStatus) {
      case 'running':
        return KitsuneTheme.foxOrange;
      case 'ok':
        return const Color(0xFF3DDC97);
      case 'fail':
        return KitsuneTheme.emberRed;
      default:
        return KitsuneTheme.mistSilver;
    }
  }

  IconData get _statusIcon {
    switch (widget.entry.toolStatus) {
      case 'running':
        return Icons.bolt;
      case 'ok':
        return Icons.check_circle;
      case 'fail':
        return Icons.error;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final meta = entry.toolMeta ?? {};
    final title = entry.toolName ?? 'tool';
    final subtitle = meta['cmd'] ?? meta['project'] ?? '';
    final isRunning = entry.toolStatus == 'running';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = isRunning ? 0.15 + _pulse.value * 0.25 : 0.0;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KitsuneTheme.cardSurface.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusColor.withOpacity(0.35 + glow),
                    width: isRunning ? 1.5 : 1,
                  ),
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: _statusColor.withOpacity(glow),
                            blurRadius: 12 + _pulse.value * 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isRunning)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _statusColor,
                    ),
                  )
                else
                  Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: KitsuneTheme.label(color: KitsuneTheme.pearl),
                ),
                const SizedBox(width: 8),
                if (meta['backend'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KitsuneTheme.surfacePurple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meta['backend']!,
                      style: KitsuneTheme.label(
                        color: KitsuneTheme.cyanEyes,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const Spacer(),
                if (meta['ms'] != null)
                  Text(
                    '${meta['ms']}ms',
                    style: KitsuneTheme.label(
                      color: KitsuneTheme.mistSilver,
                      fontSize: 10,
                    ),
                  ),
                if (meta['exit'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'exit ${meta['exit']}',
                    style: KitsuneTheme.label(
                      color: _statusColor,
                      fontSize: 10,
                    ),
                  ),
                ],
                Icon(
                  entry.expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: KitsuneTheme.mistSilver,
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: KitsuneTheme.bodyMono(
                  color: KitsuneTheme.foxGlow,
                  fontSize: 12,
                ),
                maxLines: entry.expanded ? null : 1,
                overflow: entry.expanded ? null : TextOverflow.ellipsis,
              ),
            ],
            // Stream body: show while running (even if collapsed) or when expanded
            if ((isRunning || entry.expanded) && entry.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: isRunning,
                  child: SelectableText(
                    entry.text,
                    style: KitsuneTheme.bodyMono(
                      color: KitsuneTheme.mistPearl,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
            if (isRunning && entry.text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'waiting for output…',
                style: KitsuneTheme.label(
                  color: KitsuneTheme.mistSilver,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
