import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/app_router.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/data/repositories/demo_repositories.dart';
import 'package:flutter_app/data/repositories/repositories.dart';
import 'package:flutter_app/data/services/device_token_registrar.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/orders/order_detail_screen.dart';
import 'package:flutter_app/features/profile/notifications_screen.dart';
import 'package:flutter_app/features/shell/main_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> configureApprovedDemoSession() async {
    final repositories = createDemoRepositories();
    await repositories.auth.signIn(
      phone: '07700000000',
      password: 'test-password',
    );
    await session.configure(repositories, loadInitialData: true);
  }

  testWidgets(
    'terminated push opens a loaded linked order after shell starts',
    (tester) async {
      await tester.runAsync(configureApprovedDemoSession);
      final order = session.orders.first;
      final deviceTokens = _FakeDeviceTokens(
        pending: [PushOpenEvent(orderId: order.id)],
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: MainShell(deviceTokens: deviceTokens),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await deviceTokens.dispose();
    },
  );

  testWidgets('unknown push target falls back to durable notifications', (
    tester,
  ) async {
    await tester.runAsync(configureApprovedDemoSession);
    final deviceTokens = _FakeDeviceTokens();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(deviceTokens: deviceTokens),
      ),
    );
    await tester.pump();
    deviceTokens.handleNotificationOpen(
      const PushOpenEvent(
        notificationId: 'notification-1',
        productId: 'not-loaded',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(NotificationsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await deviceTokens.dispose();
  });

  testWidgets('linked order is refreshed before its detail screen opens', (
    tester,
  ) async {
    final base = createDemoRepositories();
    await tester.runAsync(
      () => base.auth.signIn(phone: '07700000000', password: 'test-password'),
    );
    final cachedOrder = (await base.orders.fetchOrders()).first;
    final freshOrder = cachedOrder.copyWith(
      status: OrderStatus.completed,
      statusHistory: [
        ...cachedOrder.statusHistory,
        OrderStatusEntry(status: OrderStatus.completed, at: DateTime.utc(2026)),
      ],
    );
    final orders = _TargetedOrdersRepository(
      base.orders,
      targetedOrders: {cachedOrder.id: freshOrder},
    );
    await tester.runAsync(
      () =>
          session.configure(_repositories(base, orders), loadInitialData: true),
    );
    expect(session.orderById(cachedOrder.id)?.status, cachedOrder.status);

    final deviceTokens = _FakeDeviceTokens(
      pending: [PushOpenEvent(orderId: cachedOrder.id)],
    );
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(deviceTokens: deviceTokens),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final details = tester.widget<OrderDetailScreen>(
      find.byType(OrderDetailScreen),
    );
    expect(details.order.status, OrderStatus.completed);
    expect(session.orderById(cachedOrder.id)?.status, OrderStatus.completed);
    expect(orders.targetedFetches, [cachedOrder.id]);

    await tester.pumpWidget(const SizedBox());
    await deviceTokens.dispose();
  });

  testWidgets('rapid push taps coalesce to the newest target', (tester) async {
    final base = createDemoRepositories();
    await tester.runAsync(
      () => base.auth.signIn(phone: '07700000000', password: 'test-password'),
    );
    final availableOrders = await base.orders.fetchOrders();
    final first = availableOrders[0];
    final second = availableOrders[1];
    final orders = _TargetedOrdersRepository(base.orders);
    await tester.runAsync(
      () =>
          session.configure(_repositories(base, orders), loadInitialData: true),
    );
    orders.pauseNextTargetedFetch();
    final deviceTokens = _FakeDeviceTokens();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(deviceTokens: deviceTokens),
      ),
    );
    await tester.pump();

    deviceTokens.handleNotificationOpen(PushOpenEvent(orderId: first.id));
    await tester.pump();
    await tester.runAsync(() => orders.pausedTargetedFetchStarted.future);
    deviceTokens.handleNotificationOpen(PushOpenEvent(orderId: second.id));
    orders.releaseTargetedFetch();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    final details = tester.widget<OrderDetailScreen>(
      find.byType(OrderDetailScreen),
    );
    expect(details.order.id, second.id);
    expect(orders.targetedFetches, [first.id, second.id]);

    await tester.pumpWidget(const SizedBox());
    await deviceTokens.dispose();
  });
}

AppRepositories _repositories(AppRepositories base, OrdersRepository orders) =>
    AppRepositories(
      auth: base.auth,
      profile: base.profile,
      catalog: base.catalog,
      orders: orders,
      wallet: base.wallet,
      notifications: base.notifications,
      isDemo: true,
    );

class _TargetedOrdersRepository implements OrdersRepository {
  _TargetedOrdersRepository(this._delegate, {this.targetedOrders = const {}});

  final OrdersRepository _delegate;
  final Map<String, Order> targetedOrders;
  final List<String> targetedFetches = [];
  Completer<void>? _targetedRelease;
  bool _pauseNextTargeted = false;
  Completer<void> pausedTargetedFetchStarted = Completer<void>();

  void pauseNextTargetedFetch() {
    _pauseNextTargeted = true;
    _targetedRelease = Completer<void>();
    pausedTargetedFetchStarted = Completer<void>();
  }

  void releaseTargetedFetch() {
    final release = _targetedRelease;
    if (release != null && !release.isCompleted) release.complete();
  }

  @override
  Future<List<Order>> fetchOrders() => _delegate.fetchOrders();

  @override
  Future<Order> fetchOrder(String orderId) async {
    targetedFetches.add(orderId);
    if (_pauseNextTargeted) {
      _pauseNextTargeted = false;
      pausedTargetedFetchStarted.complete();
      await _targetedRelease!.future;
    }
    final targeted = targetedOrders[orderId];
    if (targeted != null) return targeted;
    return _delegate.fetchOrder(orderId);
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) =>
      _delegate.createOrder(request);

  @override
  Future<void> cancelOrder(String orderId, {required String clientRequestId}) =>
      _delegate.cancelOrder(orderId, clientRequestId: clientRequestId);

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

class _FakeDeviceTokens implements DeviceTokenRegistrar {
  _FakeDeviceTokens({List<PushOpenEvent> pending = const []})
    : _pending = List<PushOpenEvent>.of(pending);

  final StreamController<PushMessage> _foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushOpenEvent> _opens =
      StreamController<PushOpenEvent>.broadcast();
  final List<PushOpenEvent> _pending;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushOpenEvent> get notificationOpens => _opens.stream;

  @override
  void handleNotificationOpen(PushOpenEvent event) {
    if (_opens.hasListener) {
      _opens.add(event);
    } else {
      _pending.add(event);
    }
  }

  @override
  PushOpenEvent? takePendingNotificationOpen() =>
      _pending.isEmpty ? null : _pending.removeAt(0);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerCurrentDevice() async {}

  @override
  Future<void> unregisterCurrentDevice() async {}

  @override
  Future<void> dispose() async {
    await _foreground.close();
    await _opens.close();
  }
}
