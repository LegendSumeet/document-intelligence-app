import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/profile_avatar.dart';

/// The signed-in account screen.
///
/// Reads the live Firebase user so the UI can never drift from auth state, and
/// puts the one destructive action — sign out — behind a confirmation. No
/// navigation happens on sign-out: the root app shell listens to
/// `authStateChanges` and returns to the sign-in screen itself.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.auth});

  /// Injected for tests; defaults to a real [AuthService].
  final AuthService? auth;

  static Route<void> route({AuthService? auth}) {
    return MaterialPageRoute<void>(builder: (_) => ProfileScreen(auth: auth));
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();
  bool _isSigningOut = false;

  /// Whether to show the Firebase "verified email" flag.
  ///
  /// Google accounts are verified by the provider, so this is only meaningful
  /// for password-based sign-ins.
  bool get _showVerification {
    final user = _auth.currentUser;
    if (user == null) return false;
    return !user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to reach your documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _signOut();
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      // The service clears both the Google and Firebase sessions. Firebase's
      // sign-out is authoritative, so it always runs.
      await _auth.signOut();
      // No navigation: authStateChanges rebuilds the app shell.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  /// When the auth stream resolves to no user (i.e. the sign-out completed), pop
  /// this modal route so the app shell shows the sign-in screen. The spinner
  /// below is only shown for the very first stream event before auth state is
  /// known, never after a deliberate sign-out.
  void _popOnSignOut() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? _auth.currentUser;
        if (user == null) {
          if (snapshot.connectionState == ConnectionState.active) {
            _popOnSignOut();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: _isSigningOut ? null : _confirmSignOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: _ProfileBody(
            user: user,
            isSigningOut: _isSigningOut,
            showVerification: _showVerification,
            onSignOut: _confirmSignOut,
          ),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.isSigningOut,
    required this.showVerification,
    required this.onSignOut,
  });

  final User user;
  final bool isSigningOut;
  final bool showVerification;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'AskDocs user';
    final email = user.email ?? 'No email address';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Column(
              children: [
                ProfileAvatar(
                  photoUrl: user.photoURL,
                  displayName: displayName,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Account',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: context.tokens.raised,
              child: Column(
                children: [
                  ProfileField(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: displayName,
                  ),
                  const ProfileDivider(),
                  ProfileField(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: email,
                  ),
                  if (showVerification) ...[
                    const ProfileDivider(),
                    ProfileField(
                      icon: user.emailVerified
                          ? Icons.verified_outlined
                          : Icons.error_outline_rounded,
                      label: 'Email status',
                      value: user.emailVerified ? 'Verified' : 'Not verified',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isSigningOut ? null : onSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                ),
                icon: isSigningOut
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.error,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
