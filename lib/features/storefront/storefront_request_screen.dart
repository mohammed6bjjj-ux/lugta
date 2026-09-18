import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/formatters.dart';
import 'storefront_request_details.dart';
import '../../data/session.dart';
import '../../data/storefront_models.dart';
import '../../data/storefront_validation.dart';
import 'storefront_requests_view_model.dart';
import 'storefront_strings.dart';
import 'storefront_widgets.dart';

abstract final class StorefrontRequestStrings {
  static String get expired => StorefrontStrings.t(
    'انتهت صلاحية الطلب',
    'ماوەی داواکاری کۆتایی هاتووە',
    'Request expired',
  );
  static String get origin => StorefrontStrings.t(
    'طلب من الموقع',
    'داواکاری لە ماڵپەڕ',
    'Website order request',
  );
  static String get pending => StorefrontStrings.t(
    'بانتظار موافقتك',
    'چاوەڕێی ڕەزامەندی تۆیە',
    'Awaiting your approval',
  );
  static String get body => StorefrontStrings.t(
    'تواصل مع الزبون للتأكد من الطلب. لن يُرسل للإدارة حتى توافق عليه.',
    'پەیوەندی بە کڕیارەوە بکە بۆ پشتڕاستکردنەوە. تا ڕەزامەندی نەدەیت بۆ بەڕێوەبەرایەتی نانێردرێت.',
    'Contact the customer to confirm the request. It is not sent to administration until you approve it.',
  );
  static String get approve => StorefrontStrings.t(
    'تأكيد وإرسال للإدارة',
    'پشتڕاستکردنەوە و ناردن بۆ بەڕێوەبەرایەتی',
    'Confirm and send to administration',
  );
  static String get reject => StorefrontStrings.t(
    'رفض الطلب',
    'ڕەتکردنەوەی داواکاری',
    'Reject request',
  );
  static String get reason =>
      StorefrontStrings.t('سبب الرفض', 'هۆکاری ڕەتکردنەوە', 'Rejection reason');
  static String get approved => StorefrontStrings.t(
    'تمت الموافقة وإرسال الطلب للإدارة',
    'ڕەزامەندی درا و بۆ بەڕێوەبەرایەتی نێردرا',
    'Approved and sent to administration',
  );
  static String get rejected => StorefrontStrings.t(
    'تم رفض الطلب',
    'داواکاری ڕەتکرایەوە',
    'Request rejected',
  );
  static String get estimate => StorefrontStrings.t(
    'التقدير عند إرسال الطلب',
    'خەمڵاندنی کاتی ناردن',
    'Submitted estimate',
  );
  static String error(String? code) {
    if (code == 'request_timeout' || code == 'request_result_unknown') {
      return StorefrontStrings.t(
        'تأخر الرد؛ ممكن العملية تمت. حدّث حالة الطلب للتحقق قبل إعادة المحاولة، ولا تنشئ طلباً جديداً.',
        'وەڵام دوا کەوت؛ لەوانەیە جێبەجێ بووبێت. دۆخی داواکاری نوێ بکەرەوە.',
        'The response timed out; the action may have completed. Refresh its status before retrying. Do not create a new order.',
      );
    }
    if (code?.contains('expired') == true) {
      return StorefrontStrings.t(
        'انتهت صلاحية الطلب ولم يُرسل للإدارة. اطلب من الزبون إنشاء طلب جديد.',
        'ماوەی داواکاری کۆتایی هاتووە. داوای داواکارییەکی نوێ لە کڕیار بکە.',
        'This request expired and was not submitted. Ask the customer to place a new request.',
      );
    }
    if (code?.contains('price_changed') == true) {
      return StorefrontStrings.t(
        'تغير سعر أحد المنتجات. لم يُرسل الطلب. تواصل مع الزبون لإنشاء طلب جديد بالسعر الحالي.',
        'نرخی بەرهەمێک گۆڕاوە. داواکاری نەنێردرا. پەیوەندی بە کڕیارەوە بکە بۆ داواکاری نوێ.',
        'A product price changed. Nothing was submitted. Ask the customer to place a new request at the current price.',
      );
    }
    if (code?.contains('stock') == true) {
      return StorefrontStrings.t(
        'الكمية المطلوبة لم تعد متوفرة. تواصل مع الزبون ثم ارفض الطلب عند الحاجة.',
        'بڕی داواکراو بەردەست نییە. پەیوەندی بە کڕیارەوە بکە.',
        'Requested stock is no longer available. Contact the customer and reject the request if needed.',
      );
    }
    if (code?.contains('state_changed') == true ||
        code?.contains('version') == true ||
        code?.contains('conflict') == true ||
        code?.contains('already') == true) {
      return StorefrontStrings.t(
        'تغيرت حالة الطلب. حدّث الصفحة قبل المتابعة.',
        'دۆخی داواکاری گۆڕاوە. پەڕەکە نوێ بکەرەوە.',
        'The request has changed. Refresh before continuing.',
      );
    }
    return StorefrontStrings.t(
      'تعذر تحميل أو تحديث طلبات الموقع. تحقق من الإنترنت وأعد المحاولة.',
      'نەتوانرا داواکارییەکان بار یان نوێ بکرێنەوە. ئینتەرنێت بپشکنەوە.',
      'Could not load or update website requests. Check your connection and retry.',
    );
  }
}

