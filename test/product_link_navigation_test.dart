import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/product_link_inbox.dart';
import 'package:flutter_app/app/routes.dart';
import 'package:flutter_app/core/widgets/app_network_image.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/product_links.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/product/product_strings.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '22222222-2222-4222-8222-222222222222';
final _product = Product(
  id: _id,
  nameAr: 'Fresh target',
  categoryId: 'watches',
  description: '',
  specs: const {},
  variants: const [],
  media: const [],
  wholesalePrice: 6500,
  suggestedPrice: 15000,
  createdAt: DateTime(2026),
);

class _Catalog extends DemoCatalogRepository {
  int targetedReads = 0;
  Future<Product> Function()? load;
  @override
  Future<Product> fetchProduct(String id) async {
    targetedReads++;
    if (id != _id) throw const BackendException('Unavailable');
    return load == null ? _product : await load!();
  }
}

void main() {
  late _Catalog catalog;
  late AppRepositories base;
  var sequence = 0;
  Future<void> configure({
    AccountStatus status = AccountStatus.approved,
  }) async {
    base = createDemoRepositories();
    catalog = _Catalog();
    final seller = (base.profile as DemoProfileRepository).seller;
    (base.profile as DemoProfileRepository).seller = Seller(
      id: seller.id,
      name: seller.name,
      phone: seller.phone,
      storeName: seller.storeName,
      instagramUrl: seller.instagramUrl,
      governorateId: seller.governorateId,
      status: status,
      joinedAt: seller.joinedAt,
    );
    await base.auth.signIn(phone: '07700000000', password: 'test-password');
    await session.configure(
      AppRepositories(
        auth: base.auth,
        profile: base.profile,
        catalog: catalog,
        orders: base.orders,
        wallet: base.wallet,
        notifications: base.notifications,
        isDemo: true,
      ),
      loadInitialData: true,
    );
  }

  Widget app(List<Product> opened) => MaterialApp(
    key: ValueKey(sequence++),
    onGenerateRoute: (settings) {
      expect(settings.name, Routes.productDetail);
      opened.add(settings.arguments! as Product);
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Product opened')),
      );
    },
    home: const MainShell(deviceTokens: NoopDeviceTokenRegistrar()),
  );
  // Different URI first resets the two-second native duplicate filter between tests.
  void link() {
    productLinkInbox.accept(
      ProductLinks.forProduct('33333333-3333-4333-8333-333333333333')!,
    );
    productLinkInbox.take();
    productLinkInbox.accept(ProductLinks.forProduct(_id)!);
  }

  tearDown(() => productLinkInbox.take());
  testWidgets('warm link schedules a frame while the foreground app is idle', (
    tester,
  ) async {
    await tester.runAsync(configure);
    final opened = <Product>[];
    AppNetworkImage.debugImageProvider = (_) => MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() => AppNetworkImage.debugImageProvider = null);
    await tester.pumpWidget(app(opened));
    await tester.tap(find.byKey(const ValueKey('profile_nav_tab')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    link();
    // Pumping manually without this assertion would hide the idle-app bug.
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened.single.id, _id);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'cold and warm link open freshly fetched exact product only once',
    (tester) async {
      await tester.runAsync(configure);
      final opened = <Product>[];
      link();
      await tester.pumpWidget(app(opened));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened.single, same(_product));
      expect(catalog.targetedReads, 1);
      productLinkInbox.accept(ProductLinks.forProduct(_id)!);
      await tester.pump();
      expect(opened.length, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(opened));
      link();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened.length, 2);
      expect(catalog.targetedReads, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('pending approval preserves target and makes no product read', (
    tester,
  ) async {
    await tester.runAsync(() => configure(status: AccountStatus.pending));
    final opened = <Product>[];
    link();
    await tester.pumpWidget(app(opened));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, isEmpty);
    expect(catalog.targetedReads, 0);
    expect(productLinkInbox.pending, _id);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(configure);
    await tester.pumpWidget(app(opened));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened.single.id, _id);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('missing product produces safe message without navigating', (
    tester,
  ) async {
    await tester.runAsync(configure);
    catalog.load = () async =>
        throw const BackendException('Private server error');
    final opened = <Product>[];
    link();
    await tester.pumpWidget(app(opened));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, isEmpty);
    expect(find.text(ProductStrings.productLinkUnavailable), findsOneWidget);
    expect(find.text('Private server error'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'signing out while product loads cannot open data for former user',
    (tester) async {
      await tester.runAsync(configure);
      final gate = Completer<Product>();
      catalog.load = () => gate.future;
      final opened = <Product>[];
      link();
      await tester.pumpWidget(app(opened));
      await tester.pump();
      expect(catalog.targetedReads, 1);
      await tester.runAsync(base.auth.signOut);
      gate.complete(_product);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
