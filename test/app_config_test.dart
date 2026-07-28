import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/config/app_config.dart';

void main() {
  group('AppConfig demo release invariant', () {
    test('release ignores an APP_BACKEND=demo build define', () {
      expect(
        AppConfig.resolveDemoRequested(
          releaseMode: true,
          forceDemo: false,
          backendMode: 'demo',
        ),
        isFalse,
      );
    });

    test('release ignores the mutable test override', () {
      expect(
        AppConfig.resolveDemoRequested(
          releaseMode: true,
          forceDemo: true,
          backendMode: 'supabase',
        ),
        isFalse,
      );
    });

    test('debug still supports explicit demo sessions', () {
      expect(
        AppConfig.resolveDemoRequested(
          releaseMode: false,
          forceDemo: false,
          backendMode: 'demo',
        ),
        isTrue,
      );
      expect(
        AppConfig.resolveDemoRequested(
          releaseMode: false,
          forceDemo: true,
          backendMode: 'supabase',
        ),
        isTrue,
      );
    });
  });
}
