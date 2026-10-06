import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:documentintelligence/screens/auth/profile_screen.dart';

/// Navigation drawer shown from the sidebar control on the home screen.
class AskDocsDrawer extends StatelessWidget {
  const AskDocsDrawer({
    super.key,
    required this.onNewChat,
    required this.onDocuments,
    required this.onProfile,
  });

  final VoidCallback onNewChat;
  final VoidCallback onDocuments;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'AskDocs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('New chat'),
              onTap: onNewChat,
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Documents'),
              onTap: onDocuments,
            ),
            if (user != null) ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: onProfile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
