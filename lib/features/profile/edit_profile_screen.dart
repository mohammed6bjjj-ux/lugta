import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import 'profile_strings.dart';

/// تعديل الملف الشخصي — الاسم واسم المتجر ورابط إنستغرام (الهاتف للقراءة فقط).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _instagramController;
  late final TextEditingController _phoneController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seller = session.seller;
    _nameController = TextEditingController(text: seller.name);
    _storeNameController = TextEditingController(text: seller.storeName);
    _instagramController = TextEditingController(text: seller.instagramUrl);
    _phoneController = TextEditingController(text: seller.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _instagramController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final instagramUrl = normalizeInstagramProfile(_instagramController.text)!;
    setState(() => _saving = true);

    try {
      await session.updateProfile(
        name: _nameController.text.trim(),
        storeName: _storeNameController.text.trim(),
        instagramUrl: instagramUrl,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ProfileStrings.changesSaved)));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _refresh() async {
    await session.refreshAllData();
    if (!mounted) return;
    final seller = session.seller;
    setState(() {
      _nameController.text = seller.name;
      _storeNameController.text = seller.storeName;
      _instagramController.text = seller.instagramUrl;
      _phoneController.text = seller.phone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ProfileStrings.editProfile),
        actions: [SessionRefreshButton(onRefresh: _refresh)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // بطاقة معلومات الحساب القابلة للتعديل.
              Entrance(
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: ProfileStrings.fullNameLabel,
                        hint: ProfileStrings.fullNameHint,
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (v) => validateRequired(
                          v,
                          message: ProfileStrings.fullNameRequired,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: ProfileStrings.storeNameLabel,
                        hint: ProfileStrings.storeNameHint,
                        controller: _storeNameController,
                        prefixIcon: Icons.storefront_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) => validateRequired(
                          v,
                          message: ProfileStrings.storeNameRequired,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ProfileStrings.storeNameInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: ProfileStrings.instagramLabel,
                        hint: 'instagram.com/your.store',
                        controller: _instagramController,
                        prefixIcon: Icons.camera_alt_outlined,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final required = validateRequired(
                            value,
                            message: ProfileStrings.instagramRequired,
                          );
                          if (required != null) return required;
                          return normalizeInstagramProfile(value!) == null
                              ? ProfileStrings.instagramInvalid
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // بطاقة رقم الهاتف المقفل — بأيقونة قفل ذهبية.
              Entrance(
                index: 1,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: ProfileStrings.phoneLabel,
                        controller: _phoneController,
                        enabled: false,
                        prefixIcon: Icons.phone_outlined,
                        textDirection: TextDirection.ltr,
                        suffix: Center(
                          widthFactor: 1,
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsetsDirectional.only(
                              end: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ProfileStrings.phoneLockedInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Entrance(
                index: 2,
                child: PrimaryButton(
                  label: ProfileStrings.saveChanges,
                  icon: Icons.check_rounded,
                  gold: true,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
