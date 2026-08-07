import '../models.dart';

enum OtpPurpose { registration, passwordRecovery, phoneChange }

enum OrderChangeRequestType { edit, cancel }

class RegistrationRequest {
  const RegistrationRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.storeName,
    required this.governorateId,
    required this.termsVersion,
    this.instagramUrl,
    this.referralCode,
  });

  final String fullName;
  final String phone;
  final String password;
  final String storeName;
  final String governorateId;
  final String termsVersion;
  final String? instagramUrl;
  final String? referralCode;
}

class CreateOrderRequest {
  CreateOrderRequest({
    required this.clientRequestId,
    required this.product,
    required this.items,
    required this.unitSalePrice,
    required this.governorate,
    required this.customerName,
    required this.customerPhone,
    required this.addressDetails,
    this.customerPhone2,
    this.notes,
    this.packagingBox,
  }) : lines = List<CreateOrderLine>.unmodifiable([
         for (final item in items)
           CreateOrderLine(
             product: product,
             variant: item.variant,
             quantity: item.quantity,
             unitSalePrice: unitSalePrice,
             packagingBox: packagingBox,
           ),
       ]);

  CreateOrderRequest.lines({
    required this.clientRequestId,
    required List<CreateOrderLine> lines,
    required this.governorate,
    required this.customerName,
    required this.customerPhone,
    required this.addressDetails,
    this.customerPhone2,
    this.notes,
  }) : assert(lines.isNotEmpty),
       lines = List<CreateOrderLine>.unmodifiable(lines),
       product = lines.first.product,
       items = List<OrderDraftItem>.unmodifiable([
         for (final line in lines)
           OrderDraftItem(variant: line.variant, quantity: line.quantity),
       ]),
       unitSalePrice = lines.first.unitSalePrice,
       packagingBox = lines.first.packagingBox;

  final String clientRequestId;
  final Product product;
  final List<OrderDraftItem> items;
  final int unitSalePrice;
  final Governorate governorate;
  final String customerName;
  final String customerPhone;
  final String? customerPhone2;
  final String addressDetails;
  final String? notes;
  final PackagingBox? packagingBox;
  final List<CreateOrderLine> lines;
}

/// عقد سطر مستقل عند إرسال طلب متعدد المنتجات إلى الخادم.
class CreateOrderLine {
  const CreateOrderLine({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.unitSalePrice,
    this.packagingBox,
  });

  factory CreateOrderLine.fromCartItem(CartItem item) => CreateOrderLine(
    product: item.product,
    variant: item.variant,
    quantity: item.quantity,
    unitSalePrice: item.unitSalePrice,
    packagingBox: item.packagingBox,
  );

  final Product product;
  final ProductVariant variant;
  final int quantity;
  final int unitSalePrice;
  final PackagingBox? packagingBox;
}

class CreateWithdrawalRequest {
  const CreateWithdrawalRequest({
    required this.clientRequestId,
    required this.amount,
    required this.method,
    required this.accountDetail,
    this.payoutAccountId,
  });

  final String clientRequestId;
  final int amount;
  final String method;
  final String accountDetail;
  final String? payoutAccountId;
}

class SavePayoutAccountRequest {
  const SavePayoutAccountRequest({
    required this.provider,
    required this.accountHolderName,
    required this.accountIdentifier,
    this.accountId,
    this.makeDefault = false,
  });

  final String? accountId;
  final String provider;
  final String accountHolderName;
  final String accountIdentifier;
  final bool makeDefault;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.available,
    required this.pending,
    required this.totalEarned,
    required this.minimumWithdrawal,
    required this.transactions,
    required this.withdrawals,
    required this.payoutAccounts,
    required this.statementLines,
    required this.withdrawalSources,
    this.withdrawalFees = const <String, int>{},
  });

  final int available;
  final int pending;
  final int totalEarned;
  final int minimumWithdrawal;
  final List<WalletTransaction> transactions;
  final List<Withdrawal> withdrawals;
  final List<PayoutAccount> payoutAccounts;
  final List<AccountStatementLine> statementLines;
  final List<WithdrawalSourceLine> withdrawalSources;
  final Map<String, int> withdrawalFees;
}

class PublicContentSnapshot {
  const PublicContentSnapshot({
    required this.banners,
    required this.faq,
    required this.policiesText,
    required this.supportPhone,
    required this.supportWhatsapp,
    required this.termsVersion,
  });

  final List<PromoBanner> banners;
  final List<FaqItem> faq;
  final String policiesText;
  final String supportPhone;
  final String supportWhatsapp;
  final String termsVersion;
}

abstract interface class AuthRepository {
  bool get hasSession;
  String? get currentUserId;

  /// Emits the authenticated user id whenever the local Auth session changes.
  /// A `null` value means that no authenticated session remains on the device.
  Stream<String?> get userIdChanges;

