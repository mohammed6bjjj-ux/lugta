import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_app/data/repositories/supabase_storefront_repository.dart';
import 'package:flutter_app/data/storefront_draft_store.dart';
import 'package:flutter_app/data/storefront_media.dart';
import 'package:flutter_app/data/storefront_models.dart';
import 'package:flutter_app/data/storefront_validation.dart';
import 'package:flutter_app/features/storefront/storefront_requests_view_model.dart';
import 'package:flutter_app/features/storefront/storefront_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storefront_test_support.dart';

void main() {
  test(
    'image selections survive lost acknowledgement without replay',
    () async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          store: testStore,
        ),
      )..listingTimeoutAfterCommit = true;
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await model.load();
      expect(
        await model.saveProduct(
          productId: 'p',
          variantIds: ['black', 'gold'],
          retailPrice: 18000,
          coverMediaId: 'cover',
          variantMedia: {'black': 'one', 'gold': 'two'},
        ),
        isTrue,
      );
      expect(repo.listingCalls, 1);
      expect(model.snapshot!.listings.map((item) => item.imageMediaId), [
        'one',
        'two',
      ]);
      expect(model.snapshot!.listings.map((item) => item.coverMediaId), [
        'cover',
        'cover',
      ]);
    },
  );
  test(
    'batch saves two colours at one price, ignores duplicate tap and reconciles timeout',
    () async {
      final repo =
          TestStorefrontRepository(
              snapshot: StorefrontSnapshot(
                eligible: true,
                completedOrders: 10,
                store: testStore,
              ),
            )
            ..listingTimeoutAfterCommit = true
            ..mutationGate = Completer<void>();
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      await model.load();
      final first = model.saveProduct(
        productId: 'p',
        variantIds: ['black', 'brown'],
        retailPrice: 18000,
      );
      expect(
        await model.saveProduct(
          productId: 'p',
          variantIds: ['black', 'brown'],
          retailPrice: 18000,
        ),
        false,
      );
      repo.mutationGate!.complete();
      expect(await first, true);
      expect(repo.listingCalls, 1);
      expect(model.snapshot!.listings.map((i) => i.retailPrice), [
        18000,
        18000,
      ]);
      model.dispose();
    },
  );
  for (final approve in [true, false]) {
    test(
      'request timeout reads committed state without replay approve=$approve',
      () async {
        final repo = TestStorefrontRepository()
          ..requestTimeoutAfterCommit = true;
        final model = StorefrontRequestsViewModel(
          repository: repo,
          isCurrentUser: () => true,
        );
        await model.load();
        final result = approve
            ? await model.approve(testRequest)
            : await model.reject(testRequest, 'سبب الرفض');
        expect(result!.status, approve ? 'approved' : 'rejected');
        expect(repo.approveCalls + repo.rejectCalls, 1);
        expect(repo.detailCalls, 1);
        expect(model.busy, false);
        model.dispose();
      },
    );
  }
  test(
    'timeout before commit stays pending and never reports success',
    () async {
      final repo = TestStorefrontRepository()
        ..requestTimeoutBeforeCommit = true;
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => true,
      );
      await model.load();
      expect(await model.approve(testRequest), null);
      expect(model.errorCode, 'request_result_unknown');
      expect(model.requests.single.status, 'pending');
      expect(repo.approveCalls, 1);
      model.dispose();
    },
  );
  for (final timeout in [false, true]) {
    test(
      'removal confirms absence, avoids double writes, timeout=$timeout',
      () async {
        final repo = TestStorefrontRepository(
          snapshot: StorefrontSnapshot(
            eligible: true,
            completedOrders: 10,
            store: testStore,
            listings: const [
              StoreListing(
                id: 'one',
                productId: 'p',
                variantId: 'v',
                retailPrice: 20000,
              ),
            ],
          ),
        )..removalTimeoutAfterCommit = timeout;
        final model = StorefrontViewModel(
          repository: repo,
          drafts: MemoryStorefrontDrafts(),
          isCurrentUser: () => true,
        );
        addTearDown(model.dispose);
        await model.load();
        repo.mutationGate = Completer();
        final first = model.removeListing('one');
        expect(await model.removeListing('one'), isFalse);
        repo.mutationGate!.complete();
        expect(await first, isTrue);
        expect(repo.removeCalls, 1);
        expect(model.snapshot!.listings, isEmpty);
      },
    );
  }
  test('unchanged removal response never reports success', () async {
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        store: testStore,
        listings: const [
          StoreListing(
            id: 'one',
            productId: 'p',
            variantId: 'v',
            retailPrice: 20000,
          ),
        ],
      ),
    )..removalUnchanged = true;
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await model.load();
    expect(await model.removeListing('one'), isFalse);
    expect(model.errorCode, 'remove_not_confirmed');
    expect(model.snapshot!.listings, hasLength(1));
  });
  test('Iraqi currency keyboards parse unambiguously', () {
    for (final value in ['٢٥٠٠٠', '۲۵۰۰۰', '25,000', '٢٥٬٠٠٠', '25 000']) {
      expect(parseStorefrontPrice(value), 25000);
    }
    for (final value in ['', '2.5', '٢٫٥', '-2500', '25,00', '1e5', '1,2,3']) {
      expect(parseStorefrontPrice(value), isNull);
    }
  });
  test(
    'lost listing acknowledgement is reconciled with one read and no replay',
    () async {
      final repo = TestStorefrontRepository(
        snapshot: StorefrontSnapshot(
          eligible: true,
          completedOrders: 10,
          store: testStore,
        ),
      )..listingTimeoutAfterCommit = true;
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts(),
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await model.load();
      expect(
        await model.saveListing(
          productId: 'p',
          variantId: 'v',
          retailPrice: 25000,
        ),
        isTrue,
      );
      expect(repo.listingCalls, 1);
      expect(repo.fetchCalls, 2);
      expect(model.snapshot!.listings.single.variantId, 'v');
    },
  );
  test('listing double tap performs one write', () async {
    final repo = TestStorefrontRepository(
      snapshot: StorefrontSnapshot(
        eligible: true,
        completedOrders: 10,
        store: testStore,
      ),
    );
    final model = StorefrontViewModel(
      repository: repo,
      drafts: MemoryStorefrontDrafts(),
      isCurrentUser: () => true,
    );
    addTearDown(model.dispose);
    await model.load();
    repo.mutationGate = Completer();
    final first = model.saveListing(
      productId: 'p',
      variantId: 'v',
      retailPrice: 25000,
    );
    expect(
      await model.saveListing(
        productId: 'p',
        variantId: 'v',
        retailPrice: 25000,
      ),
      isFalse,
    );
    repo.mutationGate!.complete();
    expect(await first, isTrue);
    expect(repo.listingCalls, 1);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'rejection reason mirrors 2–300 and folds pasted controls to spaces',
    () {
      expect(isValidStorefrontRejectionReason('لا'), isTrue);
      expect(isValidStorefrontRejectionReason('ا'), isFalse);
      expect(isValidStorefrontRejectionReason('ا' * 300), isTrue);
      expect(isValidStorefrontRejectionReason('ا' * 301), isFalse);
      expect(
        normalizeStorefrontRejectionReason('  رفض\n  الزبون\t\x00الطلب  '),
        'رفض الزبون الطلب',
      );
    },
  );
  test(
    'slug validation matches server 3–30 and reserved/consecutive-hyphen rules',
    () {
      expect(isValidStorefrontSlug('abc'), isTrue);
      expect(isValidStorefrontSlug('a' * 30), isTrue);
      expect(isValidStorefrontSlug('a' * 31), isFalse);
      expect(isValidStorefrontSlug('ab'), isFalse);
      expect(isValidStorefrontSlug('my--store'), isFalse);
      expect(isValidStorefrontSlug('my-store'), isTrue);
      for (final reserved in [
        'admin',
        'api',
        'www',
        'store',
        'loqta',
        'theme10',
      ]) {
        expect(isValidStorefrontSlug(reserved), isFalse);
      }
    },
  );
  test(
    'server boolean, not client count, controls eligibility and expired stores close',
    () {
      final snapshot = parseStorefrontSnapshot({
        'eligible': false,
        'eligible_order_count': 10,
        'storefront': {
          'id': 's',
          'slug': 'shop',
          'theme_id': 'theme1',
          'published': true,
          'active_until': '2020-01-01T00:00:00Z',
          'items': [],
        },
      });
      expect(snapshot.eligible, isFalse);
      expect(snapshot.store!.isActiveAt(DateTime.utc(2026)), isFalse);
    },
  );
  test('draft persistence is account-scoped, ordered, and cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final a = PreferencesStorefrontDraftStore('a');
    final b = PreferencesStorefrontDraftStore('b');
    unawaited(a.write(const StorefrontDraft(brandName: 'first')));
    await a.write(const StorefrontDraft(brandName: 'latest'));
    expect((await a.read())!.brandName, 'latest');
    expect(await b.read(), isNull);
    await a.clear();
    expect(await a.read(), isNull);
  });
  test(
    'duplicate mutation blocked, no redundant post-save fetch, disk failure not save failure',
    () async {
      final repo = TestStorefrontRepository();
      final drafts = MemoryStorefrontDrafts()..failClear = true;
      final model = StorefrontViewModel(
        repository: repo,
        drafts: drafts,
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await model.load();
      repo.failFetch = true;
      repo.mutationGate = Completer();
      final save = model.save();
      expect(await model.save(), isFalse);
      await model.load();
      expect(repo.fetchCalls, 1);
      repo.mutationGate!.complete();
      expect(await save, isTrue);
      expect(repo.saveCalls, 1);
      expect(model.snapshot!.store, isNotNull);
      expect(model.errorCode, isNull);
    },
  );
  test(
    'mutation cannot race initial load and late user-A data is discarded',
    () async {
      var current = true;
      final repo = TestStorefrontRepository()..fetchGate = Completer();
      final model = StorefrontViewModel(
        repository: repo,
        drafts: MemoryStorefrontDrafts()
          ..value = const StorefrontDraft(brandName: 'private'),
        isCurrentUser: () => current,
      );
      addTearDown(model.dispose);
      final load = model.load();
      await pumpEventQueue();
      expect(await model.save(), isFalse);
      current = false;
      repo.fetchGate!.complete();
      await load;
      expect(model.snapshot, isNull);
      expect(model.draft.brandName, isEmpty);
    },
  );
  test(
    'request direct lookup and stable approval key survive uncertain retry',
    () async {
      final repo = TestStorefrontRepository()..failApprove = true;
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await model.loadRequest(testRequest.id);
      expect(repo.detailCalls, 1);
      expect(repo.cursors, isEmpty);
      expect(await model.approve(testRequest), isNull);
      final key = repo.lastApprovalKey;
      repo.failApprove = false;
      expect((await model.approve(testRequest))!.status, 'approved');
      expect(repo.lastApprovalKey, key);
    },
  );
  test(
    'pending acceptance double tap issues only one RPC and logout hides request',
    () async {
      var current = true;
      final repo = TestStorefrontRepository()..mutationGate = Completer();
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => current,
      );
      addTearDown(model.dispose);
      await model.load();
      final first = model.approve(testRequest);
      expect(await model.approve(testRequest), isNull);
      expect(repo.approveCalls, 1);
      current = false;
      repo.mutationGate!.complete();
      expect(await first, isNull);
      expect(model.requests, isEmpty);
    },
  );
  test('logo sniffing rejects forged extension and SVG', () {
    expect(storefrontLogoMime(Uint8List.fromList('<svg/>'.codeUnits)), isNull);
    expect(
      storefrontLogoMime(Uint8List.fromList([0xff, 0xd8, 0xff])),
      'image/jpeg',
    );
    expect(
      storefrontLogoMime(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
      'image/png',
    );
  });
}
