import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/background_media_downloads.dart';
import 'package:flutter_app/core/media_transfer.dart';
import 'package:flutter_app/core/network_media_request.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const photo = MediaItem(
    id: 'photo',
    type: MediaType.image,
    url:
        'https://project.supabase.co/storage/v1/object/authenticated/catalog-media/p1/photo.jpg',
  );
  const video = MediaItem(
    id: 'video',
    type: MediaType.video,
    url:
        'https://project.supabase.co/storage/v1/object/authenticated/catalog-media/p1/video.mp4',
  );
  final records = <String, String>{};
  final enqueues = <Map<dynamic, dynamic>>[];
  var signs = 0;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    signs = 0;
    records.clear();
    enqueues.clear();
    NetworkMediaRequest.configure(
      headersProvider: () => {'Authorization': 'Bearer must-not-be-persisted'},
      scopeProvider: () => 'seller-1',
      backgroundUrlProvider: (url) async {
        signs++;
        return '${url.replaceFirst('/authenticated/', '/sign/')}?token=object-only';
      },
    );
    messenger.setMockMethodCallHandler(BackgroundMediaDownloads.channel, (
      call,
    ) async {
      if (call.method == 'supported') return true;
      final args = call.arguments as Map;
      final key = args['key'] as String;
      if (call.method == 'lookup') {
        return records.containsKey(key) ? {'state': records[key]} : null;
      }
      enqueues.add(args);
      records[key] = 'queued';
      return {'state': 'queued', 'id': enqueues.length};
    });
  });
  tearDown(() {
    NetworkMediaRequest.reset();
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(BackgroundMediaDownloads.channel, null);
  });

  test(
    'queue acknowledges background work, not completed gallery saves',
    () async {
      final result = await MediaTransfer.saveToGallery([photo, video]);
      expect(result.queued, 2);
      expect(result.succeeded, 0);
      expect(result.isCompleteSuccess, false);
      expect(result.isCompleteFailure, false);
      expect(signs, 2);
      expect(enqueues.every((e) => !e.containsKey('headers')), true);
      expect(enqueues.toString(), isNot(contains('must-not-be-persisted')));
      expect(enqueues.first['url'], contains('/sign/'));
      expect(enqueues.last['video'], true);
    },
  );

  test(
    'repeated and overlapping selection queues one copy per object',
    () async {
      final results = await Future.wait([
        MediaTransfer.saveToGallery([photo, video, photo]),
        MediaTransfer.saveToGallery([photo]),
        MediaTransfer.saveToGallery([video, photo]),
      ]);
      expect(enqueues.length, 2);
      expect(signs, 2);
      expect(results.every((r) => r.failed == 0), true);
      await MediaTransfer.saveToGallery([photo, video]);
      expect(
        enqueues.length,
        2,
        reason: 'Native lookup survives sheet reopening',
      );
      expect(signs, 2);
    },
  );

  test(
    'completed native records are reported saved without another download',
    () async {
      await MediaTransfer.saveToGallery([photo]);
      records.updateAll((_, _) => 'saved');
      final result = await MediaTransfer.saveToGallery([photo]);
      expect(result.succeeded, 1);
      expect(result.queued, 0);
      expect(enqueues.length, 1);
    },
  );

  test(
    'a bad URL does not prevent the next file and retry skips accepted file',
    () async {
      const bad = MediaItem(
        id: 'bad',
        type: MediaType.image,
        url: 'http://unsafe.test/a.jpg',
      );
      final result = await MediaTransfer.saveToGallery([bad, photo]);
      expect(result.failed, 1);
      expect(result.queued, 1);
      await MediaTransfer.saveToGallery([bad, photo]);
      expect(enqueues.length, 1);
    },
  );

  test(
    'private authorization failure is not queued or reported saved',
    () async {
      NetworkMediaRequest.reset();
      final result = await MediaTransfer.saveToGallery([photo]);
      expect(result.failed, 1);
      expect(result.isCompleteFailure, true);
      expect(enqueues, isEmpty);
    },
  );

  test(
    'concurrent native preparation is single flight before lookup finishes',
    () async {
      final gate = Completer<void>();
      var calls = 0;
      messenger.setMockMethodCallHandler(BackgroundMediaDownloads.channel, (
        call,
      ) async {
        calls++;
        if (call.method == 'lookup') {
          await gate.future;
          return null;
        }
        return {'state': 'queued'};
      });
      final a = BackgroundMediaDownloads.enqueue(photo, 'photo.jpg');
      final b = BackgroundMediaDownloads.enqueue(photo, 'photo.jpg');
      expect(identical(a, b), true);
      gate.complete();
      await Future.wait([a, b]);
      expect(calls, 2);
      expect(signs, 1);
    },
  );

  test('unsupported platform does not invoke Android channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await BackgroundMediaDownloads.supported(), false);
  });

  test('native enqueue rejection permits a subsequent retry', () async {
    var reject = true;
    messenger.setMockMethodCallHandler(BackgroundMediaDownloads.channel, (
      call,
    ) async {
      if (call.method == 'supported') return true;
      if (call.method == 'lookup') return null;
      if (reject) throw PlatformException(code: 'download_enqueue_failed');
      return {'state': 'queued'};
    });
    expect((await MediaTransfer.saveToGallery([photo])).failed, 1);
    reject = false;
    expect((await MediaTransfer.saveToGallery([photo])).queued, 1);
  });
}
