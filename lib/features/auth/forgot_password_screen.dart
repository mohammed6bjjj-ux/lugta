import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/backend.dart';
import '../../data/repositories/repositories.dart';
import '../../data/session.dart';
import 'auth_strings.dart';
import 'widgets/otp_code_input.dart';

/// استعادة كلمة المرور — معالج داخلي من 3 خطوات:
/// الهاتف ← رمز التحقق ← كلمة المرور الجديدة.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static List<String> get _stepTitles => [
    AuthStrings.stepPhone,
    AuthStrings.otpTitle,
    AuthStrings.passwordLabel,
  ];

  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final GlobalKey<OtpCodeInputState> _otpKey = GlobalKey<OtpCodeInputState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _verifying = false;
  bool _resending = false;
  bool _abandoning = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ─────────────────────── الخطوة 1: الهاتف ───────────────────────

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await appBackend.auth.sendPasswordRecoveryOtp(
        _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 1;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthStrings.codeSentTo(_phoneController.text.trim())),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // ─────────────────────── الخطوة 2: رمز التحقق ───────────────────────

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

  Future<void> _resend() async {
    if (_resending || _verifying) return;
    setState(() => _resending = true);
    _otpKey.currentState?.clear();
    try {
      await appBackend.auth.resendOtp(
        phone: _phoneController.text.trim(),
        purpose: OtpPurpose.passwordRecovery,
      );
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthStrings.newCodeSentTo(_phoneController.text.trim()),
          ),
        ),
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

  Future<void> _onCodeCompleted(String code) async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      await appBackend.auth.verifyOtp(
        phone: _phoneController.text.trim(),
        token: code,
        purpose: OtpPurpose.passwordRecovery,
      );
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _verifying = false;
        _step = 2;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _verifying = false);
      _otpKey.currentState?.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // ─────────────────────── الخطوة 3: كلمة المرور ───────────────────────

  String? _validateConfirm(String? value) {
    final base = validatePassword(value);
    if (base != null) return base;
    if ((value ?? '') != _passwordController.text) {
      return AuthStrings.passwordsDontMatch;
    }
    return null;
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await appBackend.auth.updatePassword(_passwordController.text);
      try {
        await appBackend.auth.abandonPasswordRecovery();
      } catch (_) {
        // A secure-store cleanup error is non-fatal only after the temporary
        // Auth session has already been removed. Otherwise the user must stay
        // inside recovery rather than accidentally entering the app.
        if (appBackend.auth.hasSession) rethrow;
      }
      await session.clearAuthenticatedData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthStrings.passwordChangedSnack)));
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _editPhone() async {
    if (_abandoning || _verifying || _resending) return;
    setState(() => _abandoning = true);
    try {
      await appBackend.auth.abandonPasswordRecovery();
      await session.clearAuthenticatedData();
      if (!mounted) return;
      _timer?.cancel();
      _otpKey.currentState?.clear();
      setState(() {
        _step = 0;
        _abandoning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _abandoning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _abandonAndReturnToLogin() async {
    if (_abandoning || _loading || _verifying || _resending) return;
    setState(() => _abandoning = true);
    try {
      await appBackend.auth.abandonPasswordRecovery();
      await session.clearAuthenticatedData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _abandoning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // ─────────────────────── الواجهة ───────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_abandonAndReturnToLogin());
      },
      child: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(AuthStrings.forgotTitle),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SizedBox(height: AppSpacing.sm),
                Entrance(
                  child: _StepProgressIndicator(
                    current: _step,
                    titles: _stepTitles,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // تبديل الخطوات بتلاشٍ + انزلاق ناعم.
                AnimatedSwitcher(
                  duration: AppDurations.base,
                  switchInCurve: AppCurves.emphasized,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: switch (_step) {
                    0 => _buildPhoneStep(),
                    1 => _buildOtpStep(),
                    _ => _buildPasswordStep(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: const ValueKey('step-phone'),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _phoneFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AuthStrings.enterYourPhone,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AuthStrings.phoneStepSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: AuthStrings.phoneLabel,
                controller: _phoneController,
                hint: '07XXXXXXXXX',
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                prefixIcon: Icons.phone_android_rounded,
                validator: validateIraqiPhone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: AuthStrings.sendCode,
                loading: _loading,
                onPressed: _sendCode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: const ValueKey('step-otp'),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AuthStrings.enterOtp,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  AuthStrings.otpSentToShort,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _phoneController.text.trim(),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            OtpCodeInput(
              key: _otpKey,
              enabled: !_verifying && !_resending && !_abandoning,
              onCompleted: _onCodeCompleted,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_verifying)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accentStrong,
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
              )
            else if (_secondsLeft > 0)
              // عدّاد إعادة الإرسال داخل كبسولة.
              Center(
                child: Container(
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
                          AuthStrings.resendCountdown('$_secondsLeft'),
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
                ),
              )
            else
              Center(
                child: TextButton.icon(
                  onPressed: _resending || _abandoning ? null : _resend,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(AuthStrings.resendCode),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                key: const ValueKey('recovery-edit-phone'),
                onPressed: _verifying || _resending || _abandoning
                    ? null
                    : _editPhone,
                child: Text(AuthStrings.editPhone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    final theme = Theme.of(context);
    return KeyedSubtree(
      key: const ValueKey('step-password'),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AuthStrings.newPasswordTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AuthStrings.newPasswordSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: AuthStrings.newPasswordTitle,
                controller: _passwordController,
                hint: AuthStrings.passwordHintMin,
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline_rounded,
                validator: validatePassword,
                textInputAction: TextInputAction.next,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: AuthStrings.confirmPasswordLabel,
                controller: _confirmController,
                hint: AuthStrings.confirmPasswordHint,
                obscureText: _obscureConfirm,
                prefixIcon: Icons.lock_reset_rounded,
                validator: _validateConfirm,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: AuthStrings.savePassword,
                loading: _loading,
                onPressed: _savePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر تقدم المعالج: دوائر مرقمة تتصل بخطوط تقدم ذهبية متحركة،
/// بعلامة صح للخطوات المنجزة وتوهج للخطوة الحالية.
class _StepProgressIndicator extends StatelessWidget {
  const _StepProgressIndicator({required this.current, required this.titles});

  final int current;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < titles.length; i++) ...[
          if (i > 0)
            Expanded(
              // خط تقدم متحرك: يمتلئ بالتدرج الذهبي عند بلوغ الخطوة.
              child: Container(
                height: 3,
                // إزاحة للأعلى ليحاذي الخط مركز الدوائر (التسمية أسفلها).
                margin: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                  bottom: 22,
                ),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedFractionallySizedBox(
                    duration: AppDurations.slow,
                    curve: AppCurves.emphasized,
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: i <= current ? 1 : 0,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppDurations.base,
                  curve: AppCurves.emphasized,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: i < current ? AppColors.accentGradient : null,
                    color: switch (current - i) {
                      > 0 => null,
                      0 => AppColors.accentSoft,
                      _ => AppColors.neutralChip,
                    },
                    border: Border.all(
                      color: i <= current
                          ? AppColors.accentStrong
                          : Colors.transparent,
                      width: 1.4,
                    ),
                    boxShadow: i == current ? AppShadows.accentGlow : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppDurations.base,
                      switchInCurve: AppCurves.spring,
                      child: i < current
                          ? Icon(
                              Icons.check_rounded,
                              key: ValueKey('check'),
                              size: 18,
                              color: AppColors.onAccent,
                            )
                          : Text(
                              '${i + 1}',
                              key: const ValueKey('number'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: i == current
                                    ? AppColors.accentStrong
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  titles[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: i == current
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: i <= current
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
