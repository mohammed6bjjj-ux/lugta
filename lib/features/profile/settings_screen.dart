import 'package:flutter/material.dart';

import '../../app/app_metadata.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../core/network_image_cache.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/app_settings.dart';
import '../../data/session.dart';
import 'profile_strings.dart';
import 'sales_analytics_strings.dart';
import 'settings_mutation_queue.dart';

/// شاشة الإعدادات — المظهر، اللغة، مفاتيح الإشعارات، وخيارات عامة.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _ordersNotifications;
  late bool _walletNotifications;
  late bool _newProductsNotifications;
  late bool _offersNotifications;
  late SettingsMutationQueue _mutations;
  late String _ownerId;

  @override
  void initState() {
    super.initState();
    _ownerId = session.seller.id;
    _syncNotificationPreferences();
    _mutations = SettingsMutationQueue(
      initial: _currentSnapshot,
      persist: _persistSnapshot,
    );
    session.addListener(_handleSessionChange);
  }

  @override
  void dispose() {
    session.removeListener(_handleSessionChange);
    _mutations.dispose();
    super.dispose();
  }

  void _syncNotificationPreferences() {
    final preferences = session.seller.notificationPreferences;
    _ordersNotifications = preferences['orders'] ?? true;
    _walletNotifications = preferences['wallet'] ?? true;
    _newProductsNotifications = preferences['products'] ?? true;
    _offersNotifications = preferences['system'] ?? true;
  }

  Future<void> _refresh() async {
    await _mutations.settled;
    await session.refreshAllData();
    if (!mounted) return;
    setState(_syncNotificationPreferences);
    _mutations.reset(_currentSnapshot);
  }

  Map<String, bool> get _notificationPreferences => {
    'orders': _ordersNotifications,
    'wallet': _walletNotifications,
    'products': _newProductsNotifications,
    'system': _offersNotifications,
  };

  SettingsSnapshot get _currentSnapshot => SettingsSnapshot(
    locale: appSettings.language.name,
    notificationPreferences: _notificationPreferences,
  );

  Future<SettingsSnapshot> _persistSnapshot(SettingsSnapshot snapshot) async {
    await session.updateSettings(
      locale: snapshot.locale,
      notificationPreferences: snapshot.notificationPreferences,
    );
    final seller = session.seller;
    return SettingsSnapshot(
      locale: seller.locale,
      notificationPreferences: seller.notificationPreferences,
    );
  }

  void _handleSessionChange() {
    final nextOwnerId = session.seller.id;
    if (nextOwnerId == _ownerId) {
      if (_mutations.hasPending) return;
      _syncNotificationPreferences();
      _mutations.reset(_currentSnapshot);
      if (mounted) setState(() {});
      return;
    }
    _ownerId = nextOwnerId;
    if (nextOwnerId.isNotEmpty) {
      final language = AppLanguage.values.firstWhere(
        (value) => value.name == session.seller.locale,
        orElse: () => appSettings.language,
      );
      appSettings.setLanguage(language);
    }
    _syncNotificationPreferences();
    _mutations.reset(_currentSnapshot);
    if (mounted) setState(() {});
  }

  Future<void> _setNotificationPreference(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'orders':
          _ordersNotifications = value;
        case 'wallet':
          _walletNotifications = value;
        case 'products':
          _newProductsNotifications = value;
        case 'system':
          _offersNotifications = value;
      }
    });
    final result = await _mutations.setNotification(key, value);
    if (!mounted || result.ignored || result.succeeded) return;
    if (result.shouldRollback) {
      setState(() {
        final confirmed = result.confirmed.notificationPreferences[key] ?? true;
        switch (key) {
          case 'orders':
            _ordersNotifications = confirmed;
          case 'wallet':
            _walletNotifications = confirmed;
          case 'products':
            _newProductsNotifications = confirmed;
          case 'system':
            _offersNotifications = confirmed;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error.toString())));
    }
  }

  Future<void> _setLanguage(AppLanguage language) async {
    if (language == appSettings.language) return;
    final result = await _mutations.setLocale(language.name);
    if (!mounted || result.ignored) return;
    if (result.succeeded) {
      if (result.isLatest) appSettings.setLanguage(language);
      return;
    }
    if (result.shouldRollback) {
      final confirmedLanguage = AppLanguage.values.firstWhere(
        (value) => value.name == result.confirmed.locale,
        orElse: () => AppLanguage.ar,
      );
      appSettings.setLanguage(confirmedLanguage);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error.toString())));
    }
  }

  Future<void> _clearCache() async {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ProfileStrings.cacheCleared)));
    try {
      await Future.wait<void>([
        appNetworkImageCacheManager.emptyCache(),
        session.clearCatalogSnapshotCache(),
      ]);
    } catch (_) {
      // The in-memory cache is already cleared. Platform disk cleanup remains
      // best-effort on web/tests where no persistent cache backend may exist.
    }
  }

  /// مفتاح بستايل حديث: مسار ذهبي عند التفعيل وأيقونة داخل دائرة ناعمة.
  Widget _settingSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.surfaceAlt,
      secondary: _SettingIcon(icon: icon, active: value),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder كي تتحدث الشاشة فوراً عند تغيير اللغة أو المظهر.
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(ProfileStrings.settings),
            actions: [SessionRefreshButton(onRefresh: _refresh)],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Entrance(child: _GroupTitle(ProfileStrings.sectionPayments)),
              Entrance(
                index: 1,
                child: _GroupCard(
                  children: [
                    ListTile(
                      key: const ValueKey('sales_analytics_settings_tile'),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.salesAnalytics),
                      leading: const _SettingIcon(
                        icon: Icons.query_stats_rounded,
                        active: true,
                      ),
                      title: Text(
                        SalesAnalyticsStrings.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(SalesAnalyticsStrings.settingsSubtitle),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ListTile(
                      key: const ValueKey('payout_accounts_settings_tile'),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.payoutAccounts),
                      leading: const _SettingIcon(
                        icon: Icons.account_balance_wallet_outlined,
                        active: true,
                      ),
                      title: Text(
                        ProfileStrings.payoutAccounts,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(ProfileStrings.payoutAccountsSubtitle),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 2,
                child: _GroupTitle(ProfileStrings.sectionAppearance),
              ),
              Entrance(
                index: 3,
                child: _GroupCard(
                  children: [
                    _settingSwitch(
                      value: appSettings.darkMode,
                      onChanged: appSettings.setDarkMode,
                      icon: Icons.dark_mode_outlined,
                      title: ProfileStrings.darkMode,
                      subtitle: ProfileStrings.darkModeSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 4,
                child: _GroupTitle(ProfileStrings.sectionLanguage),
              ),
              Entrance(
                index: 5,
                child: _GroupCard(
                  children: [
                    for (final language in AppLanguage.values)
                      _LanguageTile(
                        language: language,
                        selected: appSettings.language == language,
                        onTap: () => _setLanguage(language),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 6,
                child: _GroupTitle(ProfileStrings.notifications),
              ),
              Entrance(
                index: 7,
                child: _GroupCard(
                  children: [
                    _settingSwitch(
                      value: _ordersNotifications,
                      onChanged: (v) => _setNotificationPreference('orders', v),
                      icon: Icons.receipt_long_outlined,
                      title: ProfileStrings.ordersNotifTitle,
                      subtitle: ProfileStrings.ordersNotifSubtitle,
                    ),
                    _settingSwitch(
                      value: _walletNotifications,
                      onChanged: (v) => _setNotificationPreference('wallet', v),
                      icon: Icons.account_balance_wallet_outlined,
                      title: ProfileStrings.walletNotifTitle,
                      subtitle: ProfileStrings.walletNotifSubtitle,
                    ),
                    _settingSwitch(
                      value: _newProductsNotifications,
                      onChanged: (v) =>
                          _setNotificationPreference('products', v),
                      icon: Icons.watch_outlined,
                      title: ProfileStrings.newProductsNotifTitle,
                      subtitle: ProfileStrings.newProductsNotifSubtitle,
                    ),
                    _settingSwitch(
                      value: _offersNotifications,
                      onChanged: (v) => _setNotificationPreference('system', v),
                      icon: Icons.local_offer_outlined,
                      title: ProfileStrings.offersNotifTitle,
                      subtitle: ProfileStrings.offersNotifSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Entrance(
                index: 8,
                child: _GroupTitle(ProfileStrings.sectionGeneral),
              ),
              Entrance(
                index: 9,
                child: _GroupCard(
                  children: [
                    ListTile(
                      onTap: _clearCache,
                      leading: const _SettingIcon(
                        icon: Icons.cleaning_services_outlined,
                        active: true,
                      ),
                      title: Text(
                        ProfileStrings.clearCache,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(ProfileStrings.clearCacheSubtitle),
                      // سهم اتجاهي تلقائي يشير لنهاية القراءة في RTL وLTR.
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ListTile(
                      leading: const _SettingIcon(
                        icon: Icons.info_outline_rounded,
                        active: true,
                      ),
                      title: Text(
                        ProfileStrings.version,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Text(
                        AppMetadata.version,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// خيار لغة مفعّل — الاختيار يبدّل لغة التطبيق فوراً.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  String get _badge => switch (language) {
    AppLanguage.ar => 'ع',
    AppLanguage.ckb => 'ک',
    AppLanguage.en => 'EN',
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _LangBadge(_badge, muted: !selected),
      title: Text(
        language.nativeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: selected ? null : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppColors.accentStrong)
          : Icon(
              Icons.circle_outlined,
              color: AppColors.textSecondary.withValues(alpha: .35),
            ),
    );
  }
}

/// أيقونة إعداد داخل دائرة ناعمة — تتلوّن ذهبياً عند التفعيل.
class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.emphasized,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? AppColors.accentSoft : AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: active ? AppColors.accentStrong : AppColors.textSecondary,
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge(this.label, {this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted ? AppColors.neutralChip : AppColors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: muted ? AppColors.textSecondary : AppColors.accentStrong,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
