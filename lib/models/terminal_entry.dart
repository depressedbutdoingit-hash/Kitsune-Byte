/// Kinds of rows that can appear in the terminal scrollback.
enum TerminalEntryKind { system, input, output, stream, tool, error }

class TerminalEntry {
  final TerminalEntryKind kind;
  final String text;
  final String? toolName;
  final String? toolStatus; // running | ok | fail
  final Map<String, String>? toolMeta;
  final bool expanded;

  const TerminalEntry({
    required this.kind,
    required this.text,
    this.toolName,
    this.toolStatus,
    this.toolMeta,
    this.expanded = false,
  });

  TerminalEntry copyWith({
    String? text,
    String? toolStatus,
    bool? expanded,
    Map<String, String>? toolMeta,
  }) {
    return TerminalEntry(
      kind: kind,
      text: text ?? this.text,
      toolName: toolName,
      toolStatus: toolStatus ?? this.toolStatus,
      toolMeta: toolMeta ?? this.toolMeta,
      expanded: expanded ?? this.expanded,
    );
  }
}
