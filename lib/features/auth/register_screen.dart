import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/repositories/repositories.dart';
import '../../data/session.dart';
import 'auth_strings.dart';

/// شاشة إنشاء حساب بائع جديد — تنتهي بإرسال رمز تحقق إلى الهاتف.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _instagramController = TextEditingController();

  Governorate? _governorate;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!session.isDemo &&
        (session.termsVersion.trim().isEmpty ||
            session.policiesText.trim().isEmpty)) {
      try {
        await session.refreshPublicData();
      } catch (_) {
        // The message below is deliberately stable and user-facing.
      }
      if (!mounted) return;
      if (session.termsVersion.trim().isEmpty ||
          session.policiesText.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthStrings.termsUnavailable)));
        return;
      }
    }
    final valid = _formKey.currentState!.validate();
    if (!_acceptedTerms) {
      setState(() => _showTermsError = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthStrings.termsRequiredSnack)));
      return;
    }
    if (!valid) return;

    setState(() => _loading = true);
    try {
      await appBackend.auth.signUp(
        RegistrationRequest(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          storeName: _storeNameController.text.trim(),
          instagramUrl: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          governorateId: _governorate!.id,
          termsVersion: session.termsVersion,
        ),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushNamed(
        context,
        Routes.otp,
        arguments: {
          'phone': _phoneController.text.trim(),
          'purpose': 'register',
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _refreshRegistrationData() async {
    final selectedId = _governorate?.id;
    await session.refreshPublicData();
    if (!mounted) return;
    Governorate? refreshedSelection;
    if (selectedId != null) {
      for (final governorate in session.governorates) {
        if (governorate.id == selectedId) {
          refreshedSelection = governorate;
          break;
        }
      }
    }
    setState(() => _governorate = refreshedSelection);
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
          title: Text(AuthStrings.createAccount),
          actions: [SessionRefreshButton(onRefresh: _refreshRegistrationData)],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Entrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthStrings.startJourney,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AuthStrings.registerSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // بطاقة البيانات الشخصية.
                Entrance(
                  index: 1,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(
                          icon: Icons.badge_outlined,
                          title: AuthStrings.personalInfo,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: AuthStrings.fullNameLabel,
                          controller: _nameController,
                          hint: AuthStrings.fullNameHint,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => validateRequired(
                            v,
                            message: AuthStrings.fullNameRequired,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
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
                          label: AuthStrings.passwordLabel,
                          controller: _passwordController,
                          hint: AuthStrings.passwordHintMin,
                          obscureText: _obscure,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: validatePassword,
                          textInputAction: TextInputAction.next,
                          suffix: IconButton(
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // بطاقة بيانات المتجر.
                Entrance(
                  index: 2,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(
                          icon: Icons.storefront_outlined,
                          title: AuthStrings.storeInfo,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: AuthStrings.storeNameLabel,
                          controller: _storeNameController,
                          hint: AuthStrings.storeNameHint,
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) => validateRequired(
                            v,
                            message: AuthStrings.storeNameRequired,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: AuthStrings.instagramLabel,
                          controller: _instagramController,
                          hint: 'instagram.com/yourstore',
                          keyboardType: TextInputType.url,
                          textDirection: TextDirection.ltr,
                          prefixIcon: Icons.alternate_email_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          AuthStrings.governorate,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<Governorate>(
                          initialValue: _governorate,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: AuthStrings.governorateHint,
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          items: [
                            for (final g in session.governorates)
                              DropdownMenuItem(
                                value: g,
                                child: Text(g.localizedName),
                              ),
                          ],
                          onChanged: (g) => setState(() => _governorate = g),
                          validator: (g) => g == null
                              ? AuthStrings.governorateRequired
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // الموافقة على الشروط — إلزامية قبل الإرسال،
                // وتتوهج الخلفية بلون الخطأ عند تجاهلها.
                Entrance(
                  index: 3,
                  child: AnimatedContainer(
                    duration: AppDurations.base,
                    curve: AppCurves.emphasized,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _showTermsError && !_acceptedTerms
                          ? AppColors.errorSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppColors.goldDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: BorderSide(
                                color: AppColors.divider,
                                width: 1.6,
                              ),
                              onChanged: (v) => setState(() {
                                _acceptedTerms = v ?? false;
                                if (_acceptedTerms) _showTermsError = false;
                              }),
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _acceptedTerms = !_acceptedTerms;
                                      if (_acceptedTerms) {
                                        _showTermsError = false;
                                      }
                                    }),
                                    child: Text(
                                      AuthStrings.agreeTo,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      Routes.policies,
                                    ),
                                    child: Text(
                                      AuthStrings.termsAndPolicies,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.goldDark,
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.goldDark,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_showTermsError && !_acceptedTerms)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: AppSpacing.md,
                              top: AppSpacing.xs,
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              AuthStrings.termsRequiredInline,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 4,
                  child: PrimaryButton(
                    label: AuthStrings.createAccountAction,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Entrance(
                  index: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          AuthStrings.alreadyHaveAccountQ,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.login),
                        child: Text(AuthStrings.loginTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ترويسة بطاقة صغيرة: أيقونة داخل كبسولة ذهبية ناعمة بجوار العنوان.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.goldDark),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
