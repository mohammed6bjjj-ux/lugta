import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/formatters.dart';
import '../../core/request_id.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/price_summary_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/repositories/repositories.dart';
import '../../data/session.dart';
import 'orders_strings.dart';

/// شاشة تفاصيل طلب واحد: الحالة، الخط الزمني، العناصر، الزبون، الحسبة، الإجراءات.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  /// المسار السعيد الكامل للطلب.
  static const List<OrderStatus> _happyPath = [
    OrderStatus.pendingReview,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.completed,
  ];
  bool _cancelling = false;
  Timer? _cancellationWindowTimer;

  @override
  void initState() {
    super.initState();
    final remaining = widget.order.createdAt
        .add(const Duration(hours: 1))
        .difference(DateTime.now());
    if (!remaining.isNegative) {
      _cancellationWindowTimer = Timer(
        remaining + const Duration(milliseconds: 100),
        () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    _cancellationWindowTimer?.cancel();
    super.dispose();
  }

  /// أحدث نسخة من الطلب من الجلسة (قد تتغير حالته بعد الإلغاء مثلاً).
  Order get _order => session.orderById(widget.order.id) ?? widget.order;

  String _statusDescription(OrderStatus status) =>
      OrdersStrings.statusDescription(status);

  /// الخطوات المتوقعة القادمة للطلب غير المنتهي.
  List<OrderStatus> _upcomingSteps(Order order) {
    if (order.status.isTerminal) return const [];
    switch (order.status) {
      case OrderStatus.deliveryFailed:
        return const [OrderStatus.returning, OrderStatus.returned];
      case OrderStatus.returning:
        return const [OrderStatus.returned];
      default:
        final index = _happyPath.indexOf(order.status);
        if (index == -1) return const [];
        return _happyPath.sublist(index + 1);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _callPhone(String phone) async {
    final opened = await launchPhoneNumber(phone);
    if (!opened && mounted) _showSnack(OrdersStrings.contactAppUnavailable);
  }

  Future<void> _contactSupport(Order order) async {
    final opened = await launchWhatsApp(
      session.supportWhatsapp,
      message: OrdersStrings.supportMessage(order.code),
    );
    if (!opened && mounted) _showSnack(OrdersStrings.contactAppUnavailable);
  }

  Future<void> _confirmCancel(Order order) async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(OrdersStrings.cancelOrder),
        content: Text(OrdersStrings.cancelOrderConfirm(order.code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(OrdersStrings.dismiss),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(OrdersStrings.confirmCancelYes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      if (mounted) setState(() => _cancelling = false);
      return;
    }
    try {
      await session.cancelOrder(order.id);
      if (!mounted) return;
      _showSnack(OrdersStrings.orderCancelled(order.code));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      _showSnack(error.toString());
    }
  }

  Future<void> _openChangeRequestSheet(Order order) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChangeRequestSheet(order: order),
    );
    if (sent == true && mounted) {
      _showSnack(OrdersStrings.changeRequestSent);
    }
  }

  Future<void> _openComplaintSheet(Order order) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ComplaintSheet(order: order),
    );
    if (sent == true && mounted) {
      _showSnack(OrdersStrings.complaintSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final order = _order;
        return Scaffold(
          // يمتد المحتوى خلف شريط الإجراءات الزجاجي السفلي.
          extendBody: true,
          appBar: AppBar(title: Text(order.code)),
          body: SessionRefreshIndicator(
            onRefresh: () async {
              await session.refreshOrderById(order.id);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                220,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Entrance(
                    index: 0,
                    child: _StatusCard(
                      order: order,
                      description: _statusDescription(order.status),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 1,
                    child: _SectionCard(
                      title: OrdersStrings.timelineTitle,
                      icon: Icons.timeline_rounded,
                      child: _OrderTimeline(
                        history: order.statusHistory,
                        upcoming: _upcomingSteps(order),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 2,
                    child: _SectionCard(
                      title: OrdersStrings.productItemsTitle,
                      icon: Icons.inventory_2_outlined,
                      child: _ProductItemsCard(order: order),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 3,
                    child: _SectionCard(
                      title: OrdersStrings.customerInfoTitle,
                      icon: Icons.person_outline_rounded,
                      child: _CustomerCard(order: order, onCall: _callPhone),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 4,
                    child: PriceSummaryCard(
                      wholesaleTotal: order.wholesaleTotal,
                      saleTotal: order.saleTotal,
                      deliveryFee: order.deliveryFee,
                      baseDeliveryFee: order.baseDeliveryFee,
                      packagingTotal: order.packagingTotal,
                      quantity: order.totalQuantity,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 5,
                    child: _StoreNameNotice(storeName: order.storeNameSnapshot),
                  ),
                  if (order.complaints.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 6,
                      child: _SectionCard(
                        title: OrdersStrings.complaintsTitle,
                        icon: Icons.report_problem_outlined,
                        child: _ComplaintsCard(complaints: order.complaints),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildActionsBar(order),
        );
      },
    );
  }

  /// شريط الإجراءات السفلي: لوحة زجاجية عائمة فوق المحتوى.
  Widget _buildActionsBar(Order order) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm + 4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.floating,
        ),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm + 4,
              AppSpacing.sm + 4,
              AppSpacing.sm + 4,
              AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.sellerCanCancelDirectly) ...[
                  SecondaryButton(
                    label: OrdersStrings.cancelOrder,
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    onPressed: _cancelling ? null : () => _confirmCancel(order),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ] else if (order.sellerCanRequestChange) ...[
                  SecondaryButton(
                    label: OrdersStrings.requestChangeOrCancel,
                    icon: Icons.edit_note_rounded,
                    onPressed: () => _openChangeRequestSheet(order),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                SecondaryButton(
                  label: OrdersStrings.addComplaintOrReport,
                  icon: Icons.report_problem_outlined,
                  onPressed: () => _openComplaintSheet(order),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: () => _contactSupport(order),
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: Text(OrdersStrings.contactSupportAboutOrder),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة الحالة الحالية: خلفية بلون الحالة الناعم وأيقونة داخل دائرة بلونها.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order, required this.description});

  final Order order;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status;
    return AppCard(
      color: status.softColor,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: status.color.withValues(alpha: .35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(status.icon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.labelAr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.failReason != null) ...[
            const SizedBox(height: AppSpacing.md - 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md - 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          OrdersStrings.failReason(order.failReason!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          OrdersStrings.noFeesOnReturns,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة قسم موحّدة بعنوان وأيقونة داخل مربع ذهبي ناعم.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                ),
                child: Icon(icon, size: 18, color: AppColors.goldDark),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// الخط الزمني الحديث: الخطوات المنجزة بدوائر ممتلئة وخط متدرج،
/// الحالية تنبض، والقادمة باهتة منقطة — مع دخول متدرج لكل صف.
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.history, required this.upcoming});

  final List<OrderStatusEntry> history;
  final List<OrderStatus> upcoming;

  @override
  Widget build(BuildContext context) {
    final total = history.length + upcoming.length;
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          Entrance(
            index: i,
            offsetY: 14,
            child: _TimelineTile(
              status: history[i].status,
              at: history[i].at,
              note: history[i].note,
              isLast: i == total - 1,
              done: true,
              isCurrent:
                  i == history.length - 1 && !history[i].status.isTerminal,
            ),
          ),
        for (var i = 0; i < upcoming.length; i++)
          Entrance(
            index: history.length + i,
            offsetY: 14,
            child: _TimelineTile(
              status: upcoming[i],
              isLast: history.length + i == total - 1,
              done: false,
            ),
          ),
      ],
    );
  }
}

class _TimelineTile extends StatefulWidget {
  const _TimelineTile({
    required this.status,
    required this.isLast,
    required this.done,
    this.isCurrent = false,
    this.at,
    this.note,
  });

  final OrderStatus status;
  final DateTime? at;
  final String? note;
  final bool isLast;
  final bool done;

  /// النقطة الحالية تنبض بحلقة شفافة تتوسع.
  final bool isCurrent;

  @override
  State<_TimelineTile> createState() => _TimelineTileState();
}

class _TimelineTileState extends State<_TimelineTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.isCurrent) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _TimelineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.isCurrent && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _buildDot() {
    final status = widget.status;

    final Widget dot = widget.done
        ? Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: status.color.withValues(alpha: .32),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(status.icon, size: 15, color: Colors.white),
          )
        : SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: AppColors.textSecondary.withValues(alpha: .35),
              ),
              child: Icon(
                status.icon,
                size: 14,
                color: AppColors.textSecondary.withValues(alpha: .45),
              ),
            ),
          );

    if (!widget.isCurrent) return dot;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_pulse.value);
            return Container(
              width: 32 + 16 * t,
              height: 32 + 16 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: status.color.withValues(alpha: (1 - t) * .45),
                  width: 2,
                ),
              ),
            );
          },
        ),
        dot,
      ],
    );
  }

  Widget _buildConnector() {
    if (widget.done) {
      final color = widget.status.color;
      return Container(
        width: 2.4,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .45), color.withValues(alpha: .1)],
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        painter: _DottedLinePainter(
          color: AppColors.textSecondary.withValues(alpha: .3),
        ),
        child: const SizedBox(width: 2.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = widget.done;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.status.labelAr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: done ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          done && widget.at != null
              ? formatDateTime(widget.at!)
              : OrdersStrings.expectedStep,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (widget.note != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neutralChip,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              widget.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                SizedBox(height: 34, child: Center(child: _buildDot())),
                if (!widget.isLast) Expanded(child: _buildConnector()),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.isLast ? 0 : AppSpacing.md,
              ),
              child: done ? content : Opacity(opacity: .6, child: content),
            ),
          ),
        ],
      ),
    );
  }
}

