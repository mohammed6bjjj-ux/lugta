import '../data/app_settings.dart';
import '../data/models.dart';

/// تسميات حالات النماذج بثلاث لغات (عربي، كوردي سوراني، إنجليزي).
/// تُستدعى من extensions النماذج — الواجهات لا تستوردها مباشرة.
class ModelStrings {
  ModelStrings._();

  static String orderStatus(OrderStatus s) => switch (appSettings.language) {
    AppLanguage.ar => switch (s) {
      OrderStatus.pendingReview => 'قيد المراجعة',
      OrderStatus.confirmed => 'مؤكد — قيد التجهيز',
      OrderStatus.shipped => 'مع شركة التوصيل',
      OrderStatus.delivered => 'تم التسليم',
      OrderStatus.completed => 'مكتمل',
      OrderStatus.deliveryFailed => 'فشل التوصيل',
      OrderStatus.returning => 'بطريق الإرجاع',
      OrderStatus.returned => 'مرتجع',
      OrderStatus.rejected => 'مرفوض',
      OrderStatus.cancelled => 'ملغي',
    },
    AppLanguage.ckb => switch (s) {
      OrderStatus.pendingReview => 'لە چاوەڕوانی پێداچوونەوەدایە',
      OrderStatus.confirmed => 'پەسەندکرا — ئامادە دەکرێت',
      OrderStatus.shipped => 'لەگەڵ کۆمپانیای گەیاندن',
      OrderStatus.delivered => 'گەیەنرا',
      OrderStatus.completed => 'تەواوبوو',
      OrderStatus.deliveryFailed => 'گەیاندن سەرنەکەوت',
      OrderStatus.returning => 'لە ڕێی گەڕانەوەدایە',
      OrderStatus.returned => 'گەڕێنرایەوە',
      OrderStatus.rejected => 'ڕەتکرایەوە',
      OrderStatus.cancelled => 'هەڵوەشێنرایەوە',
    },
    AppLanguage.en => switch (s) {
      OrderStatus.pendingReview => 'Under review',
      OrderStatus.confirmed => 'Confirmed — preparing',
      OrderStatus.shipped => 'With delivery company',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.completed => 'Completed',
      OrderStatus.deliveryFailed => 'Delivery failed',
      OrderStatus.returning => 'Being returned',
      OrderStatus.returned => 'Returned',
      OrderStatus.rejected => 'Rejected',
      OrderStatus.cancelled => 'Cancelled',
    },
  };

  static String walletTxType(WalletTxType t) => switch (appSettings.language) {
    AppLanguage.ar => switch (t) {
      WalletTxType.pendingProfit => 'ربح معلق',
      WalletTxType.profitReleased => 'ربح متاح',
      WalletTxType.reversal => 'عكس ربح (طلب راجع)',
      WalletTxType.withdrawal => 'سحب رصيد',
      WalletTxType.withdrawalRefund => 'إعادة مبلغ سحب',
      WalletTxType.adjustmentCredit => 'تسوية إدارية دائنة',
      WalletTxType.adjustmentDebit => 'تسوية إدارية مدينة',
    },
    AppLanguage.ckb => switch (t) {
      WalletTxType.pendingProfit => 'قازانجی هەڵواسراو',
      WalletTxType.profitReleased => 'قازانجی بەردەست',
      WalletTxType.reversal => 'گەڕاندنەوەی قازانج (داواکاری گەڕاوە)',
      WalletTxType.withdrawal => 'ڕاکێشانی باڵانس',
      WalletTxType.withdrawalRefund => 'گەڕاندنەوەی بڕی ڕاکێشان',
      WalletTxType.adjustmentCredit => 'ڕێکخستنی ئیداری زیادکراو',
      WalletTxType.adjustmentDebit => 'ڕێکخستنی ئیداری کەمکراو',
    },
    AppLanguage.en => switch (t) {
      WalletTxType.pendingProfit => 'Pending profit',
      WalletTxType.profitReleased => 'Available profit',
      WalletTxType.reversal => 'Profit reversal (returned order)',
      WalletTxType.withdrawal => 'Balance withdrawal',
      WalletTxType.withdrawalRefund => 'Withdrawal refund',
      WalletTxType.adjustmentCredit => 'Administrative credit',
      WalletTxType.adjustmentDebit => 'Administrative debit',
    },
  };

  static String withdrawalStatus(WithdrawalStatus s) =>
      switch (appSettings.language) {
        AppLanguage.ar => switch (s) {
          WithdrawalStatus.pending => 'قيد المراجعة',
          WithdrawalStatus.approved => 'موافَق عليه',
          WithdrawalStatus.paid => 'مدفوع',
          WithdrawalStatus.rejected => 'مرفوض',
          WithdrawalStatus.cancelled => 'ملغي',
        },
        AppLanguage.ckb => switch (s) {
          WithdrawalStatus.pending => 'لە چاوەڕوانیدایە',
          WithdrawalStatus.approved => 'پەسەندکرا',
          WithdrawalStatus.paid => 'پارە دراوە',
          WithdrawalStatus.rejected => 'ڕەتکرایەوە',
          WithdrawalStatus.cancelled => 'هەڵوەشێنراوەتەوە',
        },
        AppLanguage.en => switch (s) {
          WithdrawalStatus.pending => 'Pending',
          WithdrawalStatus.approved => 'Approved',
          WithdrawalStatus.paid => 'Paid',
          WithdrawalStatus.rejected => 'Rejected',
          WithdrawalStatus.cancelled => 'Cancelled',
        },
      };
}
