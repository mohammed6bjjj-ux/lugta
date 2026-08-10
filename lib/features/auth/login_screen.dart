import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/backend.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';
import 'guest_strings.dart';

/// شاشة تسجيل الدخول — ترويسة لكطة البنفسجية بزوايا منحنية،
/// وبطاقة الفورم تطفو متراكبة على أسفلها.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const double _heroHeight = 320;
  static const double _cardOverlap = 56;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _guestLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await appBackend.auth.signIn(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      await session.refreshAuthenticatedData();
      if (!mounted) return;
      openAuthenticatedDestination(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _continueAsGuest() async {
    if (_loading || _guestLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _guestLoading = true);
    try {
      await session.enterGuestMode();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.shell, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _guestLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: AppColors.isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── الترويسة الغامرة + البطاقة المتراكبة عليها ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeroHeader(height: _heroHeight),
                  Padding(
                    padding: EdgeInsets.only(
                      top: _heroHeight - _cardOverlap,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                    ),
                    child: Entrance(
                      index: 1,
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        radius: AppRadius.lg + 4,
                        shadows: AppShadows.floating,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              fieldKey: const ValueKey('login_phone_field'),
                              label: AuthStrings.phoneLabel,
                              controller: _phoneController,
                              hint: '07XXXXXXXXX',
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              prefixIcon: Icons.phone_android_rounded,
                              validator: validateIraqiPhone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              fieldKey: const ValueKey('login_password_field'),
                              label: AuthStrings.passwordLabel,
                              controller: _passwordController,
                              hint: '••••••',
                              obscureText: _obscure,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: validateLoginPassword,
                              textInputAction: TextInputAction.done,
                              suffix: IconButton(
                                tooltip: _obscure
                                    ? AuthStrings.showPassword
                                    : AuthStrings.hidePassword,
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 22,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  Routes.forgotPassword,
                                ),
                                child: Text(AuthStrings.forgotPasswordQ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PrimaryButton(
                              key: const ValueKey('login_submit_button'),
                              label: AuthStrings.loginTitle,
                              icon: Icons.login_rounded,
                              accented: true,
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── فاصل «أو» + إنشاء حساب ──
              Entrance(
                index: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              AuthStrings.noAccountQ,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: AuthStrings.newAccount,
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.register),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        key: const ValueKey('login_guest_button'),
                        onPressed: _guestLoading ? null : _continueAsGuest,
                        icon: _guestLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.visibility_outlined),
                        label: Text(GuestStrings.continueAsGuest),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// ترويسة حبر مسطّحة تحمل الشعار الرسمي ونصوصاً واضحة.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl + 8),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          // زر الرجوع الزجاجي.
          PositionedDirectional(
            top: 0,
            start: AppSpacing.md,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Pressable(
                  onTap: () => Navigator.maybePop(context),
                  scale: .88,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .14),
                      ),
                    ),
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // الشعار والعناوين.
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg + 8),
                child: Entrance(
                  child: Column(
                    children: [
                      const LugtaWordmark(height: 54, inverse: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AuthStrings.welcomeBack,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Text(
                          AuthStrings.loginSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: .6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
