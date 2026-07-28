import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/model_strings.dart';
import 'app_settings.dart';

/// حالة حساب البائع.
enum AccountStatus { pending, approved, rejected, blocked, deleted }

enum AccountDeletionStatus { pending, approved, rejected, cancelled }

class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.id,
    required this.status,
    required this.reason,
    required this.requestedAt,
    this.decisionReason,
    this.decidedAt,
    this.cancelledAt,
  });

  final String id;
  final AccountDeletionStatus status;
  final String reason;
  final String? decisionReason;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final DateTime? cancelledAt;
}

class Seller {
  const Seller({
    required this.id,
    required this.name,
    required this.phone,
    required this.storeName,
    required this.instagramUrl,
    required this.governorateId,
    required this.status,
    required this.joinedAt,
    this.statusReason,
    this.locale = 'ar',
    this.notificationPreferences = const {
      'orders': true,
      'wallet': true,
      'products': true,
      'system': true,
    },
  });

  final String id;
  final String name;
  final String phone;
  final String storeName;
  final String instagramUrl;
  final String governorateId;
  final AccountStatus status;
  final DateTime joinedAt;
  final String? statusReason;
  final String locale;
  final Map<String, bool> notificationPreferences;

  Seller copyWith({
    String? name,
    String? storeName,
    String? instagramUrl,
    String? locale,
    Map<String, bool>? notificationPreferences,
  }) => Seller(
    id: id,
    name: name ?? this.name,
    phone: phone,
    storeName: storeName ?? this.storeName,
    instagramUrl: instagramUrl ?? this.instagramUrl,
    governorateId: governorateId,
    status: status,
    joinedAt: joinedAt,
    statusReason: statusReason,
    locale: locale ?? this.locale,
    notificationPreferences:
        notificationPreferences ?? this.notificationPreferences,
  );
}

class Category {
  const Category({
    required this.id,
    required this.nameAr,
    required this.icon,
    required this.imageUrl,
    this.nameCkb,
    this.nameEn,
  });

  final String id;
  final String nameAr;
  final String? nameCkb;
  final String? nameEn;
  final IconData icon;
  final String imageUrl;

  String get localizedName => switch (appSettings.language) {
    AppLanguage.ckb => nameCkb?.trim().isNotEmpty == true ? nameCkb! : nameAr,
    AppLanguage.en => nameEn?.trim().isNotEmpty == true ? nameEn! : nameAr,
    AppLanguage.ar => nameAr,
  };
}

enum MediaType { image, video }

class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.url,
    String? thumbnailUrl,
    this.durationSec,
  }) : thumbnailUrl = thumbnailUrl ?? (type == MediaType.video ? '' : url);

  final String id;
  final MediaType type;
  final String url;
  final String thumbnailUrl;

  /// مدة الفيديو بالثواني (للفيديو فقط).
  final int? durationSec;

  bool get isVideo => type == MediaType.video;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.nameAr,
    required this.imageUrl,
    required this.stock,
    this.colorHex,
    this.nameCkb,
    this.nameEn,
    this.sku,
    this.wholesalePriceOverride,
    this.suggestedPriceOverride,
  });

  final String id;

  /// اسم المتغير: لون أو موديل (أسود، ذهبي، عدسة زرقاء...).
  final String nameAr;
  final String? nameCkb;
  final String? nameEn;
  final String? sku;
  final int? wholesalePriceOverride;
  final int? suggestedPriceOverride;
  final String imageUrl;
  final int stock;

  /// لون تمثيلي اختياري لعرض دائرة اللون.
  final int? colorHex;

  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 3;

  String get localizedName => switch (appSettings.language) {
    AppLanguage.ckb => nameCkb?.trim().isNotEmpty == true ? nameCkb! : nameAr,
    AppLanguage.en => nameEn?.trim().isNotEmpty == true ? nameEn! : nameAr,
    AppLanguage.ar => nameAr,
  };
}

class Product {
  const Product({
    required this.id,
    required this.nameAr,
    required this.categoryId,
    required this.description,
    required this.specs,
    required this.media,
    required this.variants,
    required this.wholesalePrice,
    required this.suggestedPrice,
    required this.createdAt,
    this.oldWholesalePrice,
    this.minSalePrice,
    this.maxSalePrice,
    this.ordersCount = 0,
    this.isNew = false,
    this.nameCkb,
    this.nameEn,
    this.descriptionCkb,
    this.descriptionEn,
  });

