import 'package:flutter_app/core/media_transfer.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Product media lives behind private `/object/authenticated/` URLs, so the
/// seller's marketing flow must hand out real files, never the URL. These cover
/// the outcomes the UI renders when the transfer cannot complete.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Anything that reaches the cache manager needs path_provider, so the actual
  // download/share round trip is only exercisable on a device. What is asserted
  // here is the contract the UI switches on.
  test('an empty selection is a no-op rather than a reported success', () async {
    final saved = await MediaTransfer.saveToGallery(const []);
    expect(saved.succeeded, 0);
    expect(saved.failed, 0);
    expect(saved.isCompleteSuccess, isFalse);

    final shared = await MediaTransfer.share(const []);
    expect(shared.succeeded, 0);
    expect(shared.isCompleteSuccess, isFalse);
  });

  test('a failed transfer is never reported as a success', () {
    const result = MediaTransferResult(succeeded: 0, failed: 3);

    expect(result.isCompleteFailure, isTrue);
    expect(result.isCompleteSuccess, isFalse);
  });

  test('a partial transfer is not reported as a complete success', () {
    const result = MediaTransferResult(succeeded: 2, failed: 1);

    expect(result.isCompleteSuccess, isFalse);
    expect(result.isCompleteFailure, isFalse);
  });

  test('materialize refuses an item without a URL', () async {
    const missing = MediaItem(id: 'media-2', type: MediaType.image, url: '  ');

    await expectLater(
      MediaTransfer.materialize(missing),
      throwsA(isA<FormatException>()),
    );
  });
}
