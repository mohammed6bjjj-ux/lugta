import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/session.dart';
import 'profile_strings.dart';

/// شاشة الدعم — تواصل هاتفي/واتساب + الأسئلة الشائعة.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launch(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final opened = await action();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.contactAppUnavailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ProfileStrings.contactUs)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final faq = session.faq;
          return SessionRefreshIndicator(
            onRefresh: session.refreshPublicData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Entrance(
                          child: _ContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            color: AppColors.info,
                            title: ProfileStrings.phoneCall,
                            detail: session.supportPhone,
                            onTap: () => _launch(
                              context,
                              () => launchPhoneNumber(session.supportPhone),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Entrance(
                          index: 1,
                          child: _ContactCard(
                            icon: Icons.chat_rounded,
                            color: AppColors.success,
                            title: ProfileStrings.whatsapp,
                            detail: session.supportWhatsapp,
                            onTap: () => _launch(
                              context,
                              () => launchWhatsApp(session.supportWhatsapp),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 3,
                  child: SectionHeader(title: ProfileStrings.faqTitle),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < faq.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Entrance(
                      index: 4 + i,
                      child: _FaqCard(
                        question: faq[i].question,
                        answer: faq[i].answer,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          // أيقونة داخل دائرة متدرجة بتوهج ملوّن.
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [color.withValues(alpha: .8), color],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// سؤال شائع داخل AppCard بسهم دوّار (AnimatedRotation).
class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: AppColors.accentStrong,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? .5 : 0,
            duration: AppDurations.base,
            curve: AppCurves.emphasized,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _expanded
                  ? AppColors.accentStrong
                  : AppColors.textSecondary,
            ),
          ),
          title: Text(
            widget.question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Text(
              widget.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
