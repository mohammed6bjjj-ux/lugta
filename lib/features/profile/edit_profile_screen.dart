import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import '../../data/repositories/repositories.dart';
import 'profile_strings.dart';

/// تعديل الملف الشخصي — الاسم واسم المتجر ورابط إنستغرام (الهاتف للقراءة فقط).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.pickImage, this.recoverLostData});

  @visibleForTesting
  final Future<XFile?> Function()? pickImage;

  @visibleForTesting
  final Future<LostDataResponse> Function()? recoverLostData;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _instagramController;
  late final TextEditingController _phoneController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _saving = false;
  bool _pickingAvatar = false;
  bool _removeAvatar = false;
  Uint8List? _avatarBytes;
  String? _avatarMimeType;

  static const int _maxAvatarBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final seller = session.seller;
    _nameController = TextEditingController(text: seller.name);
    _storeNameController = TextEditingController(text: seller.storeName);
    _instagramController = TextEditingController(text: seller.instagramUrl);
    _phoneController = TextEditingController(text: seller.phone);
    unawaited(_recoverLostAvatar());
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
      final avatarChange = _avatarBytes != null
          ? ProfileAvatarChange.replace(
              bytes: _avatarBytes!,
              mimeType: _avatarMimeType,
            )
          : _removeAvatar
          ? const ProfileAvatarChange.remove()
          : null;
      await session.updateProfile(
        name: _nameController.text.trim(),
        storeName: _storeNameController.text.trim(),
        instagramUrl: instagramUrl,
        avatarChange: avatarChange,
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
      _avatarBytes = null;
      _avatarMimeType = null;
      _removeAvatar = false;
    });
  }

  Future<void> _recoverLostAvatar() async {
    try {
      final response =
          await (widget.recoverLostData?.call() ??
              _imagePicker.retrieveLostData());
      if (!mounted || response.isEmpty) return;
      final recoveredFile = response.files?.firstOrNull ?? response.file;
      if (recoveredFile != null) {
        await _acceptAvatarFile(recoveredFile);
        return;
      }
      final exception = response.exception;
      if (exception != null && mounted) {
        _showAvatarError(ProfileStrings.avatarSelectionFailed);
      }
    } catch (_) {
      if (mounted) _showAvatarError(ProfileStrings.avatarSelectionFailed);
    }
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar || _saving) return;
    setState(() => _pickingAvatar = true);
    try {
      final file =
          await (widget.pickImage?.call() ??
              _imagePicker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 88,
              ));
      if (file != null) await _acceptAvatarFile(file);
    } catch (_) {
      if (mounted) _showAvatarError(ProfileStrings.avatarSelectionFailed);
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _acceptAvatarFile(XFile file) async {
    final length = await file.length();
    if (length <= 0 || length > _maxAvatarBytes) {
      if (mounted) _showAvatarError(ProfileStrings.avatarTooLarge);
      return;
    }
    final bytes = await file.readAsBytes();
    final mimeType = _avatarMimeTypeFor(bytes, file.mimeType);
    if (mimeType == null) {
      if (mounted) _showAvatarError(ProfileStrings.avatarUnsupported);
      return;
    }
    if (!mounted) return;
    setState(() {
      _avatarBytes = Uint8List.fromList(bytes);
      _avatarMimeType = mimeType;
      _removeAvatar = false;
    });
  }

  void _removeSelectedAvatar() {
    if (_saving) return;
    setState(() {
      _avatarBytes = null;
      _avatarMimeType = null;
      _removeAvatar = session.seller.avatarPath.isNotEmpty;
    });
  }

  void _showAvatarError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _sellerInitials() {
    final text = session.seller.storeName.trim().isNotEmpty
        ? session.seller.storeName.trim()
        : session.seller.name.trim();
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.isEmpty ? '؟' : words.take(2).map((word) => word[0]).join();
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
              Entrance(
                child: AppCard(
                  child: Column(
                    children: [
                      Semantics(
                        label: ProfileStrings.profilePhoto,
                        image: true,
                        child: Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                            ),
                            child: _avatarBytes != null
                                ? Image.memory(
                                    _avatarBytes!,
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                    cacheWidth: 256,
                                  )
                                : !_removeAvatar &&
                                      session.seller.avatarUrl.isNotEmpty
                                ? AppNetworkImage(
                                    session.seller.avatarUrl,
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                    fallbackIcon: Icons.person_outline_rounded,
                                  )
                                : Text(
                                    _sellerInitials(),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: AppColors.accentStrong,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        ProfileStrings.profilePhoto,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ProfileStrings.profilePhotoHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _pickingAvatar || _saving
                                ? null
                                : _pickAvatar,
                            icon: _pickingAvatar
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: Text(ProfileStrings.choosePhoto),
                          ),
                          if (_avatarBytes != null ||
                              (!_removeAvatar &&
                                  session.seller.avatarPath.isNotEmpty))
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _removeSelectedAvatar,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text(ProfileStrings.removePhoto),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                            color: AppColors.accentStrong,
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
                              color: AppColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: AppColors.accentStrong,
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
                            color: AppColors.accentStrong,
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
                  accented: true,
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

String? _avatarMimeTypeFor(Uint8List bytes, String? reportedMimeType) {
  final normalized = reportedMimeType?.trim().toLowerCase().split(';').first;
  if (normalized == 'image/jpg' || normalized == 'image/jpeg') {
    return 'image/jpeg';
  }
  if (normalized == 'image/png' || normalized == 'image/webp') {
    return normalized;
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}
