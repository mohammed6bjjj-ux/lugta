import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'pressable.dart';

/// البطاقة الحديثة الموحّدة: سطح أبيض بظل ناعم بدل الحدود الصلبة،
/// مع تفاعل ضغط اختياري.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.color,
    this.gradient,
    this.shadows,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// لون السطح — الافتراضي سطح اللوحة الحالية.
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;

  /// فعّلها عندما يلامس المحتوى حواف البطاقة (صور مثلاً).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? null : color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: Material(
        color: gradient == null
            ? (color ?? AppColors.surface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      card = Pressable(onTap: onTap, child: card);
    }
    return card;
  }
}