class StorefrontRequestCard extends StatelessWidget {
  const StorefrontRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });
  final StorefrontRequest request;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.successSoft,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    StorefrontRequestStrings.origin,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              request.customerName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              request.expired
                  ? StorefrontRequestStrings.expired
                  : request.pending
                  ? StorefrontRequestStrings.pending
                  : request.status == 'approved'
                  ? StorefrontRequestStrings.approved
                  : StorefrontRequestStrings.rejected,
            ),
            Text(
              request.status == 'approved'
                  ? '${StorefrontRequestStrings.estimate}: ${formatIqd(request.total)}'
                  : formatIqd(request.total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              formatDateTime(request.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class StorefrontRequestScreen extends StatefulWidget {
  const StorefrontRequestScreen({
    super.key,
    required this.requestId,
    this.viewModel,
  });
  final String requestId;
  @visibleForTesting
  final StorefrontRequestsViewModel? viewModel;
  @override
  State<StorefrontRequestScreen> createState() =>
      _StorefrontRequestScreenState();
}

class _StorefrontRequestScreenState extends State<StorefrontRequestScreen> {
  late final StorefrontRequestsViewModel _model;
  final _reason = TextEditingController();
  bool _rejecting = false;
  bool _openingOrder = false;
  String? _validation;
  Timer? _expiryRefresh;
  @override
  void initState() {
    super.initState();
    final userId = session.auth.currentUserId;
    _model =
        widget.viewModel ??
        StorefrontRequestsViewModel(
          repository: session.storefront,
          isCurrentUser: () =>
              userId != null && session.auth.currentUserId == userId,
        );
    unawaited(_model.loadRequest(widget.requestId));
    _expiryRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expiryRefresh?.cancel();
    _reason.dispose();
    if (widget.viewModel == null) _model.dispose();
    super.dispose();
  }

  Future<void> _approve(StorefrontRequest request) async {
    if (_model.busy) return;
    if (request.expired) {
      setState(() => _validation = StorefrontRequestStrings.error('expired'));
      return;
    }
    final changed = await _model.approve(request);
    if (!mounted || changed == null) return;
    // Canonical orders remain loaded by the incumbent session/repository path.
    try {
      await session.refreshOrders();
    } catch (_) {
      /* The approved request already contains the durable result. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(StorefrontRequestStrings.approved)));
  }

  Future<void> _reject(StorefrontRequest request) async {
    final reason = normalizeStorefrontRejectionReason(_reason.text);
    if (!isValidStorefrontRejectionReason(reason)) {
      setState(
        () => _validation = StorefrontStrings.t(
          'اكتب سبباً من 2 إلى 300 حرف.',
          'هۆکارێک لە 2 بۆ 300 پیت بنووسە.',
          'Enter a reason between 2 and 300 characters.',
        ),
      );
      return;
    }
    final changed = await _model.reject(request, reason);
    if (!mounted || changed == null) return;
    setState(() {
      _rejecting = false;
      _validation = null;
    });
  }

  Future<void> _openOrder(String orderId) async {
    if (_openingOrder) return;
    setState(() {
      _openingOrder = true;
      _validation = null;
    });
    try {
      final order = await session.refreshOrderById(orderId);
      if (!mounted) return;
      Navigator.pushNamed(context, Routes.orderDetail, arguments: order);
    } catch (_) {
      if (mounted) {
        setState(
          () => _validation = StorefrontStrings.t(
            'تم اعتماد الطلب، لكن تعذر تحميل تفاصيله. تحقق من الاتصال واضغط «عرض الطلب» للمحاولة مجدداً.',
            'داواکاری پەسەند کراوە بەڵام وردەکاری بار نەکرا. دووبارە هەوڵ بدەوە.',
            'The request was approved, but its order details could not load. Check your connection and tap View order to retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingOrder = false);
    }
  }

  Future<void> _contact(Future<bool> Function() action) async {
    try {
      final opened = await action();
      if (!mounted || opened) return;
    } catch (_) {
      if (!mounted) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            StorefrontStrings.t(
              'تعذر فتح تطبيق الاتصال',
              'نەتوانرا ئەپی پەیوەندی بکرێتەوە',
              'Could not open the contact app',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(StorefrontRequestStrings.origin),
      actions: [
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) => IconButton(
            tooltip: StorefrontStrings.retry,
            onPressed: _model.busy || _model.loading
                ? null
                : () => _model.loadRequest(widget.requestId),
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          if (_model.loading && _model.requests.isEmpty) {
            return const StorefrontLoading();
          }
          final request = _model.requests
              .where((item) => item.id == widget.requestId)
              .firstOrNull;
          if (request == null) {
            return ListView(
              children: [
                StorefrontMessage(
                  title: StorefrontRequestStrings.origin,
                  body: _model.errorCode == null
                      ? StorefrontStrings.t(
                          'الطلب غير موجود أو لم يعد متاحاً لهذا الحساب.',
                          'داواکاری نەدۆزرایەوە یان بۆ ئەم هەژمارە بەردەست نییە.',
                          'This request was not found or is no longer available to this account.',
                        )
                      : StorefrontRequestStrings.error(_model.errorCode),
                  action: StorefrontAction(
                    label: StorefrontStrings.retry,
                    onPressed: () => _model.loadRequest(widget.requestId),
                  ),
                ),
              ],
            );
          }
          final zone = session.governorates
              .where((zone) => zone.id == request.deliveryZoneId)
              .firstOrNull;
          return RefreshIndicator(
            onRefresh: () => _model.loadRequest(widget.requestId),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              children: [
                StorefrontRequestDetails(
                  request: request,
                  statusLabel: request.expired
                      ? StorefrontRequestStrings.expired
                      : request.pending
                      ? StorefrontRequestStrings.pending
                      : request.status == 'approved'
                      ? StorefrontRequestStrings.approved
                      : StorefrontRequestStrings.rejected,
                  zoneName: zone?.localizedName ?? '',
                  onCall: () =>
                      _contact(() => launchPhoneNumber(request.customerPhone)),
                  onWhatsApp: () =>
                      _contact(() => launchWhatsApp(request.customerPhone)),
                  onAlternateCall: () => _contact(
                    () => launchPhoneNumber(request.customerAltPhone),
                  ),
                ),
                const SizedBox(height: 12),
                if (request.expired ||
                    request.status == 'rejected' ||
                    request.status == 'approved')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      request.expired
                          ? StorefrontRequestStrings.error('expired')
                          : request.status == 'rejected'
                          ? request.rejectionReason
                          : StorefrontStrings.t(
                              'المبالغ تقديرية عند الإرسال. افتح «عرض الطلب» للمبلغ النهائي بعد خصومات التوصيل.',
                              'بڕەکان خەمڵاندنی کاتی ناردنن. داواکاری بکەرەوە بۆ بڕی کۆتایی.',
                              'Submitted estimates. Open View order for the final total after delivery discounts.',
                            ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (_validation != null || _model.errorCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _validation ??
                            StorefrontRequestStrings.error(_model.errorCode),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (request.pending) ...[
                  if (!_rejecting) ...[
                    StorefrontAction(
                      key: const ValueKey('approve_storefront_request'),
                      label: StorefrontRequestStrings.approve,
                      loading: _model.busy,
                      onPressed: request.expired || _model.loading
                          ? null
                          : () => _approve(request),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _model.busy || _model.loading
                          ? null
                          : () => setState(() => _rejecting = true),
                      child: Text(StorefrontRequestStrings.reject),
                    ),
                  ] else ...[
                    TextField(
                      key: const ValueKey('storefront_rejection_reason'),
                      controller: _reason,
                      enabled: !_model.busy,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: InputDecoration(
                        labelText: StorefrontRequestStrings.reason,
                      ),
                    ),
                    StorefrontAction(
                      label: StorefrontRequestStrings.reject,
                      loading: _model.busy,
                      onPressed: () => _reject(request),
                    ),
                    TextButton(
                      onPressed: _model.busy || _model.loading
                          ? null
                          : () => setState(() => _rejecting = false),
                      child: Text(StorefrontStrings.cancel),
                    ),
                  ],
                ] else if (request.orderId != null)
                  StorefrontAction(
                    label: StorefrontStrings.t(
                      'عرض الطلب',
                      'بینینی داواکاری',
                      'View order',
                    ),
                    loading: _openingOrder,
                    onPressed: () => _openOrder(request.orderId!),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
