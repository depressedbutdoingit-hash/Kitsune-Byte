import 'package:flutter/material.dart';
import 'kitsune_theme_v3.dart';

enum BlockType { heading, text, button, image, card }

class BuilderBlock {
  final String id;
  BlockType type;
  Map<String, String> props;
  BuilderBlock({required this.id, required this.type, required this.props});
}

class VisualBuilderScreen extends StatefulWidget {
  final String projectId;
  const VisualBuilderScreen({super.key, required this.projectId});

  @override
  State<VisualBuilderScreen> createState() => _VisualBuilderScreenState();
}

class _VisualBuilderScreenState extends State<VisualBuilderScreen> {
  int _seq = 0;
  late List<BuilderBlock> _blocks;
  bool _showCode = false;

  @override
  void initState() {
    super.initState();
    _blocks = [
      _newBlock(BlockType.heading, {'text': 'Welcome to my app'}),
      _newBlock(BlockType.text, {'text': 'Built with Kitsuné Byte.'}),
      _newBlock(BlockType.button, {'text': 'Get Started', 'tone': 'amber'}),
    ];
  }

  BuilderBlock _newBlock(BlockType type, Map<String, String> props) {
    _seq++;
    return BuilderBlock(id: 'blk_$_seq', type: type, props: props);
  }

  void _addBlock(BlockType type) {
    final defaults = {
      BlockType.heading: {'text': 'New Heading'},
      BlockType.text: {'text': 'Some descriptive body copy goes here.'},
      BlockType.button: {'text': 'Click me', 'tone': 'amber'},
      BlockType.image: {'alt': 'placeholder image'},
      BlockType.card: {'title': 'Card title', 'text': 'Card description.'},
    }[type]!;
    setState(() => _blocks.add(_newBlock(type, Map<String, String>.from(defaults))));
  }

  void _removeBlock(String id) {
    setState(() => _blocks.removeWhere((b) => b.id == id));
  }

  void _editBlock(BuilderBlock block) {
    final controllers = {
      for (final key in block.props.keys) key: TextEditingController(text: block.props[key]),
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: KitsuneTheme.deepCharcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${block.type.name}', style: KitsuneTheme.displayMedium()),
            const SizedBox(height: 12),
            ...controllers.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(labelText: e.key),
                    style: KitsuneTheme.bodyLarge(color: KitsuneTheme.warmCream),
                  ),
                )),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    for (final e in controllers.entries) {
                      block.props[e.key] = e.value.text;
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateCode() {
    final lines = _blocks.map((b) {
      switch (b.type) {
        case BlockType.heading:
          return '<h1>${b.props['text']}</h1>';
        case BlockType.text:
          return '<p>${b.props['text']}</p>';
        case BlockType.button:
          return '<button class="btn-${b.props['tone']}">${b.props['text']}</button>';
        case BlockType.image:
          return '<img alt="${b.props['alt']}" src="/placeholder.png" />';
        case BlockType.card:
          return '<Card title="${b.props['title']}">${b.props['text']}</Card>';
      }
    }).join('\n      ');
    return 'export default function App() {\n  return (\n    <main>\n      $lines\n    </main>\n  );\n}';
  }

  Widget _renderBlock(BuilderBlock b) {
    switch (b.type) {
      case BlockType.heading:
        return Text(b.props['text'] ?? '', style: KitsuneTheme.displayMedium());
      case BlockType.text:
        return Text(b.props['text'] ?? '', style: KitsuneTheme.bodyLarge());
      case BlockType.button:
        final isViolet = b.props['tone'] == 'violet';
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isViolet ? const Color(0xFF7C3AED) : KitsuneTheme.foxOrange,
            disabledBackgroundColor: isViolet ? const Color(0xFF7C3AED) : KitsuneTheme.foxOrange,
          ),
          child: Text(b.props['text'] ?? '', style: const TextStyle(color: Colors.white)),
        );
      case BlockType.image:
        return Container(
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: KitsuneTheme.mistSilver.withOpacity(0.3), style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(b.props['alt'] ?? '', style: KitsuneTheme.label()),
          ),
        );
      case BlockType.card:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: KitsuneTheme.glassCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.props['title'] ?? '', style: KitsuneTheme.bodyLarge(color: KitsuneTheme.warmCream)),
              const SizedBox(height: 4),
              Text(b.props['text'] ?? '', style: KitsuneTheme.label()),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Builder'),
        actions: [
          IconButton(
            icon: Icon(_showCode ? Icons.visibility : Icons.code),
            tooltip: _showCode ? 'Preview' : 'View code',
            onPressed: () => setState(() => _showCode = !_showCode),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final type in BlockType.values)
                  ActionChip(
                    avatar: Icon(_iconFor(type), size: 16, color: KitsuneTheme.foxGlow),
                    label: Text(type.name),
                    onPressed: () => _addBlock(type),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _showCode
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(_generateCode(), style: KitsuneTheme.bodyMono()),
                    ),
                  )
                : _blocks.isEmpty
                    ? Center(
                        child: Text('Empty canvas. Tap a chip above to add a component.', style: KitsuneTheme.label()),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: _blocks.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _blocks.removeAt(oldIndex);
                            _blocks.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final b = _blocks[index];
                          return Card(
                            key: ValueKey(b.id),
                            child: ListTile(
                              onTap: () => _editBlock(b),
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_indicator, color: KitsuneTheme.mistSilver),
                              ),
                              title: _renderBlock(b),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeBlock(b.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(BlockType type) {
    switch (type) {
      case BlockType.heading:
        return Icons.title;
      case BlockType.text:
        return Icons.text_fields;
      case BlockType.button:
        return Icons.smart_button;
      case BlockType.image:
        return Icons.image;
      case BlockType.card:
        return Icons.grid_view;
    }
  }
}
