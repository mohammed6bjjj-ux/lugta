import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/network_media_request.dart';
import 'repositories/demo_repositories.dart';
import 'repositories/repositories.dart';
import 'repositories/supabase_repositories.dart';
import 'secure_session_storage.dart';
import 'services/app_heartbeat_service.dart';
import 'services/device_token_registrar.dart';

class AppBackend {
  AppBackend._();

  static final AppBackend instance = AppBackend._();

  AppRepositories repositories = createDemoRepositories();
  AppHeartbeat heartbeat = const NoopAppHeartbeat();
  DeviceTokenRegistrar deviceTokens = const NoopDeviceTokenRegistrar();

  AuthRepository get auth => repositories.auth;

  Future<void> initialize() async {
    if (AppConfig.demoRequested) {
      NetworkMediaRequest.reset();
      await heartbeat.dispose();
      heartbeat = const NoopAppHeartbeat();
      await deviceTokens.dispose();
      deviceTokens = const NoopDeviceTokenRegistrar();
      repositories = createDemoRepositories();
      return;
    }
    if (!AppConfig.hasValidSupabaseConfiguration) {
      throw const BackendException(
        'إعدادات Supabase غير مكتملة. لا يمكن تشغيل وضع الإنتاج.',
        code: 'invalid_supabase_configuration',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureSessionStorage(
          persistSessionKey:
              'sb-${Uri.parse(AppConfig.supabaseUrl).host.split('.').first}-auth-token',
        ),
      ),
      storageOptions: const StorageClientOptions(retryAttempts: 2),
    );
    final client = Supabase.instance.client;
    await heartbeat.dispose();
    heartbeat = await createAppHeartbeat(client);
    NetworkMediaRequest.configure(
      headersProvider: () {
        final token = client.auth.currentSession?.accessToken.trim() ?? '';
        return <String, String>{
          'apikey': AppConfig.supabasePublishableKey,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
      },
      scopeProvider: () => client.auth.currentUser?.id,
      backgroundUrlProvider: (url) async {
        final uri = Uri.parse(url);
        final base = Uri.parse(AppConfig.supabaseUrl);
        const prefix = '/storage/v1/object/authenticated/';
        if (uri.host != base.host ||
            !uri.path.startsWith(prefix) ||
            client.auth.currentUser == null) {
          throw StateError('Unsupported private media origin');
        }
        final segments = uri.pathSegments.skip(4).toList();
        if (segments.length < 2 ||
            segments.any((part) => part == '..' || part.isEmpty)) {
          throw const FormatException('Invalid storage object');
        }
        // Only the explicitly saved object is delegated to the OS for 24 hours.
        // Do not put the session's bearer token in DownloadManager's database.
        return client.storage
            .from(segments.first)
            .createSignedUrl(segments.skip(1).join('/'), 86400);
      },
      refreshAuthorization: () async {
        if (client.auth.currentSession != null) {
          await client.auth.refreshSession();
        }
      },
    );
    // Even FCM token-refresh listeners must not see a recovery-only session.
    AuthRepository pushAuth = SupabaseAuthRepository(
      client,
      const NoopDeviceTokenRegistrar(),
    );
    await pushAuth.abandonPasswordRecovery();
    deviceTokens = await createDeviceTokenRegistrar(
      client,
      hasNormalSession: () => pushAuth.hasSession,
    );
    final initializedRepositories = createSupabaseRepositories(
      client,
      deviceTokens: deviceTokens,
    );
    pushAuth = initializedRepositories.auth;
    if (initializedRepositories.auth.hasSession) {
      unawaited(
        deviceTokens.registerCurrentDevice().catchError((Object error) {
          if (kDebugMode) {
            debugPrint(
              '[Push] Restored-session device registration failed: $error',
            );
          }
        }),
      );
    }
    // A phone recovery OTP creates a real Auth session. Clear any durable
    // recovery-only session before AppSession can observe it as a normal
    // signed-in identity during application bootstrap.
    repositories = initializedRepositories;
  }
}

final AppBackend appBackend = AppBackend.instance;
