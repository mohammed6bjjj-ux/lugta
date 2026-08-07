import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_app/core/widgets/price_summary_card.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/order_wizard/order_success_screen.dart';
import 'package:flutter_app/l10n/core_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'order success includes packaging in the customer total on a small phone',
    (tester) async {
      final previousLanguage = appSettings.language;
      appSettings.language = AppLanguage.en;
      addTearDown(() => appSettings.language = previousLanguage);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final createdAt = DateTime(2026, 8, 6, 12);
      final order = Order(
        id: 'order-with-packaging',
        code: 'ORD-PACKAGING',
        productId: 'product-1',
        productName: 'Test watch',
        productImage: '',
        items: const [
          OrderItem(
            productId: 'product-1',
            productName: 'Test watch',
            variantId: 'variant-1',
            variantName: 'Black',
            imageUrl: '',
            quantity: 2,
            wholesaleUnitPrice: 20000,
            saleUnitPrice: 30000,
            packagingBoxId: 'box-1',
            packagingName: 'Gift box',
            packagingUnitPrice: 2000,
          ),
        ],
        wholesalePrice: 20000,
        unitSalePrice: 30000,
        deliveryFee: 5000,
        packagingTotal: 4000,
        customerName: 'Test Customer',
        customerPhone: '07701234567',
        governorateName: 'Baghdad',
        regionName: '',
        addressDetails: 'Test address',
        status: OrderStatus.pendingReview,
        statusHistory: [
          OrderStatusEntry(status: OrderStatus.pendingReview, at: createdAt),
        ],
        createdAt: createdAt,
        storeNameSnapshot: 'Test Store',
        sellerPhoneSnapshot: '07700000000',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: OrderSuccessScreen(order: order),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 800));

      final summary = find.byType(PriceSummaryCard);
      expect(summary, findsOneWidget);
      expect(
        find.descendant(
          of: summary,
          matching: find.text(CoreStrings.packagingFeeOnCustomer),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summary,
          matching: find.text(formatIqd(order.packagingTotal)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summary,
          matching: find.text(CoreStrings.customerTotal),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summary,
          matching: find.text(formatIqd(order.customerTotal)),
        ),
        findsOneWidget,
      );
      expect(order.customerTotal, 69000);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
