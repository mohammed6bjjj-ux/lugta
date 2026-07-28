import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/price_summary_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models.dart';
import 'wizard_strings.dart';

/// شاشة نجاح إرسال الطلب — تُعرض بعد التأكيد في معالج الطلب.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  /// نبض حلقات الاحتفال حول دائرة النجاح.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  Order get order => widget.order;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _copyOrderCode() {
    Clipboard.setData(ClipboardData(text: order.code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(WizardStrings.orderCodeCopied(order.code))),
      );
  }

  /// حلقة شفافة تتوسع وتتلاشى حول دائرة النجاح — [phase] يزيح توقيت كل حلقة.
  Widget _celebrationRing(double phase) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeOut.transform((_pulse.value + phase) % 1.0);
        return Opacity(
          opacity: (1 - t) * .35,
          child: Transform.scale(
            scale: 1 + t * .5,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: SizedBox(
                        width: 168,
                        height: 168,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _celebrationRing(0),
                            _celebrationRing(.5),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) =>
                                  Transform.scale(scale: value, child: child),
                              child: Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: .35,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(
                                        alpha: .25,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 58,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 1,
                      child: Text(
                        WizardStrings.orderSentTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Entrance(
                      index: 2,
                      child: Text(
                        WizardStrings.orderSentSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 3,
                      child: Center(
                        child: Pressable(
                          onTap: _copyOrderCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm + 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: AppShadows.goldGlow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    order.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 4),
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Entrance(
                      index: 4,
                      child: Center(
                        child: Text(
                          WizardStrings.tapCodeToCopy,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 5,
                      child: PriceSummaryCard(
                        wholesaleTotal: order.wholesaleTotal,
                        saleTotal: order.saleTotal,
                        deliveryFee: order.deliveryFee,
                        quantity: order.totalQuantity,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Entrance(
                      index: 6,
                      offsetY: 14,
                      child: PrimaryButton(
                        label: WizardStrings.viewOrder,
                        icon: Icons.receipt_long_outlined,
                        gold: true,
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed(
                              Routes.orderDetail,
                              arguments: order,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Entrance(
                      index: 7,
                      offsetY: 14,
                      child: SecondaryButton(
                        label: WizardStrings.backToHome,
                        icon: Icons.home_outlined,
                        onPressed: () =>
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              Routes.shell,
                              (route) => false,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
