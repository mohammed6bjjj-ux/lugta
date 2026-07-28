import 'dart:async';

import 'package:flutter_app/data/async_request_deduplicator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shares one in-flight request with repeated callers', () async {
    final deduplicator = AsyncRequestDeduplicator();
    final completer = Completer<void>();
    var calls = 0;

    final first = deduplicator.run(() {
      calls += 1;
      return completer.future;
    });
    final second = deduplicator.run(() {
      calls += 1;
      return Future<void>.value();
    });

    expect(identical(first, second), isTrue);
    expect(calls, 1);
    expect(deduplicator.isRunning, isTrue);

    completer.complete();
    await first;

    expect(deduplicator.isRunning, isFalse);
  });

  test('accepts a new request after failure', () async {
    final deduplicator = AsyncRequestDeduplicator();
    var calls = 0;

    await expectLater(
      deduplicator.run(() {
        calls += 1;
        return Future<void>.error(StateError('offline'));
      }),
      throwsStateError,
    );

    await deduplicator.run(() async {
      calls += 1;
    });

    expect(calls, 2);
    expect(deduplicator.isRunning, isFalse);
  });
}
