import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/network_media_request.dart';
import 'repositories/demo_repositories.dart';
import 'repositories/repositories.dart';
import 'repositories/supabase_repositories.dart';
import 'secure_session_storage.dart';
import 'services/device_token_registrar.dart';

class AppBackend {
  AppBackend._();

  static final AppBackend instance = AppBackend._();

  AppRepositories repositories = createDemoRepositories();
  DeviceTokenRegistrar deviceTokens = const NoopDeviceTokenRegistrar();

  AuthRepository get auth => repositories.auth;

  Future<void> initialize() async {
    if (AppConfig.demoRequested) {
      NetworkMediaRequest.reset();
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
    NetworkMediaRequest.configure(
      headersProvider: () {
        final token = client.auth.currentSession?.accessToken.trim() ?? '';
        return <String, String>{
          'apikey': AppConfig.supabasePublishableKey,
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
      },
      scopeProvider: () => client.auth.currentUser?.id,
      refreshAuthorization: () async {
        if (client.auth.currentSession != null) {
          await client.auth.refreshSession();
        }
      },
    );
    deviceTokens = await createDeviceTokenRegistrar(client);
    if (client.auth.currentSession != null) {
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
    final initializedRepositories = createSupabaseRepositories(
      client,
      deviceTokens: deviceTokens,
    );
    // A phone recovery OTP creates a real Auth session. Clear any durable
    // recovery-only session before AppSession can observe it as a normal
    // signed-in identity during application bootstrap.
    await initializedRepositories.auth.abandonPasswordRecovery();
    repositories = initializedRepositories;
  }
}

final AppBackend appBackend = AppBackend.instance;
