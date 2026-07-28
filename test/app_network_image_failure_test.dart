import 'dart:async';

import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries weak-network and server failures but not permanent 4xx', () {
    expect(appNetworkImageFailureIsRetryable(TimeoutException('slow')), isTrue);
    expect(
      appNetworkImageFailureIsRetryable(
        const HttpExceptionWithStatus(503, 'temporary'),
      ),
      isTrue,
    );
    expect(
      appNetworkImageFailureIsRetryable(
        const HttpExceptionWithStatus(401, 'expired jwt'),
      ),
      isTrue,
    );
    expect(
      appNetworkImageFailureIsRetryable(
        const HttpExceptionWithStatus(403, 'forbidden'),
      ),
      isFalse,
    );
    expect(
      appNetworkImageFailureIsRetryable(
        const HttpExceptionWithStatus(404, 'missing'),
      ),
      isFalse,
    );
  });

  test('recognizes decoder corruption separately from transport errors', () {
    expect(
      appNetworkImageFailureIsCorrupt(
        const FormatException('Invalid image data'),
      ),
      isTrue,
    );
    expect(
      appNetworkImageFailureIsCorrupt(TimeoutException('offline')),
      isFalse,
    );
  });
}