  Future<void> signIn({required String phone, required String password});
  Future<void> signUp(RegistrationRequest request);

  /// Completes an OTP-confirmed seller registration when a matching local
  /// registration draft exists for the current authenticated phone number.
  Future<bool> completePendingRegistration();
  Future<void> verifyOtp({
    required String phone,
    required String token,
    required OtpPurpose purpose,
  });
  Future<void> resendOtp({required String phone, required OtpPurpose purpose});
  Future<void> sendPasswordRecoveryOtp(String phone);
  Future<void> updatePassword(String newPassword);

  /// Removes a password-recovery-only Auth session, if one is durably marked.
  /// Normal signed-in sessions are left untouched when no recovery gate exists.
  Future<void> abandonPasswordRecovery();
  Future<void> signOut();
}

abstract interface class ProfileRepository {
  Future<Seller> fetchCurrentProfile();
  Future<Seller> updateCurrentProfile({
    required String name,
    required String storeName,
    required String instagramUrl,
  });
  Future<Seller> updateSettings({
    required String locale,
    required Map<String, bool> notificationPreferences,
  });
  Future<AccountDeletionRequest?> fetchLatestAccountDeletionRequest();
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String reason,
    required String clientRequestId,
  });
  Future<AccountDeletionRequest> cancelAccountDeletion({
    required String requestId,
    required String clientRequestId,
  });
  Future<void> touchLastActive();
}

abstract interface class CatalogRepository {
  Future<List<Category>> fetchCategories();
  Future<List<Product>> fetchProducts();
  Future<Product> fetchProduct(String productId);
  Stream<void> watchCatalogChanges();
  Future<List<Governorate>> fetchDeliveryZones();
  Future<List<PackagingBox>> fetchPackagingBoxes();
  Future<DeliveryQuote> quoteDeliveryFee(String deliveryZoneId);
  Future<PublicContentSnapshot> fetchPublicContent();
  Future<Set<String>> fetchFavoriteProductIds();
  Future<Set<String>> fetchStockAlertProductIds();
  Future<void> setFavorite(String productId, {required bool enabled});
  Future<void> setStockAlert(String productId, {required bool enabled});
}

abstract interface class OrdersRepository {
  Future<List<Order>> fetchOrders();
  Future<Order> fetchOrder(String orderId);
  Future<Order> createOrder(CreateOrderRequest request);
  Future<void> cancelOrder(String orderId, {required String clientRequestId});
  Future<void> submitChangeRequest({
    required String orderId,
    required OrderChangeRequestType type,
    required String reason,
    required Map<String, dynamic> proposedChanges,
    required String clientRequestId,
  });
  Future<OrderComplaint> createComplaint({
    required String orderId,
    required OrderComplaintKind kind,
    required String subject,
    required String message,
    required String clientRequestId,
  });
}

abstract interface class WalletRepository {
  Future<WalletSnapshot> fetchWallet();
  Stream<void> watchWalletChanges();
  Future<List<PayoutAccount>> fetchPayoutAccounts();
  Future<PayoutAccount> upsertPayoutAccount(SavePayoutAccountRequest request);
  Future<void> deletePayoutAccount(String accountId);
  Future<Withdrawal> requestWithdrawal(CreateWithdrawalRequest request);
  Future<Withdrawal> cancelWithdrawal(
    String withdrawalId, {
    required String clientRequestId,
  });
}

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
  Future<void> markPopupSeen(String notificationId);
  Stream<List<AppNotification>> watchNotifications();
}

abstract interface class PromotionsRepository {
  Future<List<PromotionGrant>> fetchPromotionGrants();
  Future<ReferralSummary> fetchReferralSummary();
  Stream<void> watchPromotionGrantChanges();
}

class EmptyPromotionsRepository implements PromotionsRepository {
  const EmptyPromotionsRepository();

  @override
  Future<List<PromotionGrant>> fetchPromotionGrants() async => const [];

  @override
  Future<ReferralSummary> fetchReferralSummary() async =>
      const ReferralSummary.empty();

  @override
  Stream<void> watchPromotionGrantChanges() => const Stream.empty();
}

class AppRepositories {
  const AppRepositories({
    required this.auth,
    required this.profile,
    required this.catalog,
    required this.orders,
    required this.wallet,
    required this.notifications,
    this.promotions = const EmptyPromotionsRepository(),
    required this.isDemo,
  });

  final AuthRepository auth;
  final ProfileRepository profile;
  final CatalogRepository catalog;
  final OrdersRepository orders;
  final WalletRepository wallet;
  final NotificationsRepository notifications;
  final PromotionsRepository promotions;
  final bool isDemo;
}

class BackendException implements Exception {
  const BackendException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}
