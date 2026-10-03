import 'package:flutter/material.dart';

/// Shown when the library has no documents yet.
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key, required this.onUpload});

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
