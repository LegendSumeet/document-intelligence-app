import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInAccount;

import '../../core/services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/askdocs_panda.dart';
import '../../widgets/privacy_badge.dart';
import 'widgets/google_sign_in_button.dart' as platform_button;

/// The signed-out landing screen.
///
/// Presents the AskDocs brand, one clear call-to-action, and — when something
/// goes wrong — a retryable, human-readable error. All authentication work is
/// delegated to [AuthService]; this widget owns only presentation and the
/// loading/error state machine.
///
/// Login is handled two ways, because the underlying SDKs differ:
/// * Native — our own styled button calls [AuthService.signInWithGoogle].
/// * Web — the Google Identity Services button is rendered instead, because
///   that SDK rejects programmatic authentication. Its result arrives as an
///   event on the SDK's authentication stream.
///
/// Either way the app never navigates itself after success: the root app shell
/// listens to `authStateChanges` and swaps the screen. That keeps a single
/// source of truth for "am I signed in".
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key, this.auth});

  /// Injected for tests; defaults to a real [AuthService].
  final AuthService? auth;

  static Route<void> route({AuthService? auth}) {
    return MaterialPageRoute<void>(
      builder: (_) => GoogleSignInScreen(auth: auth),
    );
  }

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();

  /// Guards against double taps and against the web button firing twice.
  bool _isSigningIn = false;
  String? _errorMessage;
  StreamSubscription<void>? _webSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) unawaited(_prepareWebSignIn());
  }

  @override
  void dispose() {
    _webSubscription?.cancel();
    super.dispose();
  }

  /// Initializes the SDK and subscribes to the web button's result.
  ///
  /// `attemptLightweightAuthentication` is deliberately not called: Firebase
  /// already restores the persisted session at launch, so an implicit second
  /// sign-in path would only add ambiguity.
  Future<void> _prepareWebSignIn() async {
    try {
      await _auth.initialize();
      _webSubscription = _auth.googleSignInEvents().listen(
        (_) => unawaited(_completeSignIn(_auth.lastAccount)),
        onError: _handleError,
      );
    } catch (error) {
      _handleError(error);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      await _auth.signInWithGoogle();
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  /// Exchanges the Google account for a Firebase session.
  Future<void> _completeSignIn(GoogleSignInAccount? account) async {
    if (account == null) return;
    try {
      await _auth.signInWithAccount(account);
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  /// Shows a user-safe message, staying silent on a deliberate cancellation.
  void _handleError(Object error) {
    if (error is AuthFailure && error.isCancellation) {
      if (mounted) setState(() => _isSigningIn = false);
      return;
    }
    debugPrint('Google sign-in failed on the sign-in screen: $error');
    final message = error is AuthFailure
        ? error.message
        : 'Something went wrong while signing in. Please try again.';
    if (mounted) {
      setState(() {
        _isSigningIn = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DecorativeBackground(),
                  const Center(child: AskDocsPanda(size: 72)),
                  const SizedBox(height: 28),
                  Text(
                    'Ask anything about your documents.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload a PDF and get grounded answers, with the exact '
                    'page and lines behind every claim.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_errorMessage != null) ...[
                    _AuthErrorBanner(
                      message: _errorMessage!,
                      onRetry: _isSigningIn ? null : _signInWithGoogle,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _GoogleAuthAction(
                    isLoading: _isSigningIn,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 28),
                  const _FeatureChips(),
                  const SizedBox(height: 24),
                  const Center(
                    child: PrivacyBadge(
                      message:
                          'We only read your name, email, and profile photo.',
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Footer(theme: theme, colors: colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle floating circles that add visual depth without competing with content.
class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  static const _offsets = [
    Offset(130, 30),
    Offset(50, 130),
    Offset(190, 140),
    Offset(80, 20),
  ];
  static const _sizes = [80.0, 100.0, 70.0, 90.0];
  static const _alphas = [0.06, 0.05, 0.04, 0.05];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [colors.primary, Colors.blue, Colors.green, Colors.orange];

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          for (int i = 0; i < 4; i++)
            Positioned(
              left: _offsets[i].dx,
              top: _offsets[i].dy,
              child: Container(
                width: _sizes[i],
                height: _sizes[i],
                decoration: BoxDecoration(
                  color: palette[i].withValues(alpha: _alphas[i]),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mini feature highlights shown below the sign-in button.
class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  static const _features = [
    (Icons.auto_awesome_rounded, 'AI-powered answers'),
    (Icons.lock_outline_rounded, 'Private & encrypted'),
    (Icons.flash_on_rounded, 'Instant summaries'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final (icon, label) in _features)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Renders the platform-appropriate Google sign-in control.
///
/// On web the SDK-owned button is used (required by Google Identity Services);
/// elsewhere a standard AskDocs button drives the flow.
class _GoogleAuthAction extends StatelessWidget {
  const _GoogleAuthAction({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sdkButton = kIsWeb ? platform_button.buildGoogleSignInButton() : null;

    if (sdkButton != null) {
      return Column(
        children: [
          Center(
            child: Opacity(opacity: isLoading ? 0.6 : 1, child: sdkButton),
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ],
        ],
      );
    }

    return _GoogleButton(isLoading: isLoading, onPressed: onPressed);
  }
}

/// The app-styled "Continue with Google" button, modelled on the official
/// Google sign-in button: white fill, gray border, gray text, four-colour "G".
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: isLoading ? 'Signing in with Google' : 'Continue with Google',
      child: SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            side: BorderSide(color: tokens.hairline),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? SizedBox.square(
                    key: const ValueKey('loading'),
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.primary,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleGlobe(size: 18),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
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

/// The four-colour Google "G" inside a white circle with a subtle border.
class _GoogleGlobe extends StatelessWidget {
  const _GoogleGlobe({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.hairline, width: 0.5),
      ),
      child: Center(
        child: SizedBox.square(
          dimension: size * 0.6,
          child: CustomPaint(painter: _GoogleGlobePainter()),
        ),
      ),
    );
  }
}

class _GoogleGlobePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.24;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    const deg = 3.14159265 / 180;
    arc(-45 * deg, 90 * deg, _blue);
    arc(45 * deg, 90 * deg, _green);
    arc(135 * deg, 90 * deg, _yellow);
    arc(225 * deg, 90 * deg, _red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A dismissible, accessible error banner with a retry action.
class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Retry',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (onRetry != null) const SizedBox(width: 4),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: colors.onErrorContainer,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small footer with the app version and a privacy-policy note.
class _Footer extends StatelessWidget {
  const _Footer({required this.theme, required this.colors});

  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'AskDocs v1.0.0',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'By continuing you accept our Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
