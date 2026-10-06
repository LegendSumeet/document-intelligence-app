import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/analysis_stages.dart';
import '../../data/api/document_api.dart';
import '../../data/models/document_item.dart';
import '../../models/document.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis_progress.dart';
import '../../widgets/document_list_item.dart';
import '../../widgets/primary_button.dart';

/// Screen 3 — Add a document.
///
/// Pick a PDF, upload it to the backend and wait until it is indexed.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.api});

  final DocumentApi api;

  static Route<Document> route(DocumentApi api) =>
      MaterialPageRoute<Document>(builder: (_) => UploadScreen(api: api));

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  Document? _selected;
  PlatformFile? _file;
  Document? _indexed;
  String? _error;
  bool _analyzing = false;
  bool _complete = false;

  /// Index of the stage currently running; `kAnalysisStages.length` once done.
  int _activeStage = 0;
  double _progress = 0;

  late final AnimationController _entrance;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      _selected = Document(
        id: 'pending',
        name: file.name,
        pageCount: 0,
        status: AnalysisStatus.notAnalyzed,
      );
      _indexed = null;
      _error = null;
      _analyzing = false;
      _complete = false;
      _activeStage = 0;
      _progress = 0;
    });
    _entrance
      ..reset()
      ..forward();
  }

  void _remove() {
    setState(() {
      _selected = null;
      _file = null;
      _indexed = null;
      _error = null;
      _analyzing = false;
      _complete = false;
      _activeStage = 0;
      _progress = 0;
    });
  }

  void _setStage(int stage) {
    if (_disposed || !mounted) return;
    final done = kAnalysisStages
        .take(stage)
        .fold<double>(0, (sum, s) => sum + s.weight);
    setState(() {
      _activeStage = stage;
      _progress = done;
    });
  }

  /// Uploads the PDF, then polls until the backend finishes indexing it.
  Future<void> _analyze() async {
    final file = _file;
    if (file == null || _analyzing) return;
    setState(() {
      _analyzing = true;
      _complete = false;
      _error = null;
    });
    _setStage(0);

    try {
      final bytes = await file.readAsBytes();
      var item = (await widget.api.uploadPdf(file.name, bytes)).document;
      _setStage(1);

      for (var attempt = 0; !item.isReady; attempt++) {
        if (item.status == 'failed' || attempt >= 60) {
          throw StateError(
            item.status == 'failed'
                ? 'The backend could not process this document.'
                : 'Indexing is taking too long. Try again shortly.',
          );
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        if (_disposed || !mounted) return;
        _setStage(attempt < 3 ? 1 : 2);
        item = DocumentItem.fromJson(await widget.api.getDocument(item.id));
      }

      if (_disposed || !mounted) return;
      setState(() {
        _indexed = Document.fromItem(item);
        _activeStage = kAnalysisStages.length;
        _progress = 1;
        _analyzing = false;
        _complete = true;
      });
    } catch (error) {
      if (_disposed || !mounted) return;
      setState(() {
        _analyzing = false;
        _error = error.toString();
      });
    }
  }

  void _openChat() {
    final document = _indexed;
    if (document == null) return;
    // Hand the indexed document back to Home, which owns the chat push.
    Navigator.of(context).pop(document);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: const Text('Add a document'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Text(
                  'Choose a document from your device.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                if (_selected == null)
                  _PickerArea(onBrowse: _pick)
                else
                  _SelectedArea(
                    document: _selected!,
                    animation: _entrance,
                    onRemove: _analyzing ? null : _remove,
                  ),
                if (_analyzing || _complete) ...[
                  const SizedBox(height: 22),
                  AnalysisProgress(
                    stages: kAnalysisStages,
                    activeIndex: _activeStage,
                    progress: _progress,
                    isComplete: _complete,
                  ),
                ],
                const SizedBox(height: 26),
                if (_selected != null && !_complete)
                  PrimaryButton(
                    label: _analyzing ? 'Analyzing…' : 'Analyze with AskDocs',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _analyzing,
                    onPressed: _analyzing ? null : _analyze,
                  ),
                if (_complete)
                  PrimaryButton(
                    label: 'Ask AskDocs',
                    icon: Icons.forum_outlined,
                    onPressed: _openChat,
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Your PDF is uploaded to your AskDocs backend and indexed '
                  'so you can ask questions about it.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

/// The large, empty selection area shown before a file is chosen.
class _PickerArea extends StatelessWidget {
  const _PickerArea({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: tokens.accentSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            // Dashed-look container used only as a visual anchor for the icon.
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.hairline),
              ),
              child: Icon(
                Icons.upload_file_rounded,
                size: 30,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose a document',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'PDF',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Browse Files',
              icon: Icons.folder_open_rounded,
              onPressed: onBrowse,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// The chosen document, with its "Ready to analyze" state and a remove action.
class _SelectedArea extends StatelessWidget {
  const _SelectedArea({
    required this.document,
    required this.animation,
    required this.onRemove,
  });

  final Document document;
  final Animation<double> animation;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return FadeTransition(
      opacity: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected document',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DocumentListItem(document: document, selected: true, onTap: () {}),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: tokens.positive,
              ),
              const SizedBox(width: 7),
              Text(
                'Ready to analyze',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.positive,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
