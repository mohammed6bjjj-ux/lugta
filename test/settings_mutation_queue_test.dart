import 'dart:async';

import 'package:flutter_app/features/profile/settings_mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SettingsSnapshot initial() => SettingsSnapshot(
    locale: 'ar',
    notificationPreferences: const {
      'orders': true,
      'wallet': true,
      'products': true,
      'system': true,
    },
  );

  test(
    'serializes writes and patches only the requested notification',
    () async {
      final firstGate = Completer<void>();
      final writes = <SettingsSnapshot>[];
      var active = 0;
      var maximumActive = 0;
      final queue = SettingsMutationQueue(
        initial: initial(),
        persist: (snapshot) async {
          active++;
          maximumActive = active > maximumActive ? active : maximumActive;
          writes.add(snapshot);
          if (writes.length == 1) await firstGate.future;
          active--;
          return snapshot;
        },
      );

      final orders = queue.setNotification('orders', false);
      final wallet = queue.setNotification('wallet', false);
      await pumpEventQueue();

      expect(writes, hasLength(1));
      expect(writes.single.notificationPreferences['orders'], isFalse);
      expect(writes.single.notificationPreferences['wallet'], isTrue);

      firstGate.complete();
      expect((await orders).succeeded, isTrue);
      expect((await wallet).succeeded, isTrue);
      expect(maximumActive, 1);
      expect(writes, hasLength(2));
      expect(writes.last.notificationPreferences['orders'], isFalse);
      expect(writes.last.notificationPreferences['wallet'], isFalse);
    },
  );

  test(
    'an older failed write cannot roll back a newer value for the key',
    () async {
      final gate = Completer<void>();
      var call = 0;
      final queue = SettingsMutationQueue(
        initial: initial(),
        persist: (snapshot) async {
          call++;
          if (call == 1) {
            await gate.future;
            throw StateError('offline');
          }
          return snapshot;
        },
      );

      final older = queue.setNotification('orders', false);
      final newer = queue.setNotification('orders', true);
      gate.complete();

      final olderResult = await older;
      final newerResult = await newer;
      expect(olderResult.succeeded, isFalse);
      expect(olderResult.shouldRollback, isFalse);
      expect(newerResult.succeeded, isTrue);
      expect(queue.confirmed.notificationPreferences['orders'], isTrue);
    },
  );

  test('a failed key rolls back to its confirmed value only', () async {
    final queue = SettingsMutationQueue(
      initial: initial(),
      persist: (_) async => throw StateError('offline'),
    );

    final result = await queue.setNotification('wallet', false);

    expect(result.succeeded, isFalse);
    expect(result.shouldRollback, isTrue);
    expect(result.confirmed.notificationPreferences['wallet'], isTrue);
    expect(result.confirmed.notificationPreferences['orders'], isTrue);
  });

  test('reset invalidates a response from the previous identity', () async {
    final gate = Completer<void>();
    final queue = SettingsMutationQueue(
      initial: initial(),
      persist: (snapshot) async {
        await gate.future;
        return snapshot;
      },
    );

    final pending = queue.setLocale('en');
    final nextIdentity = SettingsSnapshot(
      locale: 'ckb',
      notificationPreferences: const {'orders': false},
    );
    await pumpEventQueue();
    expect(queue.hasPending, isTrue);
    queue.reset(nextIdentity);
    expect(queue.hasPending, isFalse);
    gate.complete();

    final result = await pending;
    expect(result.ignored, isTrue);
    expect(queue.confirmed.locale, 'ckb');
    expect(queue.confirmed.notificationPreferences, {'orders': false});
  });
}