  final String id;
  final String nameAr;
  final String? nameCkb;
  final String? nameEn;
  final String categoryId;
  final String description;
  final String? descriptionCkb;
  final String? descriptionEn;

  /// المواصفات: {العنوان: القيمة}
  final Map<String, String> specs;
  final List<MediaItem> media;
  final List<ProductVariant> variants;

  /// سعر الجملة للقطعة الواحدة (دينار عراقي).
  final int wholesalePrice;

  /// سعر الجملة قبل التخفيض — وجوده يعني أن المنتج ضمن «التخفيضات».
  final int? oldWholesalePrice;

  /// السعر المقترح للبيع (دينار عراقي).
  final int suggestedPrice;

  /// حد أدنى/أقصى اختياري لسعر البيع تحدده الإدارة (قد يكونان null).
  final int? minSalePrice;
  final int? maxSalePrice;

  final int ordersCount;
  final bool isNew;
  final DateTime createdAt;

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);
  bool get inStock => totalStock > 0;
  bool get lowStock => inStock && totalStock <= 5;

  /// هل على المنتج تخفيض فعلي على سعر الجملة؟
  bool get hasDiscount =>
      oldWholesalePrice != null && oldWholesalePrice! > wholesalePrice;

  /// نسبة التخفيض المقربة (0 إن لم يوجد تخفيض).
  int get discountPercent => hasDiscount
      ? (((oldWholesalePrice! - wholesalePrice) * 100) / oldWholesalePrice!)
            .round()
      : 0;

  String get coverImage {
    for (final item in media) {
      if (!item.isVideo && item.url.trim().isNotEmpty) {
        return item.thumbnailUrl.trim().isNotEmpty
            ? item.thumbnailUrl
            : item.url;
      }
    }
    for (final item in media) {
      if (item.isVideo && item.thumbnailUrl.trim().isNotEmpty) {
        return item.thumbnailUrl;
      }
    }
    return '';
  }

  /// الحد الأدنى الفعلي المسموح لسعر البيع.
  int get effectiveMinSalePrice => minSalePrice ?? wholesalePrice;

  String get localizedName => switch (appSettings.language) {
    AppLanguage.ckb => nameCkb?.trim().isNotEmpty == true ? nameCkb! : nameAr,
    AppLanguage.en => nameEn?.trim().isNotEmpty == true ? nameEn! : nameAr,
    AppLanguage.ar => nameAr,
  };

  String get localizedDescription => switch (appSettings.language) {
    AppLanguage.ckb =>
      descriptionCkb?.trim().isNotEmpty == true ? descriptionCkb! : description,
    AppLanguage.en =>
      descriptionEn?.trim().isNotEmpty == true ? descriptionEn! : description,
    AppLanguage.ar => description,
  };
}

class Governorate {
  const Governorate({
    required this.id,
    required this.nameAr,
    required this.deliveryFee,
    this.nameCkb,
    this.nameEn,
  });

  final String id;
  final String nameAr;
  final String? nameCkb;
  final String? nameEn;

  /// أجرة التوصيل الافتراضية للمحافظة (دينار عراقي).
  final int deliveryFee;

  String get localizedName => switch (appSettings.language) {
    AppLanguage.ckb => nameCkb?.trim().isNotEmpty == true ? nameCkb! : nameAr,
    AppLanguage.en => nameEn?.trim().isNotEmpty == true ? nameEn! : nameAr,
    AppLanguage.ar => nameAr,
  };
}

/// آلة حالات الطلب الموحّدة (10 حالات).
enum OrderStatus {
  pendingReview,
  confirmed,
  shipped,
  delivered,
  completed,
  deliveryFailed,
  returning,
  returned,
  rejected,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  /// التسمية بلغة التطبيق الحالية (الاسم تاريخي من مرحلة العربية فقط).
  String get labelAr => ModelStrings.orderStatus(this);

  Color get color => switch (this) {
    OrderStatus.pendingReview => AppColors.goldDark,
    OrderStatus.confirmed => AppColors.info,
    OrderStatus.shipped => AppColors.goldDark,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.completed => AppColors.success,
    OrderStatus.deliveryFailed => AppColors.error,
    OrderStatus.returning => AppColors.textSecondary,
    OrderStatus.returned => AppColors.error,
    OrderStatus.rejected => AppColors.error,
    OrderStatus.cancelled => AppColors.textSecondary,
  };

