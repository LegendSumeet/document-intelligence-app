import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A user-facing authentication failure.
///
/// [AuthService] never leaks SDK exceptions to the UI; it translates every
/// failure into one of these so screens can render a stable, human message.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code, this.isCancellation = false});

  /// A message that is safe to show directly to a user.
  final String message;

  /// The underlying provider/Firebase code, kept for logging and telemetry.
  final String? code;

  /// True when the user dismissed the sign-in sheet themselves.
  ///
  /// Callers should stay silent in this case rather than showing an error.
  final bool isCancellation;

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// Owns the Google ⇄ Firebase sign-in flow.
///
/// Keeping this out of the widgets means the screens contain no SDK calls at
/// all: they call [signInWithGoogle] and render one of three states. That is
/// also what makes the flow testable — a fake implementation can be injected.
///
/// Web is deliberately handled separately: the Google Identity Services SDK
/// requires *its own* rendered button and rejects programmatic
/// authentication, so [supportsInteractiveSignIn] is false there and the
/// sign-in screen renders the SDK button instead of ours.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  bool _initialized = false;
  GoogleSignInAccount? _lastAccount;

  /// The most recent account produced by the Google SDK.
  ///
  /// On web the SDK button emits an event rather than returning an account
  /// directly, so the screen reads it from here when the event arrives.
  GoogleSignInAccount? get lastAccount => _lastAccount;

  /// Sign-in events from the Google SDK (web uses these; native does not).
  Stream<GoogleSignInAuthenticationEvent> googleSignInEvents() =>
      _googleSignIn.authenticationEvents;

  /// The signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Emits the user on every sign-in/sign-out, including at app start.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Whether this platform can run a programmatic Google sign-in flow.
  ///
  /// Web returns false: it must use the button provided by the Google SDK.
  bool get supportsInteractiveSignIn => _googleSignIn.supportsAuthenticate();

  /// Initializes the Google SDK. Safe to call more than once.
  ///
  /// The [serverClientId] is only required on platforms that do not read it
  /// from a bundled configuration file (e.g. iOS). When not supplied, the
  /// Android plugin auto-resolves it from `google-services.json`.
  Future<void> initialize() async {
    if (_initialized) return;
    final clientId = _clientId.isNotEmpty ? _clientId : null;
    final serverClientId = _serverClientId.isNotEmpty ? _serverClientId : null;
    if (serverClientId == null) {
      debugPrint(
        'GOOGLE_SERVER_CLIENT_ID not provided via --dart-define; '
        'relying on platform auto-resolution '
        '(use --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id> for iOS or explicit setup).',
      );
    }
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  /// Completes sign-in from an account already produced by the SDK.
  ///
  /// Shared by the native flow and the web button's event stream, so both
  /// paths converge on exactly one credential-exchange implementation.
  Future<UserCredential> signInWithAccount(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication googleAuth = account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Runs the full interactive Google sign-in on native platforms.
  ///
  /// Throws [AuthFailure] with a user-safe message on any outcome other than
  /// success.
  Future<UserCredential> signInWithGoogle() async {
    try {
      await initialize();
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      _lastAccount = account;
      return await signInWithAccount(account);
    } on GoogleSignInException catch (error, stack) {
      throw _translateGoogleError(error, stack);
    } on FirebaseAuthException catch (error, stack) {
      throw _translateFirebaseError(error, stack);
    }
  }

  /// Signs out of both Google and Firebase.
  ///
  /// The Firebase sign-out is authoritative and must always run: a hung Google
  /// sign-out must never leave the user stuck in the app. A timeout guarantees
  /// Firebase is reached even if the Google SDK stalls.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut().timeout(
        const Duration(seconds: 5),
      );
    } on TimeoutException {
      debugPrint('Google sign-out timed out (continuing to Firebase sign-out).');
    } catch (error) {
      debugPrint('Google sign-out failed (continuing to Firebase): $error');
    }
    await _auth.signOut();
  }

  /// Config supplied at build time via `--dart-define`, when a platform needs
  /// an explicit client id instead of a bundled configuration file.
  static const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Maps a Google SDK failure to a user-safe [AuthFailure].
  AuthFailure _translateGoogleError(GoogleSignInException error, StackTrace _) {
    debugPrint('Google sign-in failed: ${error.code} ${error.description}');
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => const AuthFailure(
        'Sign-in was cancelled.',
        isCancellation: true,
      ),
      GoogleSignInExceptionCode.interrupted => const AuthFailure(
        'Sign-in was interrupted. Please try again.',
      ),
      GoogleSignInExceptionCode.uiUnavailable => const AuthFailure(
        'Google Sign-In is unavailable right now. Please try again.',
      ),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
        'Google Sign-In is not configured correctly for this app.',
      ),
      _ => AuthFailure(
        error.description ?? 'Could not sign in with Google. Please try again.',
        code: error.code.name,
      ),
    };
  }

  /// Maps a Firebase failure to a user-safe [AuthFailure].
  AuthFailure _translateFirebaseError(
    FirebaseAuthException error,
    StackTrace _,
  ) {
    debugPrint('Firebase sign-in failed: ${error.code} ${error.message}');
    return switch (error.code) {
      'account-exists-with-different-credential' => const AuthFailure(
        'An account already exists with this email using another sign-in '
        'method.',
        code: 'account-exists-with-different-credential',
      ),
      'network-request-failed' => const AuthFailure(
        'No internet connection. Check your network and try again.',
        code: 'network-request-failed',
      ),
      'user-disabled' => const AuthFailure(
        'This account has been disabled.',
        code: 'user-disabled',
      ),
      'operation-not-allowed' => const AuthFailure(
        'Google Sign-In is not enabled for this app.',
        code: 'operation-not-allowed',
      ),
      'too-many-requests' => const AuthFailure(
        'Too many attempts. Please wait a moment and try again.',
        code: 'too-many-requests',
      ),
      _ => AuthFailure(
        error.message ?? 'Could not complete sign-in. Please try again.',
        code: error.code,
      ),
    };
  }
}
