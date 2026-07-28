import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// هيكل تحميل متلألئ (Skeleton Shimmer) — حالة التحميل الحديثة
/// بدل مؤشرات الدوران التقليدية.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppRadius.sm),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: [
                (t - .35).clamp(0, 1),
                t.clamp(0, 1),
                (t + .35).clamp(0, 1),
              ],
              colors: [
                AppColors.surfaceAlt,
                AppColors.surface,
                AppColors.surfaceAlt,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