  Color get softColor => switch (this) {
    OrderStatus.pendingReview => AppColors.goldSoft,
    OrderStatus.confirmed => AppColors.infoSoft,
    OrderStatus.shipped => AppColors.goldSoft,
    OrderStatus.delivered => AppColors.successSoft,
    OrderStatus.completed => AppColors.successSoft,
    OrderStatus.deliveryFailed => AppColors.errorSoft,
    OrderStatus.returning => AppColors.neutralChip,
    OrderStatus.returned => AppColors.errorSoft,
    OrderStatus.rejected => AppColors.errorSoft,
    OrderStatus.cancelled => AppColors.neutralChip,
  };

  IconData get icon => switch (this) {
    OrderStatus.pendingReview => Icons.hourglass_top_rounded,
    OrderStatus.confirmed => Icons.inventory_2_outlined,
    OrderStatus.shipped => Icons.local_shipping_outlined,
    OrderStatus.delivered => Icons.check_circle_outline_rounded,
    OrderStatus.completed => Icons.verified_rounded,
    OrderStatus.deliveryFailed => Icons.error_outline_rounded,
    OrderStatus.returning => Icons.keyboard_return_rounded,
    OrderStatus.returned => Icons.assignment_return_outlined,
    OrderStatus.rejected => Icons.block_rounded,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };

  /// حالة نهائية لا انتقال بعدها.
  bool get isTerminal => switch (this) {
    OrderStatus.completed ||
    OrderStatus.returned ||
    OrderStatus.rejected ||
    OrderStatus.cancelled => true,
    _ => false,
  };

  /// الحالات التي يكون ربحها معلقاً في المحفظة.
  bool get holdsPendingProfit => switch (this) {
    OrderStatus.confirmed ||
    OrderStatus.shipped ||
    OrderStatus.delivered => true,
    _ => false,
  };

  /// هل يستطيع البائع الإلغاء المباشر؟ (قيد المراجعة فقط —
  /// بعدها يتحول الطلب إلى «طلب إلغاء» تراجعه الإدارة).
  bool get sellerCanCancelDirectly => this == OrderStatus.pendingReview;

  /// هل يمكن تقديم طلب تعديل/إلغاء للإدارة؟ (قبل الشحن).
  bool get canRequestChange =>
      this == OrderStatus.pendingReview || this == OrderStatus.confirmed;
}

class OrderStatusEntry {
  const OrderStatusEntry({required this.status, required this.at, this.note});

  final OrderStatus status;
  final DateTime at;
  final String? note;
}

/// سطر داخل الطلب: متغير محدد بكمية.
class OrderItem {
  const OrderItem({
    required this.variantId,
    required this.variantName,
    required this.imageUrl,
    required this.quantity,
    this.wholesaleUnitPrice,
    this.saleUnitPrice,
  });

  final String variantId;
  final String variantName;
  final String imageUrl;
  final int quantity;
  final int? wholesaleUnitPrice;
  final int? saleUnitPrice;
}

class Order {
  const Order({
    required this.id,
    required this.code,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.items,
    required this.wholesalePrice,
    required this.unitSalePrice,
    required this.deliveryFee,
    required this.customerName,
    required this.customerPhone,
    required this.governorateName,
    required this.regionName,
    required this.addressDetails,
    required this.status,
    required this.statusHistory,
    required this.createdAt,
    required this.storeNameSnapshot,
    required this.sellerPhoneSnapshot,
    this.customerPhone2,
    this.landmark,
    this.notes,
    this.failReason,
    this.deliveryCompany,
    this.trackingNumber,
  });

  final String id;

  /// رقم مقروء مثل ORD-1042.
  final String code;

  final String productId;
  final String productName;
  final String productImage;
  final List<OrderItem> items;

  // ── اللقطة السعرية الثابتة (لا تتغير حتى لو تغير سعر المنتج لاحقاً) ──
  /// سعر الجملة للقطعة وقت إنشاء الطلب.
  final int wholesalePrice;

  /// سعر البيع للقطعة الذي حدده البائع.
  final int unitSalePrice;

