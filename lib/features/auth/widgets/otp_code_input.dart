import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';

/// حقل رمز تحقق من 6 خانات منفصلة بانتقال تلقائي بين الخانات.
/// تُعرض الخانات بترتيب يسار→يمين كما هو متعارف لرموز التحقق الرقمية.
///
/// التصميم الحديث: سطح [AppColors.surfaceAlt] بلا حد، حد ذهبي عند التركيز،
/// ونبضة تكبير صغيرة عند تعبئة الخانة.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.onCompleted,
    this.enabled = true,
  });

  /// يُستدعى مرة عند اكتمال الخانات الست بالرمز الكامل.
  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput> {
  static const int _length = 6;

  late final List<TextEditingController> _controllers = List.generate(
    _length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    _length,
    (_) => FocusNode(),
  );

  /// خانات تنبض حالياً بعد تعبئتها (Micro-interaction).
  final List<bool> _pulsing = List.filled(_length, false);

  @override
  void initState() {
    super.initState();
    for (final n in _nodes) {
      n.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.removeListener(_onFocusChanged);
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// تفريغ كل الخانات وإرجاع التركيز للخانة الأولى (يُستخدم عند إعادة الإرسال).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (widget.enabled) _nodes.first.requestFocus();
  }

  void _pulse(int index) {
    setState(() => _pulsing[index] = true);
    Future.delayed(AppDurations.fast, () {
      if (mounted) setState(() => _pulsing[index] = false);
    });
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      _pulse(index);
      if (index < _length - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
      if (_code.length == _length) {
        widget.onCompleted(_code);
      }
    } else if (index > 0) {
      // حُذف الرقم — نعود للخانة السابقة.
      _nodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const idealWidth = _length * 56.0;
        final width =
            constraints.hasBoundedWidth && constraints.maxWidth < idealWidth
            ? constraints.maxWidth
            : idealWidth;

        return Center(
          child: SizedBox(
            width: width,
            child: Row(
              // رموز التحقق تُقرأ كأرقام يسار→يمين حتى داخل الواجهة العربية.
              textDirection: TextDirection.ltr,
              children: [
                for (var i = 0; i < _length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: _pulsing[i] ? 1.08 : 1,
                        duration: AppDurations.fast,
                        curve: AppCurves.spring,
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          curve: Curves.easeOut,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _nodes[i].hasFocus
                                ? AppColors.surface
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: _nodes[i].hasFocus
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 1.6,
                            ),
                            boxShadow: _nodes[i].hasFocus
                                ? AppShadows.accentGlow
                                : null,
                          ),
                          child: Center(
                            child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _nodes[i],
                              enabled: widget.enabled,
                              autofocus: i == 0,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              decoration: InputDecoration(
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintText: '•',
                                hintStyle: TextStyle(color: AppColors.divider),
                              ),
                              onChanged: (v) => _onChanged(i, v),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
