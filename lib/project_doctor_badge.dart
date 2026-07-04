import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';

class ProjectDoctorBadge extends StatelessWidget {
  const ProjectDoctorBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: KitsuneTheme.shadowAuburn,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _DoctorPanel(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: KitsuneTheme.emberRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KitsuneTheme.emberRed.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety, color: KitsuneTheme.emberRed, size: 16),
            const SizedBox(width: 6),
            Text('3 issues', style: KitsuneTheme.label(color: KitsuneTheme.emberRed)),
          ],
        ),
      ),
    );
  }
}

class _DoctorPanel extends StatelessWidget {
  final List<<DoctorIssue> _issues = [
    DoctorIssue(severity: 'critical', title: 'JWT not validated', desc: 'Auth flow missing signature verification', fix: 'Add middleware'),
    DoctorIssue(severity: 'warning', title: 'Image uploads costly', desc: 'No compression, $18/mo estimated', fix: 'Use WebP'),
    DoctorIssue(severity: 'info', title: 'Unused import', desc: 'package:old_package/old.dart', fix: 'Remove import'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: KitsuneTheme.emberRed),
              const SizedBox(width: 12),
              Text('Project Doctor', style: KitsuneTheme.displayMedium()),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: KitsuneTheme.bodyLarge(color: KitsuneTheme.mistSilver)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._issues.map((issue) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _severityColor(issue.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _severityColor(issue.severity).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: _severityColor(issue.severity), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(issue.title, style: KitsuneTheme.bodyLarge(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(issue.severity.toUpperCase(), style: KitsuneTheme.label(color: _severityColor(issue.severity))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(issue.desc, style: KitsuneTheme.bodyLarge(color: KitsuneTheme.mistSilver)),
                const SizedBox(height: 8),
                Text('Fix: ${issue.fix}', style: KitsuneTheme.label(color: KitsuneTheme.cyanEyes)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return KitsuneTheme.emberRed;
      case 'warning': return KitsuneTheme.gold;
      case 'info': return KitsuneTheme.cyanEyes;
      default: return KitsuneTheme.mistSilver;
    }
  }
}

class DoctorIssue {
  final String severity;
  final String title;
  final String desc;
  final String fix;
  DoctorIssue({required this.severity, required this.title, required this.desc, required this.fix});
}