  /// أجرة التوصيل وقت إنشاء الطلب.
  final int deliveryFee;

  // ── لقطة إخفاء المورد: تُطبع على بوليصة الشحن باسم متجر البائع ──
  final String storeNameSnapshot;
  final String sellerPhoneSnapshot;

  final String customerName;
  final String customerPhone;
  final String? customerPhone2;
  final String governorateName;
  final String regionName;
  final String addressDetails;
  final String? landmark;
  final String? notes;
  final String? deliveryCompany;
  final String? trackingNumber;

  final OrderStatus status;
  final List<OrderStatusEntry> statusHistory;
  final String? failReason;
  final DateTime createdAt;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  int get wholesaleTotal => items.any((item) => item.wholesaleUnitPrice != null)
      ? items.fold(
          0,
          (sum, item) =>
              sum + (item.wholesaleUnitPrice ?? wholesalePrice) * item.quantity,
        )
      : wholesalePrice * totalQuantity;
  int get saleTotal => items.any((item) => item.saleUnitPrice != null)
      ? items.fold(
          0,
          (sum, item) =>
              sum + (item.saleUnitPrice ?? unitSalePrice) * item.quantity,
        )
      : unitSalePrice * totalQuantity;

  /// ربح البائع = (سعر البيع − سعر الجملة) × الكمية.
  int get profit => saleTotal - wholesaleTotal;

  /// المبلغ النهائي على الزبون = إجمالي البيع + أجرة التوصيل.
  int get customerTotal => saleTotal + deliveryFee;

  /// يحق للبائع الإلغاء المباشر خلال الساعة الأولى فقط، وبعدها يرسل
  /// طلب إلغاء تراجعه الإدارة ما دام الطلب لم يُشحن.
  bool get sellerCanCancelDirectly =>
      status == OrderStatus.pendingReview &&
      !DateTime.now().isAfter(createdAt.add(const Duration(hours: 1)));

  bool get sellerCanRequestChange =>
      status == OrderStatus.confirmed ||
      (status == OrderStatus.pendingReview && !sellerCanCancelDirectly);

  Order copyWith({
    OrderStatus? status,
    List<OrderStatusEntry>? statusHistory,
    String? failReason,
  }) => Order(
    id: id,
    code: code,
    productId: productId,
    productName: productName,
    productImage: productImage,
    items: items,
    wholesalePrice: wholesalePrice,
    unitSalePrice: unitSalePrice,
    deliveryFee: deliveryFee,
    customerName: customerName,
    customerPhone: customerPhone,
    customerPhone2: customerPhone2,
    governorateName: governorateName,
    regionName: regionName,
    addressDetails: addressDetails,
    landmark: landmark,
    notes: notes,
    deliveryCompany: deliveryCompany,
    trackingNumber: trackingNumber,
    status: status ?? this.status,
    statusHistory: statusHistory ?? this.statusHistory,
    failReason: failReason ?? this.failReason,
    createdAt: createdAt,
    storeNameSnapshot: storeNameSnapshot,
    sellerPhoneSnapshot: sellerPhoneSnapshot,
  );
}

/// نوع حركة المحفظة.
enum WalletTxType {
  /// ربح معلق أُضيف عند تأكيد الطلب.
  pendingProfit,

  /// تحول الربح من معلق إلى متاح بعد نجاح التوصيل والتسوية.
  profitReleased,

  /// عكس ربح معلق بسبب فشل/إرجاع الطلب.
  reversal,

  /// سحب من الرصيد المتاح.
  withdrawal,

  /// إعادة مبلغ سحب ملغى/مرفوض إلى الرصيد المتاح.
  withdrawalRefund,

  /// تسوية إدارية موجبة أو سالبة موثقة في دفتر المحفظة.
  adjustmentCredit,
  adjustmentDebit,
}

extension WalletTxTypeX on WalletTxType {
  /// التسمية بلغة التطبيق الحالية (الاسم تاريخي من مرحلة العربية فقط).
  String get labelAr => ModelStrings.walletTxType(this);

  Color get color => switch (this) {
    WalletTxType.pendingProfit => AppColors.goldDark,
    WalletTxType.profitReleased => AppColors.success,
    WalletTxType.reversal => AppColors.error,
    WalletTxType.withdrawal => AppColors.info,
    WalletTxType.withdrawalRefund => AppColors.success,
    WalletTxType.adjustmentCredit => AppColors.success,
    WalletTxType.adjustmentDebit => AppColors.error,
  };

