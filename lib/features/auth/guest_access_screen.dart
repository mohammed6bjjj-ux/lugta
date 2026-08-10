import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/session.dart';
import 'guest_strings.dart';

class GuestAccessScreen extends StatelessWidget {
  const GuestAccessScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _openAuth(BuildContext context, String route) async {
    final navigator = Navigator.of(context);
    await session.leaveGuestMode();
    if (!navigator.mounted) return;
    navigator.pushNamedAndRemoveUntil(route, (current) => false);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            112,
          ),
          child: Entrance(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                radius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LugtaWordmark(height: 38),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.accentStrong,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      embedded
                          ? GuestStrings.previewTitle
                          : GuestStrings.signInRequiredTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      embedded
                          ? GuestStrings.previewBody
                          : GuestStrings.signInRequiredBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.65,
                      ),
                    ),
                    if (embedded) ...[
                      const SizedBox(height: AppSpacing.md),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  GuestStrings.liveDataNotice,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.6,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const ValueKey('guest_create_account_button'),
                      label: GuestStrings.createSellerAccount,
                      icon: Icons.person_add_alt_1_rounded,
                      accented: true,
                      onPressed: () => _openAuth(context, Routes.register),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      key: const ValueKey('guest_sign_in_button'),
                      label: GuestStrings.signIn,
                      icon: Icons.login_rounded,
                      onPressed: () => _openAuth(context, Routes.login),
                    ),
                    if (!embedded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                        ),
                        label: Text(GuestStrings.backToPreview),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (embedded) return Scaffold(body: content);
    return Scaffold(
      appBar: AppBar(title: Text(GuestStrings.guestPreview)),
      body: content,
    );
  }
}
