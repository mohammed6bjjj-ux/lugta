import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef RetrySleep = Future<void> Function(Duration delay);
typedef RetryJitter = int Function(int upperBound);

/// A small, bounded retry policy for idempotent Data API reads only.
///
/// Call sites must disable PostgREST's built-in retry for the wrapped request
/// so the two policies cannot multiply each other's attempts. Never use this
/// for mutations. The timeout covers the whole operation; it does not start a
/// new HTTP request while a timed-out Future may still be completing.
class TransientReadRetry {
  TransientReadRetry({
    this.maxRetries = 2,
    this.overallTimeout = const Duration(seconds: 12),
    this.baseDelay = const Duration(milliseconds: 250),
    this.maxDelay = const Duration(seconds: 2),
    RetrySleep? sleep,
    RetryJitter? jitter,
  }) : assert(maxRetries >= 0),
       assert(overallTimeout > Duration.zero),
       assert(baseDelay >= Duration.zero),
       assert(maxDelay >= baseDelay),
       _sleep = sleep ?? _defaultSleep,
       _jitter = jitter ?? Random().nextInt;

  final int maxRetries;
  final Duration overallTimeout;
  final Duration baseDelay;
  final Duration maxDelay;
  final RetrySleep _sleep;
  final RetryJitter _jitter;

  Future<T> run<T>(Future<T> Function() read) {
    var expired = false;
    return _runWithRetries(read, () => expired).timeout(
      overallTimeout,
      onTimeout: () {
        expired = true;
        throw TimeoutException('Supabase read timed out.', overallTimeout);
      },
    );
  }

  Future<T> _runWithRetries<T>(
    Future<T> Function() read,
    bool Function() isExpired,
  ) async {
    var retries = 0;
    while (true) {
      if (isExpired()) {
        throw TimeoutException('Supabase read timed out.', overallTimeout);
      }
      try {
        return await read();
      } catch (error, stackTrace) {
        if (isExpired() ||
            retries >= maxRetries ||
            !isTransientReadFailure(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        final delay = delayBeforeRetry(retries);
        retries += 1;
        await _sleep(delay);
      }
    }
  }

  /// [retryIndex] is zero for the delay before the first retry.
  Duration delayBeforeRetry(int retryIndex) {
    final baseMilliseconds = baseDelay.inMilliseconds;
    if (baseMilliseconds == 0) return Duration.zero;

    final exponent = retryIndex.clamp(0, 30).toInt();
    final exponential = min(
      baseMilliseconds * (1 << exponent),
      maxDelay.inMilliseconds,
    ).toInt();
    final jitterWindow = max(1, (exponential ~/ 2) + 1).toInt();
    final jitter = _jitter(jitterWindow).clamp(0, jitterWindow - 1).toInt();
    return Duration(
      milliseconds: min(exponential + jitter, maxDelay.inMilliseconds).toInt(),
    );
  }
}

bool isTransientReadFailure(Object error) {
  if (error is TimeoutException) return true;

  // Auth, RLS, validation and other Postgres errors must surface immediately.
  // PostgREST uses a numeric HTTP status as `code` for gateway/non-JSON
  // failures, while normal database errors use codes such as 42501 or 23514.
  if (error is PostgrestException) {
    final code = (error.code ?? '').trim().toUpperCase();
    final status = int.tryParse(code);
    return status == 429 ||
        (status != null && status >= 500 && status <= 599) ||
        _postgrestServerCodes.contains(code);
  }
  if (error is AuthException || error is StorageException) return false;

  // The concrete transport exception differs between dart:io and web. Keep
  // this classifier platform-neutral so the same app still compiles for web.
  final type = error.runtimeType.toString().toLowerCase();
  if (type.contains('socketexception') ||
      type.contains('clientexception') ||
      type.contains('handshakeexception') ||
      type.contains('httpexception') ||
      type.contains('tlsexception')) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return _transportMessages.any(message.contains);
}

const _transportMessages = <String>[
  'connection reset by peer',
  'connection closed before full header',
  'connection refused',
  'connection timed out',
  'failed host lookup',
  'network is unreachable',
  'networkerror when attempting to fetch resource',
  'software caused connection abort',
  'xmlhttprequest error',
  'failed to fetch',
];

// PostgREST preserves these JSON codes instead of the HTTP status. They map
// to 503/504 and are the only PGRST codes treated as transient here.
const _postgrestServerCodes = <String>{
  'PGRST000',
  'PGRST001',
  'PGRST002',
  'PGRST003',
};

Future<void> _defaultSleep(Duration delay) => Future<void>.delayed(delay);
