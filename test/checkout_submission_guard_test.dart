import 'package:flutter/material.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/order_wizard/order_wizard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _SlowCountingOrdersRepository ordersRepository;

  setUp(() async {
    appSettings.language = AppLanguage.en;
    final base = createDemoRepositories();
    await base.auth.signIn(phone: '07712345678', password: 'test-password');
    final orders = _SlowCountingOrdersRepository(base.orders);
    await session.configure(
      AppRepositories(
        auth: base.auth,
        profile: base.profile,
        catalog: base.catalog,
        orders: orders,
        wallet: base.wallet,
        notifications: base.notifications,
        isDemo: true,
      ),
    );
    ordersRepository = orders;
  });

  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
    appSettings.language = AppLanguage.ar;
  });

  testWidgets('rapid confirm taps create only one backend order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = session.products.first;
    final variant = product.variants.firstWhere((item) => item.stock > 0);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: OrderWizardScreen(product: product),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(ValueKey<String>('variant_increment_${variant.id}')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('order_wizard_next_button')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byKey(const ValueKey('order_sale_price_field')),
      product.suggestedPrice.toString(),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('order_wizard_next_button')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(
      find.byKey(const ValueKey('order_customer_name_field')),
      'Test Customer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('order_customer_phone_field')),
      '07701234567',
    );
    await tester.enterText(
      find.byKey(const ValueKey('order_address_field')),
      'Baghdad test address',
    );
    final governorateField = find.byKey(
      const ValueKey('order_governorate_field'),
    );
    await tester.ensureVisible(governorateField);
    await tester.tap(governorateField);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(session.governorates.first.localizedName).last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('order_wizard_next_button')));
    await tester.pump(const Duration(milliseconds: 500));

    final confirm = find.byKey(const ValueKey('order_wizard_next_button'));
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(ordersRepository.createCalls, 1);
  });
}

class _SlowCountingOrdersRepository implements OrdersRepository {
  _SlowCountingOrdersRepository(this._delegate);

  final OrdersRepository _delegate;
  int createCalls = 0;

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    createCalls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _delegate.createOrder(request);
  }

  @override
  Future<void> cancelOrder(String orderId, {required String clientRequestId}) =>
      _delegate.cancelOrder(orderId, clientRequestId: clientRequestId);

  @override
  Future<Order> fetchOrder(String orderId) => _delegate.fetchOrder(orderId);

  @override
  Future<List<Order>> fetchOrders() => _delegate.fetchOrders();

  @override
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  }) => _delegate.submitChangeRequest(
    orderId: orderId,
    type: type,
    reason: reason,
    proposedChanges: proposedChanges,
    clientRequestId: clientRequestId,
  );

  @override
  Future<OrderComplaint> createComplaint({
    required String orderId,
    required OrderComplaintKind kind,
    required String subject,
    required String message,
    required String clientRequestId,
  }) => _delegate.createComplaint(
    orderId: orderId,
    kind: kind,
    subject: subject,
    message: message,
    clientRequestId: clientRequestId,
  );
}
