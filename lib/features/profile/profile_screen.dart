import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/external_actions.dart';
import '../../core/formatters.dart';
import '../../core/request_id.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';
import 'profile_strings.dart';
import 'legal/legal_document_screen.dart';
import 'legal/legal_documents.dart';

bool _cancelDeletionInFlight = false;

Future<void> _openInstagram(BuildContext context, String value) async {
  final opened = await launchInstagramProfile(value);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ProfileStrings.contactAppUnavailable)),
    );
  }
}

/// شاشة «حسابي» — بطاقة المتجر، إحصائيات سريعة، وقوائم الحساب والدعم.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _storeInitials(String storeName) {
    final words = storeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return switch (words) {
      [] => '؟',
      [final first, final second, ...] => '${first[0]} ${second[0]}',
      [final only] => only.length >= 2 ? only.substring(0, 2) : only,
    };
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ProfileStrings.logout),
        content: Text(ProfileStrings.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(ProfileStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await session.signOut();
              } catch (_) {
                // Local account data was still cleared in AppSession.finally.
              }
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (route) => false,
              );
            },
            child: Text(ProfileStrings.logout),
          ),
        ],
      ),
    );
  }

  void _openDeleteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }

  Future<void> _cancelDeletion(BuildContext context) async {
    if (_cancelDeletionInFlight) return;
    _cancelDeletionInFlight = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(ProfileStrings.cancelDeletionRequest),
          content: Text(ProfileStrings.cancelDeletionRequestBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(ProfileStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(ProfileStrings.confirmCancelDeletion),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await session.cancelAccountDeletion();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfileStrings.deletionRequestCancelled)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      _cancelDeletionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CoreStrings.tabProfile)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final seller = session.seller;
          final completedCount = session.orders
              .where((o) => o.status == OrderStatus.completed)
              .length;
          final unread = session.unreadNotificationsCount;

          return SessionRefreshIndicator(
            onRefresh: () =>
                session.reconcileAfterResume(minimumInterval: Duration.zero),
            child: ListView(
              key: const ValueKey('profile_scroll_view'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                120, // حشوة سفلية كي لا يغطي شريط التنقل العائم آخر المحتوى
              ),
              children: [
                Entrance(
                  child: _StoreCard(
                    initials: _storeInitials(seller.storeName),
                    seller: seller,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Entrance(
                        index: 1,
                        child: _StatCard(
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.info,
                          value: session.orders.length,
                          label: ProfileStrings.statTotalOrders,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Entrance(
                        index: 2,
                        child: _StatCard(
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                          value: completedCount,
                          label: ProfileStrings.statCompletedOrders,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Entrance(
                        index: 3,
                        child: _StatCard(
                          icon: Icons.trending_up_rounded,
                          color: AppColors.goldDark,
                          value: session.totalEarned,
                          label: ProfileStrings.statTotalEarnings,
                          format: formatIqd,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 4,
                  child: _MenuGroup(
                    title: CoreStrings.tabProfile,
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: ProfileStrings.editProfile,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.editProfile),
                      ),
                      _MenuItem(
                        key: const ValueKey('profile_notifications_item'),
                        icon: Icons.notifications_none_rounded,
                        title: ProfileStrings.notifications,
                        iconColor: AppColors.info,
                        iconBackground: AppColors.infoSoft,
                        badgeCount: unread,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.notifications),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: ProfileStrings.favorites,
                        iconColor: AppColors.error,
                        iconBackground: AppColors.errorSoft,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.favorites),
                      ),
                      _MenuItem(
                        icon: Icons.payments_outlined,
                        title: ProfileStrings.withdrawalsHistory,
                        iconColor: AppColors.success,
                        iconBackground: AppColors.successSoft,
                        onTap: () => Navigator.pushNamed(
                          context,
                          Routes.withdrawalsHistory,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 5,
                  child: _MenuGroup(
                    title: ProfileStrings.groupSupport,
                    children: [
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        title: ProfileStrings.contactUs,
                        iconColor: AppColors.info,
                        iconBackground: AppColors.infoSoft,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.support),
                      ),
                      _MenuItem(
                        key: const ValueKey('profile_policies_item'),
                        icon: Icons.description_outlined,
                        title: ProfileStrings.policies,
                        iconColor: AppColors.warning,
                        iconBackground: AppColors.warningSoft,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.policies),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        title: ProfileStrings.about,
                        onTap: () => Navigator.pushNamed(context, Routes.about),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        title: ProfileStrings.settings,
                        iconColor: AppColors.textSecondary,
                        iconBackground: AppColors.surfaceAlt,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 6,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    clip: true,
                    child: _MenuItem(
                      icon: Icons.logout_rounded,
                      title: ProfileStrings.logout,
                      iconColor: AppColors.error,
                      iconBackground: AppColors.errorSoft,
                      titleColor: AppColors.error,
                      onTap: () => _confirmLogout(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Entrance(
                  index: 7,
                  child:
                      session.accountDeletionRequest?.status ==
                          AccountDeletionStatus.pending
                      ? AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      ProfileStrings.deletionRequestPending,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: () => _cancelDeletion(context),
                                child: Text(
                                  ProfileStrings.cancelDeletionRequest,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: TextButton(
                            onPressed: () => _openDeleteSheet(context),
                            child: Text(
                              ProfileStrings.deleteAccount,
                              style: TextStyle(
                                color: AppColors.error.withValues(alpha: .55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

// ─────────────────────────── بطاقة المتجر ───────────────────────────

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.initials, required this.seller});

  final String initials;
  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أفاتار بحلقة تدرج ذهبي متوهجة تلف دائرة بيضاء بالحرفين.
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: AppShadows.goldGlow,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Text(
                    initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          seller.storeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // شارة «بائع معتمد» كبسولة بتدرج ذهبي.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            ProfileStrings.verifiedSeller,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      seller.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(icon: Icons.phone_outlined, text: seller.phone),
                    const SizedBox(height: AppSpacing.xs),
                    Pressable(
                      onTap: () => _openInstagram(context, seller.instagramUrl),
                      child: _InfoRow(
                        icon: Icons.camera_alt_outlined,
                        text: seller.instagramUrl,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ProfileStrings.memberSince(formatDate(seller.joinedAt)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // أيقونات اتصال ذهبية صغيرة.
        Icon(icon, size: 15, color: AppColors.goldDark),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── بطاقات الإحصائيات ───────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.format = formatNumber,
  });

  final IconData icon;
  final Color color;
  final num value;
  final String label;
  final String Function(num) format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          // الرقم يُعدّ تصاعدياً عند الدخول.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: AppCurves.emphasized,
            builder: (context, animated, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                format(animated.round()),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── مجموعات القوائم ───────────────────────────

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(indent: 74, endIndent: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.iconBackground,
    this.titleColor,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackground;
  final Color? titleColor;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 21,
                color: iconColor ?? AppColors.goldDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              // شارة إشعارات كبسولة بتدرج ذهبي.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  formatNumber(badgeCount),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            // سهم اتجاهي تلقائي: يشير لنهاية القراءة في RTL وLTR.
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── ورقة حذف الحساب ───────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _confirmed = false;
  bool _loading = false;
  late final String _clientRequestId = newUuidV4();

  @override
  void dispose() {
    _controller.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _confirmed && _reasonController.text.trim().length >= 3 && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await session.requestAccountDeletion(
        _reasonController.text.trim(),
        clientRequestId: _clientRequestId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(ProfileStrings.deleteRequestReceived)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Entrance(
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: .18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 34,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              ProfileStrings.deleteAccountTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ProfileStrings.deleteAccountBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('delete_account_policy_link'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LegalDocumentScreen(
                    document: LegalDocuments.accountDeletion,
                  ),
                ),
              ),
              icon: const Icon(Icons.policy_outlined),
              label: Text(ProfileStrings.readDeletionPolicy),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: ProfileStrings.deleteReasonLabel,
              hint: ProfileStrings.deleteReasonHint,
              controller: _reasonController,
              maxLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              onChanged: (_) => setState(() {}),
              validator: (value) => (value ?? '').trim().length < 3
                  ? ProfileStrings.deleteReasonRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: ProfileStrings.deleteConfirmLabel,
              hint: ProfileStrings.deleteConfirmWord,
              controller: _controller,
              inputFormatters: [LengthLimitingTextInputFormatter(32)],
              onChanged: (v) => setState(
                () => _confirmed = v.trim() == ProfileStrings.deleteConfirmWord,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: ProfileStrings.deleteConfirmSubmit,
              color: AppColors.error,
              loading: _loading,
              onPressed: _canSubmit ? _submit : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: ProfileStrings.deleteCancel,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
