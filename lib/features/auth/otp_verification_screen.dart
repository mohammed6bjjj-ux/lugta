import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/entrance.dart';
import '../../data/backend.dart';
import '../../data/repositories/repositories.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';
import 'widgets/otp_code_input.dart';

/// شاشة التحقق برمز OTP — 6 خانات مع عدّاد إعادة إرسال 60 ثانية.
///
/// [purpose]:
/// - 'register': عند الاكتمال ينتقل إلى شاشة انتظار الموافقة.
/// - غير ذلك (مثل 'resetPassword'): يعود للشاشة السابقة بالنتيجة true.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.purpose,
  });

  final String phone;
  final String purpose;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<OtpCodeInputState> _otpKey = GlobalKey<OtpCodeInputState>();

  Timer? _timer;
  int _secondsLeft = 60;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  OtpPurpose get _purpose => switch (widget.purpose) {
    'register' => OtpPurpose.registration,
    'phoneChange' => OtpPurpose.phoneChange,
    _ => OtpPurpose.passwordRecovery,
  };

  Future<void> _resend() async {
    if (_resending || _verifying) return;
    setState(() => _resending = true);
    _otpKey.currentState?.clear();
    try {
      await appBackend.auth.resendOtp(phone: widget.phone, purpose: _purpose);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthStrings.newOtpSentTo(widget.phone))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _onCompleted(String code) async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      await appBackend.auth.verifyOtp(
        phone: widget.phone,
        token: code,
        purpose: _purpose,
      );
      if (widget.purpose == 'register') {
        await session.refreshAuthenticatedData();
      }
      if (!mounted) return;
      if (widget.purpose == 'register') {
        openAuthenticatedDestination(context);
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _otpKey.currentState?.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: AppColors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(AuthStrings.otpTitle),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      boxShadow: AppShadows.goldGlow,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 1,
                child: Column(
                  children: [
                    Text(
                      AuthStrings.enterOtp,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AuthStrings.otpSentToPhone,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.phone,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Entrance(
                index: 2,
                child: OtpCodeInput(
                  key: _otpKey,
                  enabled: !_verifying && !_resending,
                  onCompleted: _onCompleted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedOpacity(
                opacity: _verifying ? 1 : 0,
                duration: AppDurations.fast,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.goldDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        AuthStrings.verifyingCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // عدّاد إعادة الإرسال داخل كبسولة، يتبدل بنعومة إلى زر الإرسال.
              Entrance(
                index: 3,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppDurations.base,
                    switchInCurve: AppCurves.emphasized,
                    child: _secondsLeft > 0
                        ? Container(
                            key: const ValueKey('countdown'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutralChip,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    AuthStrings.resendCountdown(
                                      '$_secondsLeft',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton.icon(
                            key: const ValueKey('resend'),
                            onPressed: _verifying || _resending
                                ? null
                                : _resend,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(AuthStrings.resendCode),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
