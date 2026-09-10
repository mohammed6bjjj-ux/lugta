import 'dart:async';
import 'package:flutter_app/core/network_image_cache.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _Response implements FileServiceResponse {
  _Response(this.content);
  @override
  final Stream<List<int>> content;
  @override
  int? get contentLength => 2;
  @override
  int get statusCode => 200;
  @override
  String get fileExtension => '.jpg';
  @override
  String? get eTag => 'etag';
  @override
  DateTime get validTill => DateTime(2030);
}

void main() {
  test('a stalled body fails promptly and cancels its subscription', () async {
    var cancelled = false;
    final source = StreamController<List<int>>(
      onCancel: () {
        cancelled = true;
      },
    );
    final response = IdleTimeoutFileResponse(
      _Response(source.stream),
      idleTimeout: const Duration(milliseconds: 10),
    );
    final result = response.content.toList();
    source.add([1]);
    await expectLater(result, throwsA(isA<TimeoutException>()));
    expect(cancelled, true);
    await source.close();
  });
  test('complete content and cache metadata pass through unchanged', () async {
    final response = IdleTimeoutFileResponse(
      _Response(
        Stream.fromIterable([
          [1],
          [2],
        ]),
      ),
    );
    expect(await response.content.toList(), [
      [1],
      [2],
    ]);
    expect(response.statusCode, 200);
    expect(response.fileExtension, '.jpg');
    expect(response.eTag, 'etag');
    expect(response.contentLength, 2);
  });
  test('underlying connection errors are not swallowed', () async {
    final response = IdleTimeoutFileResponse(
      _Response(Stream.error(StateError('connection closed'))),
    );
    await expectLater(response.content.toList(), throwsStateError);
  });
}
