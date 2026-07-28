import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// حقل إدخال موحّد بعنوان أعلى الحقل.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
    this.inputFormatters,
    this.textDirection,
    this.autofocus = false,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final bool autofocus;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onChanged: onChanged,
          enabled: enabled,
          inputFormatters: inputFormatters,
          textDirection: textDirection,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 22, color: AppColors.textSecondary),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
