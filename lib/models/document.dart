import 'package:flutter/material.dart';

import '../data/models/document_item.dart';

/// The kind of file a document is, used for icon shape and accent color.
enum DocumentKind {
  pdf('PDF', Icons.picture_as_pdf_rounded),
  docx('DOCX', Icons.description_rounded),
  txt('TXT', Icons.notes_rounded),
  image('IMAGE', Icons.image_rounded);

  const DocumentKind(this.label, this.icon);

  final String label;
  final IconData icon;

  static DocumentKind fromExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => DocumentKind.pdf,
      'docx' || 'doc' => DocumentKind.docx,
      'txt' => DocumentKind.txt,
      'png' || 'jpg' || 'jpeg' || 'webp' || 'heic' => DocumentKind.image,
      _ => DocumentKind.txt,
    };
  }
}

/// How far along AskDocs is with a document.
enum AnalysisStatus { notAnalyzed, analyzing, analyzed }

/// A document known to the backend, adapted for display.
///
/// A document has exactly **one** [status] at a time, and that status is the
/// single source of truth for the card's status line. There is no separate
/// "readiness" text that can contradict it.
@immutable
class Document {
  const Document({
    required this.id,
    required this.name,
    required this.pageCount,
    required this.status,
    this.lastAnalyzed,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final int pageCount;
  final AnalysisStatus status;

  /// When the last analysis finished, used for "Analyzed 2h ago".
  /// Null when the backend does not report a timestamp.
  final DateTime? lastAnalyzed;

  /// Original file size, when known, for the "PDF · 7 pages · 2.4 MB" line.
  final int? sizeBytes;

  DocumentKind get kind => DocumentKind.fromExtension(name);

  String get fileType => kind.label;

  String get pageLabel => pageCount == 1 ? '1 page' : '$pageCount pages';

  /// True when [name] is a machine identifier rather than a human title,
  /// e.g. `cb23eabc-0726-40fd-8a54-28c440fdadd3`. Such names are shown as
  /// "Document" instead of letting a UUID dominate the card.
  bool get hasGenericName {
    final stem = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return _uuidPattern.hasMatch(stem) || stem.length > 64;
  }

  /// The name to show on a card: a human title, or "Document" for UUIDs.
  String get displayName => hasGenericName ? 'Document' : name;

  /// The full name to reveal on tooltip / details, always the real value.
  String get fullName => name;

  /// e.g. "PDF · 7 pages · 2.4 MB" (size omitted when unknown).
  String get metaLabel {
    final parts = <String>[
      fileType,
      if (pageCount > 0) pageLabel,
      if (sizeBytes != null) formatBytes(sizeBytes!),
    ];
    return parts.join(' · ');
  }

  factory Document.fromItem(DocumentItem item) => Document(
    id: item.id,
    name: item.name,
    pageCount: item.pageCount,
    status: item.isReady
        ? AnalysisStatus.analyzed
        : item.status == 'completed' || item.status == 'processing'
        ? AnalysisStatus.analyzing
        : AnalysisStatus.notAnalyzed,
    lastAnalyzed: item.lastAnalyzed,
    sizeBytes: item.sizeBytes,
  );

  bool get isAnalyzed => status == AnalysisStatus.analyzed;
  bool get isAnalyzing => status == AnalysisStatus.analyzing;

  /// The one status line shown on the card.
  ///
  /// Never mixes states: an analyzed document reads "Analyzed 2h ago", an
  /// unanalyzed one reads "Ready to analyze", and a running one reads
  /// "Analyzing…".
  String get statusLabel => switch (status) {
    AnalysisStatus.analyzed =>
      lastAnalyzed == null
          ? 'Analyzed'
          : 'Analyzed ${relativeTime(lastAnalyzed!)}',
    AnalysisStatus.analyzing => 'Analyzing…',
    AnalysisStatus.notAnalyzed => 'Ready to analyze',
  };

  Document copyWith({
    String? id,
    String? name,
    int? pageCount,
    AnalysisStatus? status,
    DateTime? lastAnalyzed,
    int? sizeBytes,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Human file size, e.g. "2.4 MB". Returns null-equivalent empty string for
/// non-positive input.
String formatBytes(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final decimals = unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

/// A short, human "time ago" phrase: "just now", "5m ago", "2h ago",
/// "yesterday", "3 days ago", "2 weeks ago", or a date beyond that.
String relativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return weeks == 1 ? 'a week ago' : '$weeks weeks ago';
  }
  final months = diff.inDays ~/ 30;
  return months <= 1 ? 'a month ago' : '$months months ago';
}
