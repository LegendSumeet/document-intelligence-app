import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'app_theme.dart';
import 'document_api.dart';
import 'models.dart';
import 'source_pdf_viewer.dart';

class DocumentIntelligenceApp extends StatelessWidget {
  const DocumentIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const DocumentSelectionPage(),
    );
  }
}

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
          _NavigationItem(
            icon: Icons.folder_copy_outlined,
            label: 'Library',
            selected: true,
            onTap: () {},
          ),
          _NavigationItem(
            icon: Icons.auto_awesome_outlined,
            label: 'Analyze selection',
            onTap: _selected.isEmpty ? null : () => _openAnalysis(context),
          ),
          _NavigationItem(
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document library',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Select trusted sources, then ask, compare, or extract.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          onPressed: _loading || _api == null
                              ? null
                              : _loadDocuments,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh documents',
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _uploading || _api == null
                              ? null
                              : _upload,
                          icon: _uploading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(_uploading ? 'Indexing' : 'Add PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricTile(
                          value: '${_documents.length}',
                          label: 'Documents',
                          icon: Icons.description_outlined,
                        ),
                        _MetricTile(
                          value: '$readyCount',
                          label: 'Ready',
                          icon: Icons.check_circle_outline,
                        ),
                        _MetricTile(
                          value: '$pageCount',
                          label: 'Indexed pages',
                          icon: Icons.layers_outlined,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      _ErrorPanel(message: _error!),
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
            child: _LibraryEmptyState(onUpload: _api == null ? null : _upload),
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
                    child: _DocumentRow(
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

  void _openAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntelligencePage(
          api: _api!,
          documents: _documents
              .where((item) => _selected.contains(item.id))
              .toList(),
        ),
      ),
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

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          enabled: onTap != null,
          onTap: onTap,
          leading: Icon(icon, size: 20),
          title: Text(label),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 176,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.selected,
    required this.onSelected,
    required this.onInspect,
  });

  final DocumentItem document;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onInspect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.48)
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: onSelected == null
                    ? null
                    : (value) => onSelected!(value ?? false),
              ),
              const SizedBox(width: 6),
              Container(
                width: 42,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${document.pageCount} pages  ·  ${document.readinessLabel}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (document.collection != null || document.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (document.collection != null)
                              document.collection!,
                            ...document.tags,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              if (onInspect != null)
                IconButton(
                  onPressed: onInspect,
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Inspect document',
                )
              else
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.onUpload});

  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 40,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your first source',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload a selectable-text PDF to index its structure, pages, and citation evidence.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose PDF'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IntelligencePage extends StatefulWidget {
  const IntelligencePage({
    super.key,
    required this.api,
    required this.documents,
  });

  final DocumentApi api;
  final List<DocumentItem> documents;

  @override
  State<IntelligencePage> createState() => _IntelligencePageState();
}

class _IntelligencePageState extends State<IntelligencePage> {
  static const _extractionPresets = <String, String>{
    'Contract review': 'Extract parties, effective dates, commercial terms, obligations, deadlines, termination clauses, and material risks.',
    'Invoice': 'Extract vendor, customer, invoice number, issue date, due date, currency, line items, taxes, and total amount.',
    'Resume': 'Extract contact details, skills, education, employers, roles, employment dates, and measurable achievements.',
    'Financial report': 'Extract reporting period, revenue, expenses, profit, cash flow, key changes, risks, and management outlook.',
  };

  final _controller = TextEditingController();
  final _schemaController = TextEditingController(text: 'custom');
  bool _extractMode = false;
  bool _loading = false;
  String _reasoningEffort = 'medium';
  String? _error;
  QueryResult? _queryResult;
  ExtractionResult? _extractionResult;

