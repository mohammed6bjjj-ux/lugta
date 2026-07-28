import 'package:flutter/material.dart';

import '../../app/app_metadata.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import 'profile_strings.dart';

/// شاشة حول التطبيق — هوية لُگطة ونبذة عن المنصة والإصدار.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(ProfileStrings.about)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Entrance(child: Center(child: BrandIcon(size: 104))),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 1,
            child: Column(
              children: [
                const LugtaWordmark(height: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ProfileStrings.brandTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Entrance(
            index: 2,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ProfileStrings.aboutTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ProfileStrings.aboutBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 3,
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              clip: true,
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.inventory_2_outlined,
                    text: ProfileStrings.feature1,
                  ),
                  const Divider(indent: 68, endIndent: AppSpacing.md),
                  _FeatureRow(
                    icon: Icons.campaign_outlined,
                    text: ProfileStrings.feature2,
                  ),
                  const Divider(indent: 68, endIndent: AppSpacing.md),
                  _FeatureRow(
                    icon: Icons.payments_outlined,
                    text: ProfileStrings.feature3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 4,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 21,
                      color: AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      ProfileStrings.version,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    AppMetadata.version,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Entrance(
            index: 5,
            child: Column(
              children: [
                Text(
                  ProfileStrings.copyright,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ProfileStrings.madeInIraq,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.goldDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
