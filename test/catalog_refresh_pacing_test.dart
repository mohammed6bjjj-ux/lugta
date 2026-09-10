import 'package:flutter_app/data/catalog_refresh_pacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog bursts respect cooldown and retain cross-device jitter', () {
    final now = DateTime.utc(2026, 9, 6);
    expect(
      catalogRealtimeDelay(now, null, 0),
      const Duration(milliseconds: 700),
    );
    expect(
      catalogRealtimeDelay(now, null, 1200),
      const Duration(milliseconds: 1900),
    );
    expect(
      catalogRealtimeDelay(now, now.add(const Duration(seconds: 10)), 800),
      const Duration(seconds: 10),
    );
    expect(
      catalogRealtimeDelay(now, now.subtract(const Duration(seconds: 1)), 500),
      const Duration(milliseconds: 1200),
    );
  });
}
