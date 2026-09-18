import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/data/repositories/supabase_storefront_repository.dart';
import 'package:flutter_app/features/storefront/storefront_request_screen.dart';
import 'package:flutter_app/features/storefront/storefront_requests_view_model.dart';
import 'package:flutter_app/features/storefront/storefront_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'storefront_test_support.dart';
import 'storefront_widgets_test.dart' show pumpStore;

Map<String, Object?> requestData() => {
  'id': testRequest.id,
  'request_number': 'WEB-EXPIRED',
  'status': 'pending',
  'version': 1,
  'customer_name': 'زبون اختبار',
  'customer_phone': '07700000000',
  'sale_total': 18000,
  'delivery_fee': 5000,
  'total_collect_amount': 23000,
  'created_at': '2020-01-01T00:00:00Z',
  'expires_at': '2020-01-08T00:00:00Z',
};

void main() {
  setUpAll(() async {
    await (FontLoader('Zain')
          ..addFont(rootBundle.load('assets/fonts/Zain-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Zain-Bold.ttf')))
        .load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (cache.path.split(Platform.pathSeparator).last != 'cache') {
      cache = cache.parent;
    }
    final icons = await File(
      '${cache.path}/artifacts/material_fonts/materialicons-regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
  });
  test(
    'expiry parses UTC, honors boundary and never changes terminal status',
    () {
      final row = requestData();
      final request = parseStorefrontRequest(row);
      expect(request.expiresAt, DateTime.utc(2020, 1, 8));
      expect(request.isExpiredAt(DateTime.utc(2020, 1, 7, 23, 59, 59)), false);
      expect(request.isExpiredAt(DateTime.utc(2020, 1, 8)), true);
      for (final status in ['approved', 'rejected']) {
        expect(
          parseStorefrontRequest({...row, 'status': status}).expired,
          false,
        );
      }
      row.remove('expires_at');
      expect(parseStorefrontRequest(row).expiresAt, isNull);
    },
  );

  test(
    'expired approval cannot send RPC; rejection remains possible',
    () async {
      final repo = TestStorefrontRepository()
        ..request = parseStorefrontRequest(requestData());
      final model = StorefrontRequestsViewModel(
        repository: repo,
        isCurrentUser: () => true,
      );
      addTearDown(model.dispose);
      await model.loadRequest(repo.request.id);
      expect(await model.approve(repo.request), isNull);
      expect(repo.approveCalls, 0);
      expect(model.errorCode, 'storefront_request_expired');
      await model.reject(repo.request, 'انتهت صلاحية الطلب');
      expect(repo.rejectCalls, 1);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'expired request explains reason, disables approve and retains reject, dark=$dark',
      (tester) async {
        final repo = TestStorefrontRepository()
          ..request = parseStorefrontRequest(requestData());
        final model = StorefrontRequestsViewModel(
          repository: repo,
          isCurrentUser: () => true,
        );
        addTearDown(model.dispose);
        await pumpStore(
          tester,
          StorefrontRequestScreen(requestId: repo.request.id, viewModel: model),
          width: 375,
          scale: 2,
          dark: dark,
        );
        expect(find.text(StorefrontRequestStrings.expired), findsOneWidget);
        expect(
          find.text(StorefrontRequestStrings.error('expired')),
          findsOneWidget,
        );
        final approve = find.byKey(
          const ValueKey('approve_storefront_request'),
        );
        await tester.scrollUntilVisible(
          approve,
          350,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<StorefrontAction>(approve).onPressed, isNull);
        expect(repo.approveCalls, 0);
        expect(find.text(StorefrontRequestStrings.reject), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('storefront_visual_surface')),
          matchesGoldenFile(
            'goldens/storefront-expired-${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
