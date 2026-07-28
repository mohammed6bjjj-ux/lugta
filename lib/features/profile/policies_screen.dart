import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import 'legal/legal_document.dart';
import 'legal/legal_document_screen.dart';
import 'legal/legal_documents.dart';
import 'profile_strings.dart';

/// فهرس السياسات والوثائق القانونية المنشورة داخل التطبيق.
class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode == 'ar';
    final isKurdish = languageCode == 'ku' || languageCode == 'ckb';

    String localized({
      required String ar,
      required String ku,
      required String en,
    }) {
      if (isArabic) return ar;
      if (isKurdish) return ku;
      return en;
    }

    return Scaffold(
      key: const ValueKey('legal_center_screen'),
      appBar: AppBar(title: Text(ProfileStrings.policies)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final policyVersion = session.termsVersion.trim();

          return SessionRefreshIndicator(
            onRefresh: session.refreshPublicData,
            child: ListView(
              key: const ValueKey('legal_center_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Entrance(
                  child: AppCard(
                    key: const ValueKey('legal_center_header'),
                    color: AppColors.goldSoft,
                    shadows: const [],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localized(
                                      ar: 'المركز القانوني',
                                      ku: 'ناوەندی یاسایی',
                                      en: 'Legal Center',
                                    ),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    localized(
                                      ar: 'كل ما يوضح حقوقك والتزاماتك وطريقة عمل لقطة في مكان واحد.',
                                      ku: 'هەموو ماف و ئەرکەکانت و شێوازی کاری لقطة لە یەک شوێن.',
                                      en: 'Your rights, responsibilities and how Luqta works, in one place.',
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _InfoChip(
                              icon: Icons.description_outlined,
                              label: localized(
                                ar: '7 وثائق',
                                ku: '7 بەڵگەنامە',
                                en: '7 documents',
                              ),
                            ),
                            if (policyVersion.isNotEmpty)
                              _InfoChip(
                                key: const ValueKey(
                                  'legal_center_version_chip',
                                ),
                                icon: Icons.verified_outlined,
                                label: ProfileStrings.policyVersion(
                                  policyVersion,
                                ),
                              ),
                            _InfoChip(
                              icon: Icons.offline_bolt_outlined,
                              label: localized(
                                ar: 'متاحة دون اتصال',
                                ku: 'بێ ئینتەرنێت بەردەستە',
                                en: 'Available offline',
                              ),
                            ),
                            _InfoChip(
                              icon: Icons.event_available_outlined,
                              label: LegalDocuments.effectiveDateLabel.resolve(
                                languageCode,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localized(
                    ar: 'اختر الوثيقة',
                    ku: 'بەڵگەنامە هەڵبژێرە',
                    en: 'Choose a document',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var index = 0; index < LegalDocuments.all.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Entrance(
                      index: index + 1,
                      child: _LegalDocumentCard(
                        document: LegalDocuments.all[index],
                        languageCode: languageCode,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LegalDocumentScreen(
                              document: LegalDocuments.all[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  localized(
                    ar: 'تشغّل Nawl Ltd تطبيق لقطة داخل العراق. للدعم والاستفسارات: 0773 882 2202',
                    ku: 'Nawl Ltd ئەپی لقطة لە عێراق بەڕێوە دەبات. پشتگیری: 0773 882 2202',
                    en: 'Luqta is operated in Iraq by Nawl Ltd. Support: 0773 882 2202',
                  ),
                  key: const ValueKey('legal_center_footer'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({
    required this.document,
    required this.languageCode,
    required this.onTap,
  });

  final LegalDocument document;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: ValueKey('legal_document_card_${document.id}'),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _iconFor(document.id),
              color: AppColors.goldDark,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title.resolve(languageCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  document.summary.resolve(languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String documentId) {
    return switch (documentId) {
      LegalDocumentIds.terms => Icons.rule_folder_outlined,
      LegalDocumentIds.privacy => Icons.privacy_tip_outlined,
      LegalDocumentIds.orders => Icons.local_shipping_outlined,
      LegalDocumentIds.earnings => Icons.account_balance_wallet_outlined,
      LegalDocumentIds.acceptableUse => Icons.verified_user_outlined,
      LegalDocumentIds.customerNotice => Icons.receipt_long_outlined,
      LegalDocumentIds.accountDeletion => Icons.person_remove_outlined,
      _ => Icons.description_outlined,
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.goldDark),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
