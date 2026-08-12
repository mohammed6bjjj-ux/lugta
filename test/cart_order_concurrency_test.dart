import 'dart:async';

import 'package:flutter_app/data/mock_data.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/sales_analytics.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await session.configure(createDemoRepositories(), loadInitialData: false);
  });

  test(
    'successful delayed cart order preserves cart changes made in flight',
    () async {
      final base = createDemoRepositories();
      await base.auth.signIn(phone: '07712345678', password: 'test-password');
      final delayedOrders = _DelayedOrdersRepository(base.orders);
      await session.configure(
        AppRepositories(
          auth: base.auth,
          profile: base.profile,
          catalog: base.catalog,
          orders: delayedOrders,
          wallet: base.wallet,
          notifications: base.notifications,
          promotions: base.promotions,
          isDemo: true,
        ),
        loadInitialData: false,
      );

      final products = MockData.products
          .where(
            (product) => product.variants.any((variant) => variant.stock >= 3),
          )
          .take(2)
          .toList(growable: false);
      expect(products, hasLength(2));
      final firstProduct = products[0];
      final secondProduct = products[1];
      final firstVariant = firstProduct.variants.firstWhere(
        (variant) => variant.stock >= 3,
      );
      final secondVariant = secondProduct.variants.firstWhere(
        (variant) => variant.stock >= 3,
      );

      session.addToCart(product: firstProduct, variant: firstVariant);
      final pendingOrder = session.createCartOrder(
        governorate: MockData.governorates.first,
        customerName: 'زبون اختبار',
        customerPhone: '07701234567',
        addressDetails: 'بغداد - عنوان اختبار',
      );

      final submittedRequest = await delayedOrders.requestStarted.future;
      expect(submittedRequest.lines, hasLength(1));
      expect(submittedRequest.lines.single.variant.id, firstVariant.id);
      expect(submittedRequest.lines.single.quantity, 1);

      session.updateCartQuantity(firstVariant.id, 2);
      session.addToCart(product: secondProduct, variant: secondVariant);

      delayedOrders.release.complete();
      final createdOrder = await pendingOrder;

      expect(delayedOrders.createCalls, 1);
      expect(session.orders.first.id, createdOrder.id);
      expect(session.cartLineCount, 2);
      expect(session.cartItemForVariant(firstVariant.id)?.quantity, 2);
      expect(session.cartItemForVariant(secondVariant.id)?.quantity, 1);
    },
  );
}

class _DelayedOrdersRepository implements OrdersRepository {
  _DelayedOrdersRepository(this._delegate);

  final OrdersRepository _delegate;
  final Completer<CreateOrderRequest> requestStarted =
      Completer<CreateOrderRequest>();
  final Completer<void> release = Completer<void>();
  int createCalls = 0;

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    createCalls++;
    if (!requestStarted.isCompleted) requestStarted.complete(request);
    await release.future;
    return _delegate.createOrder(request);
  }

  @override
  Future<void> cancelOrder(String orderId, {required String clientRequestId}) =>
      _delegate.cancelOrder(orderId, clientRequestId: clientRequestId);

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

  @override
  Future<Order> fetchOrder(String orderId) => _delegate.fetchOrder(orderId);

  @override
  Future<SalesAnalyticsSnapshot> fetchSalesAnalytics({
    required DateTime from,
    required DateTime to,
  }) => _delegate.fetchSalesAnalytics(from: from, to: to);

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
}
