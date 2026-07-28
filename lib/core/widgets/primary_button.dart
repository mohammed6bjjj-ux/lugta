import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'pressable.dart';

/// الزر الأساسي الحديث: سطح داكن (أو تدرج ذهبي عبر [gold])،
/// ظل ناعم، وتفاعل تصغير عند الضغط.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.color,
    this.gold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final Color? color;

  /// نسخة ذهبية متدرجة بتوهج — للإجراءات المميزة.
  final bool gold;

  bool get _enabled => onPressed != null && !loading;

  /// لون المحتوى: الذهبي/الملوّن أبيض دائماً، والافتراضي onPrimary
  /// (أبيض في الفاتح، داكن على الزر العاجي في الوضع الداكن).
  Color get _fg =>
      gold || color != null || !_enabled ? Colors.white : AppColors.onPrimary;

  @override
  Widget build(BuildContext context) {
    final fg = _fg;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: fg);

    final Widget content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          );

    final button = Pressable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: Curves.easeOut,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !_enabled
              ? const Color(0xFFDDD8D0)
              : gold
              ? null
              : (color ?? AppColors.primary),
          gradient: _enabled && gold ? AppColors.goldGradient : null,
          // كبسولة كاملة الاستدارة — لغة أزرار نول.
          borderRadius: BorderRadius.circular(100),
          boxShadow: !_enabled
              ? null
              : gold
              ? AppShadows.goldGlow
              : [
                  BoxShadow(
                    color: (color ?? AppColors.primary).withValues(alpha: .28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: content,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// زر ثانوي حديث: سطح أبيض بظل خفيف وحد شعري، مع تفاعل ضغط.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = color ?? AppColors.textPrimary;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: fg);

    final button = Pressable(
      onTap: onPressed,
      enabled: enabled,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: color?.withValues(alpha: .4) ?? AppColors.divider,
            width: 1.2,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
