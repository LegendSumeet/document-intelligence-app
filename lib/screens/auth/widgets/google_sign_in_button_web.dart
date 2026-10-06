import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_web/web_only.dart' as web;

/// Builds the official Google Identity Services button for the web.
///
/// The GIS SDK refuses programmatic authentication, so on web the app must
/// render *this* button rather than its own. Tapping it emits a sign-in event
/// that [AuthService] picks up via `authenticationEvents`.
Widget? buildGoogleSignInButton() {
  return web.renderButton();
}
