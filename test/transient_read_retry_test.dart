import 'dart:async';

import 'package:flutter_app/data/repositories/transient_read_retry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('TransientReadRetry', () {
    test(
      'returns immediately without sleeping after a successful read',
      () async {
        var attempts = 0;
        final sleeps = <Duration>[];
        final policy = TransientReadRetry(
          sleep: (delay) async => sleeps.add(delay),
          jitter: (_) => 0,
        );

        final value = await policy.run(() async {
          attempts += 1;
          return 42;
        });

        expect(value, 42);
        expect(attempts, 1);
        expect(sleeps, isEmpty);
      },
    );

    test('retries a transient timeout at most twice with backoff', () async {
      var attempts = 0;
      final sleeps = <Duration>[];
      final policy = TransientReadRetry(
        sleep: (delay) async => sleeps.add(delay),
        jitter: (_) => 0,
      );

      final value = await policy.run<int>(() async {
        attempts += 1;
        if (attempts < 3) throw TimeoutException('temporary timeout');
        return 7;
      });

      expect(value, 7);
      expect(attempts, 3);
      expect(sleeps, const [
        Duration(milliseconds: 250),
        Duration(milliseconds: 500),
      ]);
    });

    test('stops after the configured two retries', () async {
      var attempts = 0;
      final policy = TransientReadRetry(sleep: (_) async {}, jitter: (_) => 0);

      await expectLater(
        policy.run<void>(() async {
          attempts += 1;
          throw TimeoutException('still unavailable');
        }),
        throwsA(isA<TimeoutException>()),
      );
      expect(attempts, 3);
    });

    test('retries HTTP 429 and 5xx PostgREST failures', () async {
      for (final code in [
        '429',
        '500',
        '503',
        '599',
        'PGRST000',
        'PGRST001',
        'PGRST002',
        'PGRST003',
      ]) {
        var attempts = 0;
        final policy = TransientReadRetry(
          sleep: (_) async {},
          jitter: (_) => 0,
        );

        final value = await policy.run<int>(() async {
          attempts += 1;
          if (attempts == 1) {
            throw PostgrestException(message: 'temporary', code: code);
          }
          return 1;
        });

        expect(value, 1, reason: 'HTTP $code should be retried');
        expect(attempts, 2, reason: 'HTTP $code should retry exactly once');
      }
    });

    test(
      'never retries permission, validation, auth-like, or 4xx errors',
      () async {
        final errors = <Object>[
          const PostgrestException(message: 'permission denied', code: '42501'),
          const PostgrestException(message: 'invalid input', code: '23514'),
          const PostgrestException(message: 'unauthorized', code: '401'),
          const PostgrestException(message: 'not found', code: '404'),
          StateError('invalid local state'),
        ];

        for (final error in errors) {
          var attempts = 0;
          final policy = TransientReadRetry(
            sleep: (_) async {},
            jitter: (_) => 0,
          );

          await expectLater(
            policy.run<void>(() async {
              attempts += 1;
              throw error;
            }),
            throwsA(same(error)),
          );
          expect(attempts, 1, reason: '$error must not be retried');
        }
      },
    );

    test('recognizes platform transport exceptions without dart:io', () async {
      var attempts = 0;
      final policy = TransientReadRetry(sleep: (_) async {}, jitter: (_) => 0);

      final value = await policy.run<int>(() async {
        attempts += 1;
        if (attempts == 1) throw const ClientException('network unavailable');
        return 9;
      });

      expect(value, 9);
      expect(attempts, 2);
    });

    test(
      'enforces one overall timeout without starting an overlapping retry',
      () async {
        var attempts = 0;
        final policy = TransientReadRetry(
          overallTimeout: const Duration(milliseconds: 5),
          sleep: (_) async {},
          jitter: (_) => 0,
        );

        await expectLater(
          policy.run<int>(() {
            attempts += 1;
            return Completer<int>().future;
          }),
          throwsA(isA<TimeoutException>()),
        );
        expect(attempts, 1);
      },
    );

    test('adds bounded jitter to exponential delays', () {
      final policy = TransientReadRetry(jitter: (upperBound) => upperBound - 1);

      expect(policy.delayBeforeRetry(0), const Duration(milliseconds: 375));
      expect(policy.delayBeforeRetry(1), const Duration(milliseconds: 750));
      expect(policy.delayBeforeRetry(20), const Duration(seconds: 2));
    });
  });
}

class ClientException implements Exception {
  const ClientException(this.message);

  final String message;

  @override
  String toString() => 'ClientException: $message';
}
