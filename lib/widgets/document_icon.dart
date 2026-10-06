import 'package:flutter/material.dart';

import '../models/document.dart';
import '../theme/app_colors.dart';

/// A rounded tile showing the document's type icon in its accent color.
///
/// The accent is a fixed brand color per file type (red for PDF, blue for
/// DOCX, and so on) so the list is scannable at a glance without relying on
/// text alone.
class DocumentIcon extends StatelessWidget {
  const DocumentIcon({super.key, required this.kind, this.size = 44});

  final DocumentKind kind;
  final double size;

  static Color accentFor(DocumentKind kind) => switch (kind) {
    DocumentKind.pdf => AppColors.pdfAccent,
    DocumentKind.docx => AppColors.docxAccent,
    DocumentKind.txt => AppColors.txtAccent,
    DocumentKind.image => AppColors.imageAccent,
  };

  @override
  Widget build(BuildContext context) {
    final accent = accentFor(kind);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(kind.icon, size: size * 0.46, color: accent),
    );
  }
}