  Future<void> _run() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _queryResult = null;
      _extractionResult = null;
    });
    try {
      final ids = widget.documents.map((item) => item.id).toList();
      if (_extractMode) {
        final result = await widget.api.extract(
          ids,
          prompt,
          schemaName: _schemaController.text.trim().isEmpty
              ? 'custom'
              : _schemaController.text.trim(),
        );
        if (mounted) setState(() => _extractionResult = result);
      } else {
        final result = await widget.api.query(
          ids,
          prompt,
          reasoningEffort: _reasoningEffort,
        );
        if (mounted) setState(() => _queryResult = result);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _schemaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis workspace')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 56),
            children: [
              Text(
                _extractMode
                    ? 'Build a structured dataset'
                    : 'Ask across your sources',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _extractMode
                    ? 'Describe the fields and rules. Results include traceable source evidence.'
                    : 'Answers are grounded in the selected documents and linked to exact lines.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.documents
                    .map(
                      (document) => Chip(
                        avatar: const Icon(
                          Icons.description_outlined,
                          size: 16,
                        ),
                        label: Text(document.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.question_answer_outlined),
                    label: Text('Ask'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.data_object),
                    label: Text('Extract JSON'),
                  ),
                ],
                selected: {_extractMode},
                onSelectionChanged: (value) => setState(() {
                  _extractMode = value.first;
                  _queryResult = null;
                  _extractionResult = null;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: _extractMode
                      ? 'Extraction instruction'
                      : 'Question',
                  hintText: _extractMode
                      ? 'Extract parties, dates, obligations, and risks.'
                      : 'What are the main findings?',
                ),
              ),
              if (_extractMode) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _extractionPresets.entries)
                      ActionChip(
                        avatar: const Icon(Icons.bolt_outlined, size: 16),
                        label: Text(preset.key),
                        onPressed: () {
                          _schemaController.text = preset.key
                              .toLowerCase()
                              .replaceAll(' ', '_');
                          _controller.text = preset.value;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schemaController,
                  decoration: const InputDecoration(
                    labelText: 'Schema name',
                    prefixIcon: Icon(Icons.dataset_outlined),
                  ),
                ),
              ],
              if (!_extractMode) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _reasoningEffort,
                  decoration: const InputDecoration(
                    labelText: 'Reasoning effort',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value != null) _reasoningEffort = value;
                  },
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _run,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _extractMode ? Icons.data_object : Icons.auto_awesome,
                      ),
                label: Text(_extractMode ? 'Extract' : 'Generate answer'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorPanel(message: _error!),
              ],
              if (_queryResult != null) ...[
                const SizedBox(height: 24),
                _ResultPanel(
                  api: widget.api,
                  title: _queryResult!.isLocationVerified
                      ? 'Citation locations verified'
                      : 'Unverified answer',
                  body: answerWithCitationLinks(
                    _queryResult!.answer,
                    _queryResult!.citations,
                  ),
                  citations: _queryResult!.citations,
                  selectedPages: _queryResult!.selectedPages,
                  usage: _queryResult!.usage,
                ),
              ],
              if (_extractionResult != null) ...[
                const SizedBox(height: 24),
                _ResultPanel(
                  api: widget.api,
                  title:
                      'Structured extraction · ${_extractionResult!.schemaName}',
                  body: const JsonEncoder.withIndent('  ')
                      .convert(_extractionResult!.data),
                  citations: _extractionResult!.citations,
                  code: true,
                  copyable: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
        title: Text(widget.document.name),
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
                return _ErrorPanel(message: snapshot.error.toString());
              }
              final nodes = snapshot.data ?? const [];
              if (nodes.isEmpty) {
                return const _InfoPanel(
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
                        _StructureNode(node: nodes[index], index: index),
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
            _ErrorPanel(message: _error!),
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

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.api,
    required this.title,
    required this.body,
    required this.citations,
    this.code = false,
    this.selectedPages = const {},
    this.usage = const {},
    this.copyable = false,
  });

  final DocumentApi api;
  final String title;
  final String body;
  final List<CitationItem> citations;
  final bool code;
  final Map<String, List<int>> selectedPages;
  final Map<String, dynamic> usage;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  citations.isNotEmpty
                      ? Icons.fact_check_outlined
                      : Icons.info_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (copyable)
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: 'Copy result',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (code)
              SelectableText(body)
            else
              MarkdownBody(
                data: body,
                selectable: true,
                builders: {
                  'a': _CitationBadgeBuilder(
                    citations: citations,
                    onTap: (citation) =>
                        _showCitationEvidence(context, api, citation),
                  ),
                },
              ),
            if (citations.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Sources', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final citation in citations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _showCitationEvidence(context, api, citation),
                  leading: Icon(
                    citation.locationVerified
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                  ),
                  title: Text(citation.label),
                  subtitle: Text(
                    citation.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
            if (selectedPages.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Retrieval scope',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in selectedPages.entries)
                    Chip(
                      avatar: const Icon(Icons.find_in_page_outlined, size: 16),
                      label: Text(
                        '${entry.value.length} pages from ${entry.key.substring(0, entry.key.length.clamp(0, 8))}',
                      ),
                    ),
                ],
              ),
            ],
            if (usage.isNotEmpty) ...[
              const Divider(height: 32),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.monitor_heart_outlined),
                title: const Text('Model usage'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(usage),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _StructureNode extends StatelessWidget {
  const _StructureNode({required this.node, required this.index});

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
                  child: _StructureNode(
                    node: children[childIndex],
                    index: childIndex,
                  ),
                ),
            ]
          : const [],
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.api,
    required this.session,
    required this.documents,
  });

  final DocumentApi api;
  final ChatSession session;
  final List<DocumentItem> documents;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ChatMessage> _messages;
  String _draft = '';
  String _stage = 'Ready';
  bool _sending = false;
  String _reasoningEffort = 'medium';
  String? _sendError;
  String? _failedQuestion;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    _messages = widget.session.history
        .map((turn) => ChatMessage(role: turn.role, text: turn.content))
        .toList();
  }

  void _onInputChanged() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
  }

  List<DocumentItem> get _selectedDocuments => widget.documents
      .where((item) => widget.session.documentIds.contains(item.id))
      .toList();

  Future<void> _changeDocuments() async {
    final selected = widget.session.documentIds.toSet();
    final updated = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose chat documents'),
          content: SizedBox(
            width: 460,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final document in widget.documents.where(
                  (item) => item.isReady,
                ))
                  CheckboxListTile(
                    value: selected.contains(document.id),
                    title: Text(document.name),
                    subtitle: Text('${document.pageCount} pages'),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(document.id);
                      } else {
                        selected.remove(document.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (updated == null ||
        setEquals(updated, widget.session.documentIds.toSet())) {
      return;
    }
    try {
      final session = await widget.api.updateSessionDocuments(
        widget.session.id,
        updated.toList(),
      );
      if (!mounted) return;
      setState(() {
        widget.session.documentIds
          ..clear()
          ..addAll(session.documentIds);
        _messages.clear();
        _draft = '';
        _stage = 'Scope changed';
      });
    } catch (error) {
      if (mounted) setState(() => _stage = error.toString());
    }
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: question));
      _sending = true;
      _draft = '';
      _stage = chatProgressLabel(null);
      _sendError = null;
      _failedQuestion = null;
    });
    try {
      await for (final event in widget.api.streamMessage(
        widget.session.id,
        question,
        reasoningEffort: _reasoningEffort,
      )) {
        if (!mounted) return;
        if (event.type == 'answer_delta') {
          final delta = event.data['delta'] as String? ?? '';
          await _appendStreamDelta(delta);
          continue;
        }
        setState(() {
          if (event.type == 'status') {
            _stage = chatProgressLabel(event.data['stage'] as String?);
          } else if (event.type == 'validation') {
            _stage = chatProgressLabel('validation');
          } else if (event.type == 'complete') {
            final result = event.data['data'] as Map<String, dynamic>;
            final citations = (result['citations'] as List? ?? const [])
                .map(
                  (item) => CitationItem.fromJson(item as Map<String, dynamic>),
                )
                .toList();
            _messages.add(
              ChatMessage(
                role: 'assistant',
                text: answerWithCitationLinks(
                  result['answer'] as String,
                  citations,
                ),
                verified: result['verification_status'] == 'location_verified',
                citations: citations,
                conversational:
                    result['verification_status'] == 'unverified' &&
                    citations.isEmpty,
                selectedPages:
                    (result['selected_pages'] as Map<String, dynamic>? ??
                            const {})
                        .map(
                          (key, value) =>
                              MapEntry(key, (value as List).cast<int>()),
                        ),
                usage: result['usage'] as Map<String, dynamic>? ?? const {},
              ),
            );
            _draft = '';
          } else if (event.type == 'error') {
            _sendError = event.data['message'] as String? ?? 'Request failed';
            _failedQuestion = question;
          }
        });
        _scrollToEnd();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _sendError = error.toString();
          _failedQuestion = question;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _appendStreamDelta(String delta) async {
    if (delta.isEmpty) return;
    final units = RegExp(r'\S+\s*|\s+').allMatches(delta);
    for (final unit in units) {
      if (!mounted) return;
      setState(() => _draft += unit.group(0)!);
      _scrollToEnd();
      await Future<void>.delayed(const Duration(milliseconds: 28));
    }
  }

  void _retry() {
    final question = _failedQuestion;
    if (question == null || _sending) return;
    _controller.text = question;
    _send();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.api.deleteSession(widget.session.id);
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final streamingAnswer = parseStreamingAnswer(_draft, _selectedDocuments);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document chat',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDocuments.length} source${_selectedDocuments.length == 1 ? '' : 's'} in context',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton.outlined(
            onPressed: _sending ? null : _changeDocuments,
            icon: const Icon(Icons.library_add_check_outlined),
            tooltip: 'Change documents',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (_sendError != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: _ErrorPanel(
                    message: _sendError!,
                    actionLabel: 'Retry',
                    onAction: _retry,
                  ),
                ),
              ),
            ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                border: Border.symmetric(
                  horizontal: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                children: [
                  if (_messages.isEmpty && _draft.isEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: _ChatWelcome(
                          documents: _selectedDocuments,
                          onPrompt: (prompt) {
                            _controller.text = prompt;
                            _send();
                          },
                        ),
                      ),
                    ),
                  for (final message in _messages)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: _MessageBubble(
                          message: message,
                          api: widget.api,
                        ),
                      ),
                    ),
                  if (_sending || _draft.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _draft.isEmpty
                              ? _AssistantProcessing(
                                  key: const ValueKey('processing'),
                                  stage: _stage,
                                )
                              : _MessageBubble(
                                  key: const ValueKey('streaming'),
                                  message: ChatMessage(
                                    role: 'assistant',
                                    text: streamingAnswer.markdown,
                                    citations: streamingAnswer.citations,
                                  ),
                                  api: widget.api,
                                  isDraft: true,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 6,
                        enabled: !_sending,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask anything about your documents',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(18, 16, 18, 10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Row(
                          children: [
                            PopupMenuButton<String>(
                              enabled: !_sending,
                              initialValue: _reasoningEffort,
                              tooltip: 'Reasoning effort',
                              onSelected: (value) =>
                                  setState(() => _reasoningEffort = value),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'low',
                                  child: Text('Low reasoning'),
                                ),
                                PopupMenuItem(
                                  value: 'medium',
                                  child: Text('Medium reasoning'),
                                ),
                                PopupMenuItem(
                                  value: 'high',
                                  child: Text('High reasoning'),
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.tune, size: 17),
                                    const SizedBox(width: 7),
                                    Text(
                                      '${_reasoningEffort[0].toUpperCase()}${_reasoningEffort.substring(1)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.expand_more, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _hasInput && !_sending
                                    ? colors.primary
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _hasInput && !_sending
                                    ? _send
                                    : null,
                                tooltip: 'Send message',
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _sending
                                      ? const SizedBox.square(
                                          key: ValueKey('sending'),
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_upward_rounded,
                                          key: const ValueKey('send'),
                                          color: _hasInput
                                              ? colors.onPrimary
                                              : colors.onSurfaceVariant,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantProcessing extends StatefulWidget {
  const _AssistantProcessing({super.key, required this.stage});

  final String stage;

  @override
  State<_AssistantProcessing> createState() => _AssistantProcessingState();
}

class _AssistantProcessingState extends State<_AssistantProcessing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 16, color: colors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => Row(
                      children: List.generate(3, (index) {
                        final phase = (_animation.value * 3 - index) % 3;
                        final opacity =
                            0.3 + (1 - (phase - 1).abs()).clamp(0, 1) * 0.7;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        widget.stage,
                        key: ValueKey(widget.stage),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.api,
    this.isDraft = false,
  });

  final ChatMessage message;
  final DocumentApi api;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    if (user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.only(bottom: 22, left: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SelectableText(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    builders: {
                      'a': _CitationBadgeBuilder(
                        citations: message.citations,
                        onTap: (citation) =>
                            _showCitationEvidence(context, api, citation),
                      ),
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.55),
                          h3: Theme.of(context).textTheme.titleLarge,
                          listBullet: Theme.of(context).textTheme.bodyLarge,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _ResponseMeta(message: message, isDraft: isDraft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome({required this.documents, required this.onPrompt});

  final List<DocumentItem> documents;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'Summarize the key findings and decisions.',
      'Identify obligations, deadlines, and owners.',
      if (documents.length > 1)
        'Compare the documents and highlight conflicts.',
      'What risks or missing information should I review?',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask with evidence',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${documents.length} source${documents.length == 1 ? '' : 's'} in scope',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final prompt in prompts)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: ActionChip(
                    avatar: const Icon(Icons.arrow_outward, size: 16),
                    label: Text(prompt),
                    onPressed: () => onPrompt(prompt),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showCitationEvidence(
  BuildContext context,
  DocumentApi api,
  CitationItem citation,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    citation.locationVerified
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      citation.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SourcePdfPage(
                            api: api,
                            documentId: citation.docId,
                            documentName: citation.document,
                            citation: citation,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Open PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(citation.text),
              const Divider(height: 28),
              Text(
                'Page evidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<PageEvidenceResult>(
                  future: api.getPageEvidence(citation.docId, citation.page),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorPanel(message: snapshot.error.toString());
                    }
                    return ListView(
                      children: [
                        for (final line in snapshot.data?.lines ?? const [])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            color:
                                line.line >= citation.startLine &&
                                    line.line <= citation.endLine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: SelectableText(
                              '${line.line.toString().padLeft(3)}  ${line.text}',
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CitationBadgeBuilder extends MarkdownElementBuilder {
  _CitationBadgeBuilder({required this.citations, required this.onTap});

  final List<CitationItem> citations;
  final ValueChanged<CitationItem> onTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final index = citationIndexFromHref(element.attributes['href']);
    if (index == null || index >= citations.length) return null;
    final citation = citations[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: () => onTap(citation),
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  citation.inlineLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseMeta extends StatelessWidget {
  const _ResponseMeta({required this.message, required this.isDraft});

  final ChatMessage message;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final icon = isDraft
        ? Icons.pending_outlined
        : message.verified
        ? Icons.verified_outlined
        : Icons.forum_outlined;
    final label = isDraft
        ? 'Streaming response'
        : message.verified
        ? 'Citation locations verified · ${message.citations.length} source(s)'
        : 'Conversational response';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
