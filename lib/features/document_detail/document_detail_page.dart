import 'package:flutter/material.dart';

import '../../core/widgets/feedback_panels.dart';
import '../../data/api/document_api.dart';
import '../../data/models/document_item.dart';
import '../../data/models/page_evidence.dart';
import '../source_viewer/source_pdf_page.dart';
import 'widgets/structure_node.dart';

/// Shows a document's outline and lets the user pull page-level evidence,
/// with a shortcut into the source PDF viewer.
class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({
    super.key,
    required this.api,
    required this.document,
  });

  final DocumentApi api;
  final DocumentItem document;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late Future<List<dynamic>> _structure;
  final _pageController = TextEditingController(text: '1');
  NumberedPagesResult? _pages;
  String? _error;

  @override
  void initState() {
    super.initState();
    _structure = widget.api.getStructure(widget.document.id);
  }

  Future<void> _loadPages() async {
    try {
      final pages = await widget.api.getPages(
        widget.document.id,
        _pageController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _pages = pages;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SourcePdfPage(
                  api: widget.api,
                  documentId: widget.document.id,
                  documentName: widget.document.name,
                ),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'View source PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Document outline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: _structure,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return ErrorPanel(message: snapshot.error.toString());
              }
              final nodes = snapshot.data ?? const [];
              if (nodes.isEmpty) {
                return const InfoPanel(
                  icon: Icons.account_tree_outlined,
                  message: 'No outline was detected for this document.',
                );
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (var index = 0; index < nodes.length; index++)
                        StructureNode(node: nodes[index], index: index),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Page evidence', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageController,
                  decoration: const InputDecoration(
                    labelText: 'Pages',
                    hintText: '1, 3-5',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _loadPages,
                icon: const Icon(Icons.search),
                tooltip: 'Load evidence',
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorPanel(message: _error!),
          ],
          if (_pages != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final page in _pages!.pages)
                          Chip(label: Text('Page $page')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _pages!.evidence,
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