/// حدود دائرة منقطة للنقاط القادمة في الخط الزمني.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dashCount = 12;
    const sweep = (2 * math.pi) / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * .55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// خط عمودي منقط للخطوات القادمة في الخط الزمني.
class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + 4, size.height)),
        paint,
      );
      y += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// المنتج وعناصر الطلب (متغير × كمية).
class _ProductItemsCard extends StatelessWidget {
  const _ProductItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppNetworkImage(
              order.productImage,
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.hasMultipleProducts
                        ? '${order.productName} ${OrdersStrings.additionalProducts(formatNumber(order.productCount - 1))}'
                        : order.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    OrdersStrings.totalQuantity(
                      formatNumber(order.totalQuantity),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          child: Divider(),
        ),
        for (var i = 0; i < order.items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              AppNetworkImage(
                order.items[i].imageUrl,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.hasMultipleProducts &&
                        order.items[i].productName.isNotEmpty)
                      Text(
                        order.items[i].productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Text(
                      order.items[i].variantName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: order.hasMultipleProducts
                            ? AppColors.textSecondary
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '× ${formatNumber(order.items[i].quantity)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (order.items[i].packagingName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 52),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 17),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${order.items[i].packagingName} · '
                      '${order.items[i].packagingUnitPrice == 0 ? OrdersStrings.freePackaging : formatIqd(order.items[i].packagingUnitPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// بيانات الزبون مع أزرار اتصال فعلية.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order, required this.onCall});

  final Order order;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.badge_outlined,
          label: OrdersStrings.customerNameLabel,
          value: order.customerName,
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: OrdersStrings.phoneLabel,
          value: order.customerPhone,
          trailing: _CallButton(onTap: () => onCall(order.customerPhone)),
        ),
        if (order.customerPhone2 != null)
          _InfoRow(
            icon: Icons.phone_callback_outlined,
            label: OrdersStrings.altPhoneLabel,
            value: order.customerPhone2!,
            trailing: _CallButton(onTap: () => onCall(order.customerPhone2!)),
          ),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: OrdersStrings.governorateLabel,
          value: order.governorateName,
        ),
        _InfoRow(
          icon: Icons.home_outlined,
          label: OrdersStrings.addressLabel,
          value: order.addressDetails,
        ),
        if (order.landmark != null)
          _InfoRow(
            icon: Icons.near_me_outlined,
            label: OrdersStrings.landmarkLabel,
            value: order.landmark!,
          ),
        if (order.deliveryCompany != null)
          _InfoRow(
            icon: Icons.local_shipping_outlined,
            label: OrdersStrings.deliveryCompanyLabel,
            value: order.deliveryCompany!,
          ),
        if (order.trackingNumber != null)
          _InfoRow(
            icon: Icons.pin_outlined,
            label: OrdersStrings.trackingNumberLabel,
            value: order.trackingNumber!,
          ),
        if (order.notes != null)
          _InfoRow(
            icon: Icons.sticky_note_2_outlined,
            label: OrdersStrings.notesLabel,
            value: order.notes!,
          ),
      ],
    );
  }
}