  IconData get icon => switch (this) {
    WalletTxType.pendingProfit => Icons.schedule_rounded,
    WalletTxType.profitReleased => Icons.trending_up_rounded,
    WalletTxType.reversal => Icons.undo_rounded,
    WalletTxType.withdrawal => Icons.account_balance_wallet_outlined,
    WalletTxType.withdrawalRefund => Icons.settings_backup_restore_rounded,
    WalletTxType.adjustmentCredit => Icons.add_card_rounded,
    WalletTxType.adjustmentDebit => Icons.money_off_csred_outlined,
  };
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.at,
    this.orderCode,
    this.note,
  });

  final String id;
  final WalletTxType type;

  /// المبلغ موجب دائماً؛ الاتجاه يُفهم من النوع.
  final int amount;
  final DateTime at;
  final String? orderCode;
  final String? note;
}

enum WithdrawalStatus { pending, approved, paid, rejected, cancelled }

extension WithdrawalStatusX on WithdrawalStatus {
  /// التسمية بلغة التطبيق الحالية (الاسم تاريخي من مرحلة العربية فقط).
  String get labelAr => ModelStrings.withdrawalStatus(this);

  Color get color => switch (this) {
    WithdrawalStatus.pending => AppColors.textSecondary,
    WithdrawalStatus.approved => AppColors.info,
    WithdrawalStatus.paid => AppColors.success,
    WithdrawalStatus.rejected => AppColors.error,
    WithdrawalStatus.cancelled => AppColors.textSecondary,
  };
}

class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.amount,
    required this.method,
    required this.accountDetail,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.rejectReason,
    this.transferFee = 0,
  });

  final String id;
  final int amount;

  /// طريقة الدفع: زين كاش... (Placeholder — بانتظار حسم طرق الدفع).
  final String method;
  final String accountDetail;
  final int transferFee;
  int get netAmount => amount - transferFee;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? rejectReason;
}

class PayoutAccount {
  const PayoutAccount({
    required this.id,
    required this.provider,
    required this.accountHolderName,
    required this.accountIdentifier,
    required this.identifierLast4,
    required this.isVerified,
    required this.isDefault,
  });

  final String id;
  final String provider;
  final String accountHolderName;
  final String accountIdentifier;
  final String identifierLast4;
  final bool isVerified;
  final bool isDefault;

  String get providerLabel => switch (provider) {
    'zain_cash' => 'زين كاش',
    'superqi' => 'سوبر كي',
    'mastercard' => 'ماستر كارد',
    _ => provider,
  };
}

/// Immutable order-line snapshot exposed by `seller_account_statement`.
class AccountStatementLine {
  const AccountStatementLine({
    required this.orderItemId,
    required this.orderId,
    required this.orderCode,
    required this.orderStatus,
    required this.orderCreatedAt,
    required this.productNameAr,
    required this.variantNameAr,
    required this.quantity,
    required this.unitWholesalePrice,
    required this.unitSalePrice,
    required this.unitProfit,
    required this.lineWholesaleTotal,
    required this.lineSaleTotal,
    required this.lineProfitTotal,
    this.productNameCkb,
    this.productNameEn,
    this.variantNameCkb,
    this.variantNameEn,
    this.sku,
    this.completedAt,
  });

  final String orderItemId;
  final String orderId;
  final String orderCode;
  final OrderStatus orderStatus;
  final DateTime orderCreatedAt;
  final DateTime? completedAt;
  final String productNameAr;
  final String? productNameCkb;
  final String? productNameEn;
  final String variantNameAr;
  final String? variantNameCkb;
  final String? variantNameEn;
  final String? sku;
  final int quantity;
  final int unitWholesalePrice;
  final int unitSalePrice;
  final int unitProfit;
  final int lineWholesaleTotal;
  final int lineSaleTotal;
  final int lineProfitTotal;

  String get localizedProductName => switch (appSettings.language) {
    AppLanguage.ckb =>
      productNameCkb?.trim().isNotEmpty == true
          ? productNameCkb!
          : productNameAr,
    AppLanguage.en =>
      productNameEn?.trim().isNotEmpty == true ? productNameEn! : productNameAr,
    AppLanguage.ar => productNameAr,
  };

