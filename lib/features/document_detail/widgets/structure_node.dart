import 'package:flutter/material.dart';

/// Renders one node of a document outline tree, recursing into any children.
class StructureNode extends StatelessWidget {
  const StructureNode({super.key, required this.node, required this.index});

  final dynamic node;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (node is! Map) {
      return ListTile(
        leading: Text('${index + 1}'),
        title: Text(node.toString()),
      );
    }
    final data = Map<String, dynamic>.from(node as Map);
    final title =
        data['title'] ?? data['text'] ?? data['name'] ?? 'Section ${index + 1}';
    final page = data['page'] ?? data['page_number'] ?? data['start_page'];
    final children = data['children'] ?? data['nodes'] ?? data['sections'];
    return ExpansionTile(
      initiallyExpanded: index < 2,
      leading: const Icon(Icons.segment),
      title: Text(title.toString()),
      subtitle: page == null ? null : Text('Page $page'),
      children: children is List
          ? [
              for (
                var childIndex = 0;
                childIndex < children.length;
                childIndex++
              )
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: StructureNode(
                    node: children[childIndex],
                    index: childIndex,
                  ),
                ),
            ]
          : const [],
    );
  }
}
