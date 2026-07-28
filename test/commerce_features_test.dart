import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/models.dart';

void main() {
  test(
    'packaging is charged to the customer without changing seller profit',
    () {
      final createdAt = DateTime(2026, 7, 28, 12);
      final order = Order(
        id: 'order-1',
        code: 'ORD-TEST-1',
        productId: 'product-1',
        productName: 'ساعة تجريبية',
        productImage: '',
        items: const [
          OrderItem(
            variantId: 'variant-1',
            variantName: 'أسود',
            imageUrl: '',
            quantity: 2,
            wholesaleUnitPrice: 20000,
            saleUnitPrice: 30000,
            packagingBoxId: 'box-1',
            packagingName: 'علبة هدية',
            packagingUnitPrice: 2000,
          ),
        ],
        wholesalePrice: 20000,
        unitSalePrice: 30000,
        deliveryFee: 0,
        baseDeliveryFee: 5000,
        deliveryDiscount: 5000,
        freeDeliveryReason: 'ترحيب الحساب الجديد',
        packagingTotal: 4000,
        customerName: 'زبون تجريبي',
        customerPhone: '07800000000',
        governorateName: 'بغداد',
        regionName: '',
        addressDetails: 'عنوان تجريبي',
        status: OrderStatus.pendingReview,
        statusHistory: [
          OrderStatusEntry(status: OrderStatus.pendingReview, at: createdAt),
        ],
        createdAt: createdAt,
        storeNameSnapshot: 'متجر تجريبي',
        sellerPhoneSnapshot: '07811111111',
      );

      expect(order.totalQuantity, 2);
      expect(order.wholesaleTotal, 40000);
      expect(order.saleTotal, 60000);
      expect(order.profit, 20000);
      expect(order.customerTotal, 64000);
      expect(order.deliveryDiscount, 5000);
    },
  );
}