  String get localizedVariantName => switch (appSettings.language) {
    AppLanguage.ckb =>
      variantNameCkb?.trim().isNotEmpty == true
          ? variantNameCkb!
          : variantNameAr,
    AppLanguage.en =>
      variantNameEn?.trim().isNotEmpty == true ? variantNameEn! : variantNameAr,
    AppLanguage.ar => variantNameAr,
  };
}

/// Exact order/item allocation backing a withdrawal hold.
class WithdrawalSourceLine {
  const WithdrawalSourceLine({
    required this.withdrawalId,
    required this.sourceEntryId,
    required this.allocatedAmount,
    required this.orderId,
    required this.orderCode,
    required this.productNameAr,
    required this.variantNameAr,
    required this.quantity,
    required this.unitWholesalePrice,
    required this.unitSalePrice,
    required this.lineProfitTotal,
    required this.createdAt,
    this.productNameCkb,
    this.productNameEn,
    this.variantNameCkb,
    this.variantNameEn,
  });

  final String withdrawalId;
  final String sourceEntryId;
  final int allocatedAmount;
  final String orderId;
  final String orderCode;
  final String productNameAr;
  final String? productNameCkb;
  final String? productNameEn;
  final String variantNameAr;
  final String? variantNameCkb;
  final String? variantNameEn;
  final int quantity;
  final int unitWholesalePrice;
  final int unitSalePrice;
  final int lineProfitTotal;
  final DateTime createdAt;

  String get localizedProductName => switch (appSettings.language) {
    AppLanguage.ckb =>
      productNameCkb?.trim().isNotEmpty == true
          ? productNameCkb!
          : productNameAr,
    AppLanguage.en =>
      productNameEn?.trim().isNotEmpty == true ? productNameEn! : productNameAr,
    AppLanguage.ar => productNameAr,
  };

  String get localizedVariantName => switch (appSettings.language) {
    AppLanguage.ckb =>
      variantNameCkb?.trim().isNotEmpty == true
          ? variantNameCkb!
          : variantNameAr,
    AppLanguage.en =>
      variantNameEn?.trim().isNotEmpty == true ? variantNameEn! : variantNameAr,
    AppLanguage.ar => variantNameAr,
  };
}

enum NotificationType { order, wallet, product, system }

extension NotificationTypeX on NotificationType {
  IconData get icon => switch (this) {
    NotificationType.order => Icons.receipt_long_outlined,
    NotificationType.wallet => Icons.account_balance_wallet_outlined,
    NotificationType.product => Icons.watch_outlined,
    NotificationType.system => Icons.campaign_outlined,
  };

  Color get color => switch (this) {
    NotificationType.order => AppColors.info,
    NotificationType.wallet => AppColors.success,
    NotificationType.product => AppColors.goldDark,
    NotificationType.system => AppColors.warning,
  };
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.at,
    this.isRead = false,
    this.targetOrderId,
    this.targetProductId,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime at;
  bool isRead;
  final String? targetOrderId;
  final String? targetProductId;
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.targetProductId,
    this.targetCategoryId,
    this.titleCkb,
    this.titleEn,
    this.subtitleCkb,
    this.subtitleEn,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? titleCkb;
  final String? titleEn;
  final String? subtitleCkb;
  final String? subtitleEn;
  final String? targetProductId;
  final String? targetCategoryId;

  String get localizedTitle => switch (appSettings.language) {
    AppLanguage.ckb => titleCkb?.trim().isNotEmpty == true ? titleCkb! : title,
    AppLanguage.en => titleEn?.trim().isNotEmpty == true ? titleEn! : title,
    AppLanguage.ar => title,
  };

  String? get localizedSubtitle => switch (appSettings.language) {
    AppLanguage.ckb =>
      subtitleCkb?.trim().isNotEmpty == true ? subtitleCkb : subtitle,
    AppLanguage.en =>
      subtitleEn?.trim().isNotEmpty == true ? subtitleEn : subtitle,
    AppLanguage.ar => subtitle,
  };
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// عنصر مسودة داخل معالج إنشاء الطلب: متغير + كمية.
class OrderDraftItem {
  OrderDraftItem({required this.variant, this.quantity = 1});

  final ProductVariant variant;
  int quantity;
}