/// أيقونة اتصال داخل دائرة ناعمة قابلة للنقر.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.infoSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.call_outlined, size: 18, color: AppColors.info),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// تنويه اسم المتجر المطبوع على البوليصة — بطاقة بتدرج ذهبي ناعم.
class _StoreNameNotice extends StatelessWidget {
  const _StoreNameNotice({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [AppColors.goldSoft, const Color(0xFFFDFBF7)],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 21,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: OrdersStrings.arrivesUnderName,
                children: [
                  TextSpan(
                    text: storeName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintsCard extends StatelessWidget {
  const _ComplaintsCard({required this.complaints});

  final List<OrderComplaint> complaints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (index, complaint) in complaints.indexed) ...[
          if (index > 0) const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.subject,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                OrdersStrings.complaintStatus(complaint.status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${complaint.ticketNumber} · '
            '${complaint.kind == OrderComplaintKind.report ? OrdersStrings.reportKind : OrdersStrings.complaintKind}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(complaint.message),
          ),
          if (complaint.adminResponse?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${OrdersStrings.adminResponse}: ${complaint.adminResponse}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ComplaintSheet extends StatefulWidget {
  const _ComplaintSheet({required this.order});

  final Order order;

  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<_ComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  late final String _clientRequestId = newUuidV4();
  OrderComplaintKind _kind = OrderComplaintKind.complaint;
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await session.createOrderComplaint(
        orderId: widget.order.id,
        kind: _kind,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        clientRequestId: _clientRequestId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${OrdersStrings.addComplaintOrReport} · ${widget.order.code}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<OrderComplaintKind>(
                  segments: [
                    ButtonSegment(
                      value: OrderComplaintKind.complaint,
                      label: Text(OrdersStrings.complaintKind),
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                    ButtonSegment(
                      value: OrderComplaintKind.report,
                      label: Text(OrdersStrings.reportKind),
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (value) {
                    setState(() => _kind = value.first);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _subjectController,
                  maxLength: 160,
                  decoration: InputDecoration(
                    labelText: OrdersStrings.complaintSubject,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? OrdersStrings.reasonRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 4000,
                  decoration: InputDecoration(
                    labelText: OrdersStrings.complaintDetails,
                    hintText: OrdersStrings.complaintDetailsHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().length < 10
                      ? OrdersStrings.reasonRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: OrdersStrings.submitComplaint,
                  icon: Icons.send_outlined,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// BottomSheet طلب تعديل / إلغاء يُرسل للإدارة.
class _ChangeRequestSheet extends StatefulWidget {
  const _ChangeRequestSheet({required this.order});

  final Order order;

  @override
  State<_ChangeRequestSheet> createState() => _ChangeRequestSheetState();
}

class _ChangeRequestSheetState extends State<_ChangeRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.order.customerPhone,
  );
  late final TextEditingController _altPhoneController = TextEditingController(
    text: widget.order.customerPhone2 ?? '',
  );
  late final TextEditingController _addressController = TextEditingController(
    text: widget.order.addressDetails,
  );
  bool _isCancelRequest = false;
  bool _submitting = false;
  late final String _clientRequestId = newUuidV4();

  @override
  void dispose() {
    _reasonController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await session.submitOrderChangeRequest(
        orderId: widget.order.id,
        type: _isCancelRequest
            ? OrderChangeRequestType.cancel
            : OrderChangeRequestType.edit,
        reason: _reasonController.text.trim(),
        clientRequestId: _clientRequestId,
        proposedChanges: _isCancelRequest
            ? const {}
            : {
                'customer_phone': _phoneController.text.trim(),
                'customer_alt_phone': _altPhoneController.text.trim().isEmpty
                    ? null
                    : _altPhoneController.text.trim(),
                'address_line': _addressController.text.trim(),
              },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _typeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.emphasized,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.divider,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? AppShadows.card : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.goldDark : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.goldDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OrdersStrings.changeRequestTitle(widget.order.code),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                OrdersStrings.changeRequestBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _typeOption(
                    label: OrdersStrings.editOrder,
                    icon: Icons.edit_outlined,
                    selected: !_isCancelRequest,
                    onTap: () => setState(() => _isCancelRequest = false),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _typeOption(
                    label: OrdersStrings.cancelOrder,
                    icon: Icons.cancel_outlined,
                    selected: _isCancelRequest,
                    onTap: () => setState(() => _isCancelRequest = true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_isCancelRequest) ...[
                AppTextField(
                  label: OrdersStrings.phoneLabel,
                  controller: _phoneController,
                  hint: '07XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: validateIraqiPhone,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: OrdersStrings.altPhoneLabel,
                  controller: _altPhoneController,
                  hint: '07XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? null
                      : validateIraqiPhone(value),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: OrdersStrings.addressLabel,
                  controller: _addressController,
                  maxLines: 2,
                  inputFormatters: [LengthLimitingTextInputFormatter(1200)],
                  validator: (value) => validateRequired(
                    value,
                    message: OrdersStrings.reasonRequired,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                label: _isCancelRequest
                    ? OrdersStrings.cancelReasonLabel
                    : OrdersStrings.editDetailsLabel,
                controller: _reasonController,
                hint: _isCancelRequest
                    ? OrdersStrings.cancelReasonHint
                    : OrdersStrings.editDetailsHint,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                validator: (v) =>
                    validateRequired(v, message: OrdersStrings.reasonRequired),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: OrdersStrings.sendToAdmin,
                icon: Icons.send_rounded,
                gold: true,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
