import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_refresh.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import 'payout_account_rules.dart';
import 'wallet_strings.dart';

typedef SavePayoutAccountCallback =
    Future<PayoutAccount> Function({
      required String provider,
      required String accountHolderName,
      required String accountIdentifier,
      required bool makeDefault,
    });

class PayoutAccountsScreen extends StatefulWidget {
  const PayoutAccountsScreen({super.key});

  @override
  State<PayoutAccountsScreen> createState() => _PayoutAccountsScreenState();
}

class _PayoutAccountsScreenState extends State<PayoutAccountsScreen> {
  String? _busyAccountId;
  bool _editorOpen = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(silent: true));
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      await session.refreshWallet();
    } catch (error) {
      if (!silent && mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _openEditor([PayoutAccount? account]) async {
    if (_editorOpen) return;
    _editorOpen = true;
    PayoutAccount? saved;
    try {
      saved = await showModalBottomSheet<PayoutAccount>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => PayoutAccountEditorSheet(
          account: account,
          makeDefaultInitially:
              account?.isDefault ?? session.payoutAccounts.isEmpty,
          onSave:
              ({
                required provider,
                required accountHolderName,
                required accountIdentifier,
                required makeDefault,
              }) => session.savePayoutAccount(
                accountId: account?.id,
                provider: provider,
                accountHolderName: accountHolderName,
                accountIdentifier: accountIdentifier,
                makeDefault: makeDefault,
              ),
        ),
      );
    } finally {
      _editorOpen = false;
    }
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved.isVerified
              ? WalletStrings.payoutAccountUpdated
              : WalletStrings.payoutAccountSavedPending,
        ),
      ),
    );
  }

  Future<void> _makeDefault(PayoutAccount account) async {
    if (_busyAccountId != null) return;
    setState(() => _busyAccountId = account.id);
    try {
      await session.savePayoutAccount(
        accountId: account.id,
        provider: account.provider,
        accountHolderName: account.accountHolderName,
        accountIdentifier: account.accountIdentifier,
        makeDefault: true,
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyAccountId = null);
    }
  }

  Future<void> _delete(PayoutAccount account) async {
    if (_busyAccountId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(WalletStrings.deletePayoutAccount),
        content: Text(WalletStrings.deletePayoutAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(WalletStrings.keepAccount),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              WalletStrings.deletePayoutAccount,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyAccountId = account.id);
    try {
      await session.deletePayoutAccount(account.id);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyAccountId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(WalletStrings.managePayoutAccounts),
        actions: [SessionRefreshButton(onRefresh: _refresh)],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final accounts = session.payoutAccounts;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Entrance(child: const _VerificationNotice()),
              const SizedBox(height: AppSpacing.lg),
              if (accounts.isEmpty)
                Entrance(index: 1, child: const _EmptyPayoutAccounts())
              else
                for (final (index, account) in accounts.indexed) ...[
                  Entrance(
                    index: index + 1,
                    child: _PayoutAccountCard(
                      account: account,
                      busy: _busyAccountId == account.id,
                      onEdit:
                          account.provider == 'zain_cash' ||
                              account.provider == 'superqi'
                          ? () => _openEditor(account)
                          : null,
                      onMakeDefault: account.isDefault
                          ? null
                          : () => _makeDefault(account),
                      onDelete: () => _delete(account),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              const SizedBox(height: AppSpacing.sm),
              Entrance(
                index: accounts.length + 2,
                child: PrimaryButton(
                  label: WalletStrings.addPayoutAccount,
                  icon: Icons.add_card_rounded,
                  accented: true,
                  onPressed: _openEditor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.accentSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.accentStrong),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WalletStrings.payoutAccountsSettingsSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  WalletStrings.payoutVerificationInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPayoutAccounts extends StatelessWidget {
  const _EmptyPayoutAccounts();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.textSecondary,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              WalletStrings.noPayoutAccountsTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              WalletStrings.noPayoutAccountsBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayoutAccountCard extends StatelessWidget {
  const _PayoutAccountCard({
    required this.account,
    required this.busy,
    required this.onEdit,
    required this.onMakeDefault,
    required this.onDelete,
  });

  final PayoutAccount account;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onMakeDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final verified = account.isVerified;
    return AppCard(
      onTap: busy ? null : onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: verified
                      ? AppColors.successSoft
                      : AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verified ? Icons.verified_rounded : Icons.schedule_rounded,
                  color: verified ? AppColors.success : AppColors.accentStrong,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.providerLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '•••• ${account.identifierLast4}',
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'default') onMakeDefault?.call();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(WalletStrings.editPayoutAccount),
                      ),
                    if (onMakeDefault != null)
                      PopupMenuItem(
                        value: 'default',
                        child: Text(WalletStrings.makePayoutDefault),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        WalletStrings.deletePayoutAccount,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            WalletStrings.accountHolderRegisteredName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            account.accountHolderName,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _AccountBadge(
                label: verified
                    ? WalletStrings.verifiedPayoutAccount
                    : WalletStrings.awaitingVerification,
                color: verified ? AppColors.success : AppColors.accentStrong,
                background: verified
                    ? AppColors.successSoft
                    : AppColors.accentSoft,
              ),
              if (account.isDefault)
                _AccountBadge(
                  label: WalletStrings.defaultPayoutAccount,
                  color: AppColors.textPrimary,
                  background: AppColors.surfaceAlt,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PayoutAccountEditorSheet extends StatefulWidget {
  const PayoutAccountEditorSheet({
    super.key,
    required this.onSave,
    this.account,
    this.makeDefaultInitially = false,
  });

  final PayoutAccount? account;
  final bool makeDefaultInitially;
  final SavePayoutAccountCallback onSave;

  @override
  State<PayoutAccountEditorSheet> createState() =>
      _PayoutAccountEditorSheetState();
}

class _PayoutAccountEditorSheetState extends State<PayoutAccountEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holderController;
  late final TextEditingController _identifierController;
  late String _provider;
  late bool _makeDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.account?.provider == 'superqi' ? 'superqi' : 'zain_cash';
    _holderController = TextEditingController(
      text: widget.account?.accountHolderName ?? '',
    );
    _identifierController = TextEditingController(
      text: widget.account?.accountIdentifier ?? '',
    );
    _makeDefault = widget.makeDefaultInitially;
  }

  @override
  void dispose() {
    _holderController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  void _selectProvider(String provider) {
    if (_provider == provider) return;
    setState(() {
      _provider = provider;
      _identifierController.clear();
    });
  }

  String? _validateHolder(String? value) {
    if ((value ?? '').trim().length < 3) {
      return WalletStrings.accountHolderRequired;
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final account = await widget.onSave(
        provider: _provider,
        accountHolderName: _holderController.text.trim(),
        accountIdentifier: _identifierController.text.trim(),
        makeDefault: _makeDefault,
      );
      if (mounted) Navigator.pop(context, account);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editingVerified = widget.account?.isVerified ?? false;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.account == null
                    ? WalletStrings.addPayoutAccount
                    : WalletStrings.editPayoutAccount,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                WalletStrings.payoutAccountsSettingsSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                WalletStrings.payoutProvider,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      key: const ValueKey('payout_provider_zain_cash'),
                      selected: _provider == 'zain_cash',
                      avatar: const Icon(Icons.phone_android_rounded, size: 18),
                      label: Text(WalletStrings.methodZainCash),
                      onSelected: (_) => _selectProvider('zain_cash'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      key: const ValueKey('payout_provider_superqi'),
                      selected: _provider == 'superqi',
                      avatar: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                      ),
                      label: Text(WalletStrings.methodSuperQi),
                      onSelected: (_) => _selectProvider('superqi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                fieldKey: const ValueKey('payout_account_holder_field'),
                label: WalletStrings.accountHolderRegisteredName,
                controller: _holderController,
                hint: WalletStrings.accountHolderHint,
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(160)],
                validator: _validateHolder,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const ValueKey('payout_account_identifier_field'),
                label: _provider == 'zain_cash'
                    ? WalletStrings.zainWalletNumberLabel
                    : WalletStrings.superQiNumberLabel,
                controller: _identifierController,
                hint: _provider == 'zain_cash'
                    ? WalletStrings.zainWalletNumberHint
                    : WalletStrings.superQiNumberHint,
                keyboardType: TextInputType.number,
                prefixIcon: _provider == 'zain_cash'
                    ? Icons.phone_android_rounded
                    : Icons.account_balance_wallet_outlined,
                inputFormatters: payoutAccountInputFormatters(_provider),
                validator: (value) => validatePayoutAccountIdentifier(
                  provider: _provider,
                  value: value ?? '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _makeDefault,
                onChanged: (value) => setState(() => _makeDefault = value),
                title: Text(
                  WalletStrings.defaultPayoutAccount,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (editingVerified) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          WalletStrings.payoutEditVerificationWarning,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                key: const ValueKey('save_payout_account_button'),
                label: widget.account == null
                    ? WalletStrings.savePayoutAccount
                    : WalletStrings.savePayoutAccountChanges,
                icon: Icons.verified_user_outlined,
                accented: true,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
