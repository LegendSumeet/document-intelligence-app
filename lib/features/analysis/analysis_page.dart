import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/services/citation_formatting.dart';
import '../../core/widgets/feedback_panels.dart';
import '../../data/api/document_api.dart';
import '../../data/models/document_item.dart';
import '../../data/models/query_result.dart';
import 'widgets/result_panel.dart';

/// Ask-or-extract workspace over a fixed set of selected documents.
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, required this.api, required this.documents});

  final DocumentApi api;
  final List<DocumentItem> documents;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
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
                ErrorPanel(message: _error!),
              ],
              if (_queryResult != null) ...[
                const SizedBox(height: 24),
                ResultPanel(
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
                ResultPanel(
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
