import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import 'legal_document.dart';
import 'legal_documents.dart';

/// قارئ وثيقة قانونية واحدة.
///
/// تعتمد الشاشة [SliverList] حتى لا تُبنى الأقسام الطويلة إلا عند اقترابها
/// من مساحة العرض. المتن القانوني عربي دائماً وقابل للتحديد والنسخ.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  LegalDocumentScreen.fromId({super.key, required String documentId})
    : document = LegalDocuments.byId(documentId);

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = document.title.resolve(languageCode);
    final summary = document.summary.resolve(languageCode);

    return Scaffold(
      key: ValueKey('legal_document_screen_${document.id}'),
      appBar: AppBar(title: Text(title)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          key: ValueKey('legal_document_scroll_${document.id}'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: _DocumentHeader(
                  documentId: document.id,
                  title: title,
                  summary: summary,
                  effectiveDate: LegalDocuments.effectiveDateLabel.resolve(
                    languageCode,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                key: ValueKey('legal_document_sections_${document.id}'),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = document.sections[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        key: ValueKey('legal_section_${document.id}_$index'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 24,
                                  margin: const EdgeInsets.only(
                                    left: AppSpacing.sm,
                                    top: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    section.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.45,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Divider(height: 1, color: AppColors.divider),
                            const SizedBox(height: AppSpacing.md),
                            SelectableText(
                              section.body,
                              key: ValueKey(
                                'legal_section_body_${document.id}_$index',
                              ),
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: document.sections.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  addSemanticIndexes: true,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'للدعم والاستفسارات: 0773 882 2202',
                  key: ValueKey('legal_document_contact_${document.id}'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.documentId,
    required this.title,
    required this.summary,
    required this.effectiveDate,
  });

  final String documentId;
  final String title;
  final String summary;
  final String effectiveDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: ValueKey('legal_document_header_$documentId'),
      color: AppColors.accentSoft,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'وثيقة قانونية',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.accentStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'النص القانوني المعتمد معروض باللغة العربية.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            effectiveDate,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.accentStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
