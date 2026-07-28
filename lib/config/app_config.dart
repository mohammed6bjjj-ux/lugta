import 'package:flutter/foundation.dart';

/// Compile-time configuration for the mobile client.
///
/// Only the project URL and the publishable key are allowed in this client.
/// Server-only secrets (service-role, SMS.to, FCM service credentials, etc.)
/// must never be added here.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xmlqrvvdhlhqixinaecg.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_wdH31dL1yBalLZZqaGoFUA_A39TiBKe',
  );

  /// `supabase` is the production/default mode. `demo` is intentionally
  /// opt-in and is used by widget/integration tests and design previews.
  static const String backendMode = String.fromEnvironment(
    'APP_BACKEND',
    defaultValue: 'supabase',
  );

  /// Native mobile builds ship their public Firebase client configuration as
  /// platform resources. Push can still be disabled explicitly for a build.
  static const bool fcmRequested = bool.fromEnvironment(
    'APP_FCM_ENABLED',
    defaultValue: true,
  );
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );
  static const String firebaseWebVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  static bool forceDemo = false;

  static bool get demoRequested => resolveDemoRequested(
    releaseMode: kReleaseMode,
    forceDemo: forceDemo,
    backendMode: backendMode,
  );

  /// Centralizes the release invariant so it can be verified without needing
  /// a release-mode test runner. Demo data must never be reachable from a
  /// distributable binary, even if a build command accidentally passes
  /// `--dart-define=APP_BACKEND=demo`.
  @visibleForTesting
  static bool resolveDemoRequested({
    required bool releaseMode,
    required bool forceDemo,
    required String backendMode,
  }) => !releaseMode && (forceDemo || backendMode.toLowerCase() == 'demo');

  static bool get hasValidSupabaseConfiguration =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.startsWith('sb_publishable_');

  static bool get useSupabase =>
      !demoRequested && hasValidSupabaseConfiguration;

  static bool get usesBundledFirebaseConfiguration =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static bool get hasExplicitFirebaseClientConfiguration =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get hasFirebaseClientConfiguration =>
      usesBundledFirebaseConfiguration ||
      hasExplicitFirebaseClientConfiguration;

  static bool get fcmEnabled =>
      !demoRequested && fcmRequested && hasFirebaseClientConfiguration;
}
