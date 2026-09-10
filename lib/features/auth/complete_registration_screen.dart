import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/repositories/repositories.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';

/// Repairs an OTP-confirmed seller whose first profile-completion request was
/// interrupted. No password or second OTP is requested or retained here.
class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({super.key});

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _storeController;
  late final TextEditingController _instagramController;
  final _referralController = TextEditingController();

  Governorate? _governorate;
  bool _acceptedTerms = false;
  bool _loadingData = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: session.seller.name);
    _storeController = TextEditingController(text: session.seller.storeName);
    _instagramController = TextEditingController(
      text: session.seller.instagramUrl,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePublicData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _instagramController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _ensurePublicData() async {
    if (session.governorates.isNotEmpty &&
        session.termsVersion.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingData = true);
    try {
      await session.refreshPublicData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_saving || !_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthStrings.termsRequiredSnack)));
      return;
    }
    if (session.termsVersion.trim().isEmpty) {
      await _ensurePublicData();
      if (!mounted || session.termsVersion.trim().isEmpty) return;
    }

    setState(() => _saving = true);
    try {
      await appBackend.auth.completeRegistration(
        RegistrationCompletionRequest(
          fullName: _nameController.text.trim(),
          storeName: _storeController.text.trim(),
          governorateId: _governorate!.id,
          termsVersion: session.termsVersion,
          instagramUrl: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          referralCode: _referralController.text.trim().isEmpty
              ? null
              : _referralController.text.trim(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    try {
      await session.refreshCurrentProfile();
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (_) => false);
      return;
    }
    if (mounted) openAuthenticatedDestination(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: AppColors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(AuthStrings.completeAccountTitle)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  AuthStrings.completeAccountBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: AuthStrings.fullNameLabel,
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) => validateRequired(
                          value,
                          message: AuthStrings.fullNameRequired,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: AuthStrings.storeNameLabel,
                        controller: _storeController,
                        prefixIcon: Icons.storefront_outlined,
                        validator: (value) => validateRequired(
                          value,
                          message: AuthStrings.storeNameRequired,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: AuthStrings.instagramLabel,
                        controller: _instagramController,
                        prefixIcon: Icons.alternate_email_rounded,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: AuthStrings.referralCodeLabel,
                        controller: _referralController,
                        prefixIcon: Icons.group_add_outlined,
                        textDirection: TextDirection.ltr,
                        validator: validateReferralCode,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(16),
                        ],
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
                          hintText: _loadingData
                              ? '...'
                              : AuthStrings.governorateHint,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        items: [
                          for (final governorate in session.governorates)
                            DropdownMenuItem(
                              value: governorate,
                              child: Text(governorate.localizedName),
                            ),
                        ],
                        onChanged: _loadingData
                            ? null
                            : (value) => setState(() => _governorate = value),
                        validator: (value) => value == null
                            ? AuthStrings.governorateRequired
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(AuthStrings.agreeTo),
                  subtitle: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.policies),
                    child: Text(AuthStrings.termsAndPolicies),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: AuthStrings.completeAccountAction,
                  icon: Icons.verified_user_outlined,
                  loading: _saving,
                  onPressed: _loadingData ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
