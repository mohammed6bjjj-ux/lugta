import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/product/product_video_player.dart';

void main() {
  const media = MediaItem(
    id: 'video-1',
    type: MediaType.video,
    url: 'https://example.test/video.mp4?token=signed',
  );

  testWidgets('initializes and controls the real video surface', (
    tester,
  ) async {
    final controller = _FakeVideoController();
    await tester.pumpWidget(
      _testApp(
        ProductVideoPlayer(
          item: media,
          active: true,
          controllerFactory: (_) => controller,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
    expect(find.byKey(const Key('product-video-play')), findsOneWidget);

    await tester.tap(find.byKey(const Key('product-video-ready')));
    await tester.pump();
    expect(controller.playCalls, 1);
    expect(find.byKey(const Key('product-video-play')), findsNothing);

    await tester.pumpWidget(
      _testApp(
        ProductVideoPlayer(
          item: media,
          active: false,
          controllerFactory: (_) => controller,
        ),
      ),
    );
    await tester.pump();
    expect(controller.pauseCalls, 1);
  });

  testWidgets('shows an error and retries with a fresh controller', (
    tester,
  ) async {
    final failing = _FakeVideoController(initializeError: StateError('bad'));
    final working = _FakeVideoController();
    var attempts = 0;

    await tester.pumpWidget(
      _testApp(
        ProductVideoPlayer(
          item: media,
          active: true,
          controllerFactory: (_) => attempts++ == 0 ? failing : working,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('product-video-error')), findsOneWidget);
    expect(failing.disposeCalls, 1);

    await tester.tap(find.byKey(const Key('product-video-retry')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
    expect(attempts, 2);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(width: 360, height: 640, child: child),
    ),
  );
}

class _FakeVideoController implements ProductVideoController {
  _FakeVideoController({this.initializeError});

  final Object? initializeError;
  final List<VoidCallback> _listeners = [];
  bool _initialized = false;
  bool _playing = false;
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @override
  bool get isInitialized => _initialized;
  @override
  bool get isPlaying => _playing;
  @override
  bool get isBuffering => false;
  @override
  bool get hasError => false;
  @override
  String? get errorDescription => null;
  @override
  double get aspectRatio => 16 / 9;
  @override
  Duration get duration => const Duration(seconds: 30);
  @override
  Duration get position => const Duration(seconds: 2);

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);
  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Future<void> initialize() async {
    if (initializeError != null) throw initializeError!;
    _initialized = true;
    _notify();
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    _playing = true;
    _notify();
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _playing = false;
    _notify();
  }

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Widget buildVideo() =>
      const ColoredBox(key: Key('fake-video-surface'), color: Colors.blue);

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}
