import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/feedback_panels.dart';
import '../../core/widgets/metric_tile.dart';
import '../../data/api/document_api.dart';
import '../../data/models/document_item.dart';
import '../analysis/analysis_page.dart';
import '../chat/chat_page.dart';
import '../document_detail/document_detail_page.dart';
import 'widgets/document_row.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/navigation_item.dart';

/// Landing screen: lists documents, handles upload, and routes into the
/// analysis and chat workspaces for the current selection.
class DocumentSelectionPage extends StatefulWidget {
  const DocumentSelectionPage({super.key});

  @override
  State<DocumentSelectionPage> createState() => _DocumentSelectionPageState();
}

class _DocumentSelectionPageState extends State<DocumentSelectionPage> {
  DocumentApi? _api;
  List<DocumentItem> _documents = const [];
  final Set<String> _selected = {};
  String? _error;
  bool _loading = true;
  bool _uploading = false;
  bool? _healthy;

  @override
  void initState() {
    super.initState();
    try {
      _api = DocumentApi();
      _loadDocuments();
    } on StateError catch (error) {
      _error = error.message;
      _loading = false;
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final documents = await _api!.listDocuments();
      final healthy = await _api!.health();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _healthy = healthy;
        _selected.removeWhere(
          (id) => !documents.any((document) => document.id == id),
        );
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final result = await _api!.uploadPdf(file.name, await file.readAsBytes());
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.reused
                  ? '${result.document.name} was already indexed and has been reused.'
                  : '${result.document.name} was indexed successfully.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openChat() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    try {
      final session = await _api!.createSession(_selected.toList());
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ChatPage(api: _api!, session: session, documents: _documents),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisPage(
          api: _api!,
          documents: _documents
              .where((item) => _selected.contains(item.id))
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text('AskDocs'),
            actions: [
              Tooltip(
                message: _healthy == true ? 'API connected' : 'API unavailable',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    _healthy == true
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: _healthy == true
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    semanticLabel: _healthy == true
                        ? 'API connected'
                        : 'API unavailable',
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading || _api == null ? null : _loadDocuments,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh documents',
              ),
              IconButton.filledTonal(
                onPressed: _uploading || _api == null ? null : _upload,
                icon: _uploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                tooltip: _uploading ? 'Indexing PDF' : 'Add PDF',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (wide) _buildNavigation(context),
              Expanded(
                child: Column(
                  children: [
                    if (_loading || _uploading)
                      const LinearProgressIndicator(minHeight: 2),
                    Expanded(child: _buildLibrary(context, wide)),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide ? null : _buildMobileActions(context),
        );
      },
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 248,
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.article_outlined, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Document\nIntelligence',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const NavigationItem(
            icon: Icons.folder_copy_outlined,
            label: 'Library',
            selected: true,
            onTap: _noop,
          ),
          NavigationItem(
            icon: Icons.auto_awesome_outlined,
            label: 'Analyze selection',
            onTap: _selected.isEmpty ? null : () => _openAnalysis(context),
          ),
          NavigationItem(
            icon: Icons.forum_outlined,
            label: 'Chat with selection',
            onTap: _selected.isEmpty ? null : _openChat,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                _healthy == true
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 16,
                color: _healthy == true ? colors.primary : colors.error,
              ),
              const SizedBox(width: 8),
              Text(
                _healthy == true ? 'API connected' : 'API unavailable',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selected.length} selected',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _selected.isEmpty
                      ? 'Choose documents to begin.'
                      : 'Ready for cross-document work.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary(BuildContext context, bool wide) {
    final colors = Theme.of(context).colorScheme;
    final readyCount = _documents.where((item) => item.isReady).length;
    final pageCount = _documents.fold<int>(
      0,
      (total, item) => total + item.pageCount,
    );
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 20,
                  wide ? 40 : 22,
                  wide ? 40 : 20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document library',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select trusted sources, then ask, compare, or extract.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        MetricTile(
                          value: '${_documents.length}',
                          label: 'Documents',
                          icon: Icons.description_outlined,
                        ),
                        MetricTile(
                          value: '$readyCount',
                          label: 'Ready',
                          icon: Icons.check_circle_outline,
                        ),
                        MetricTile(
                          value: '$pageCount',
                          label: 'Indexed pages',
                          icon: Icons.layers_outlined,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      ErrorPanel(message: _error!),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Sources',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (_selected.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(_selected.clear),
                            child: const Text('Clear selection'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_documents.isEmpty && !_loading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: LibraryEmptyState(onUpload: _api == null ? null : _upload),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              wide ? 40 : 20,
              0,
              wide ? 40 : 20,
              120,
            ),
            sliver: SliverList.separated(
              itemCount: _documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final document = _documents[index];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: DocumentRow(
                      document: document,
                      selected: _selected.contains(document.id),
                      onSelected: document.isReady
                          ? (selected) => setState(() {
                              if (selected) {
                                _selected.add(document.id);
                              } else {
                                _selected.remove(document.id);
                              }
                            })
                          : null,
                      onInspect: document.isReady
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DocumentDetailPage(
                                  api: _api!,
                                  document: document,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selected.isEmpty || _loading
                  ? null
                  : () => _openAnalysis(context),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Analyze'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _selected.isEmpty || _loading ? null : _openChat,
              icon: const Icon(Icons.forum_outlined),
              label: Text('Chat (${_selected.length})'),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
