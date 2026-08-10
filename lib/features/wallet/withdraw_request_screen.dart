import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
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
import '../profile/legal/legal_document_screen.dart';
import '../profile/legal/legal_documents.dart';
import 'payout_account_rules.dart';
import 'wallet_strings.dart';

/// طريقة استلام المبلغ.
///
/// Providers supported by the backend payout contract.
class _PayMethod {
  const _PayMethod({required this.provider, required this.icon});

  final String provider;
  final IconData icon;

  String get name => switch (provider) {
    'zain_cash' => WalletStrings.methodZainCash,
    'superqi' => WalletStrings.methodSuperQi,
    _ => WalletStrings.methodCard,
  };

  String get accountLabel => switch (provider) {
    'zain_cash' => WalletStrings.zainWalletNumberLabel,
    'superqi' => WalletStrings.superQiNumberLabel,
    _ => WalletStrings.cardNumberLabel,
  };

  String get accountHint => switch (provider) {
    'zain_cash' => WalletStrings.zainWalletNumberHint,
    'superqi' => WalletStrings.superQiNumberHint,
    _ => WalletStrings.cardNumberHint,
  };
}

const List<_PayMethod> _methods = [
  _PayMethod(provider: 'zain_cash', icon: Icons.phone_android_rounded),
  _PayMethod(provider: 'superqi', icon: Icons.account_balance_wallet_outlined),
];

/// شاشة طلب سحب رصيد من المحفظة.
class WithdrawRequestScreen extends StatefulWidget {
  const WithdrawRequestScreen({super.key});

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();

  _PayMethod _selectedMethod = _methods.first;
  PayoutAccount? _selectedAccount;
  bool _submitting = false;
  late final String _clientRequestId = newUuidV4();

  @override
  void dispose() {
    _amountController.dispose();
    _holderController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  int get _amount => _parseAmount(_amountController.text);

  static int _parseAmount(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String? _validateAmount(String? value) {
    final amount = _parseAmount(value ?? '');
    if (amount == 0) return WalletStrings.amountRequired;
    if (amount < session.minWithdrawalAmount) {
      return WalletStrings.minWithdrawalError(
        formatIqd(session.minWithdrawalAmount),
      );
    }
    if (amount > session.availableBalance) {
      return WalletStrings.amountExceedsBalance(
        formatIqd(session.availableBalance),
      );
    }
    return null;
  }

  String? _validateAccount(String? value) {
    return validatePayoutAccountIdentifier(
      provider: _selectedMethod.provider,
      value: value ?? '',
    );
  }

  void _fillMaxAmount() {
    _amountController.text = formatNumber(session.availableBalance);
    setState(() {});
  }

  void _selectMethod(_PayMethod method) {
    if (identical(method, _selectedMethod)) return;
    setState(() {
      _selectedMethod = method;
      _selectedAccount = null;
      _holderController.clear();
      _accountController.clear();
    });
  }

  void _selectSavedAccount(PayoutAccount account) {
    final method = _methods.firstWhere(
      (item) => item.provider == account.provider,
      orElse: () => _methods.last,
    );
    setState(() {
      _selectedAccount = account;
      _selectedMethod = method;
      _holderController.text = account.accountHolderName;
      _accountController.text = account.accountIdentifier;
    });
  }

  Future<void> _managePayoutAccounts() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PayoutAccountsSheet(
        onSelect: (account) {
          Navigator.pop(sheetContext);
          _selectSavedAccount(account);
        },
        onDeleted: (accountId) {
          if (_selectedAccount?.id == accountId && mounted) {
            setState(() {
              _selectedAccount = null;
              _holderController.clear();
              _accountController.clear();
            });
          }
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = _amount;
    late String methodName;
    late String accountDetail;
    late Withdrawal submittedWithdrawal;

    setState(() => _submitting = true);
    try {
      // Balance and verification can change while this screen is open. Read a
      // fresh snapshot immediately before the financial mutation.
      await session.refreshWallet();
      if (!mounted) return;
      final selectedId = _selectedAccount?.id;
      if (selectedId != null) {
        PayoutAccount? latestAccount;
        for (final account in session.payoutAccounts) {
          if (account.id == selectedId) {
            latestAccount = account;
            break;
          }
        }
        if (latestAccount == null) {
          setState(() {
            _submitting = false;
            _selectedAccount = null;
            _holderController.clear();
            _accountController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(WalletStrings.payoutAccountUnavailable)),
          );
          return;
        }
        _selectedAccount = latestAccount;
        _selectedMethod = _methods.firstWhere(
          (item) => item.provider == latestAccount!.provider,
          orElse: () => _methods.last,
        );
        _holderController.text = latestAccount.accountHolderName;
        _accountController.text = latestAccount.accountIdentifier;
      }
      if (!(_formKey.currentState?.validate() ?? false)) {
        setState(() => _submitting = false);
        return;
      }
      methodName = _selectedMethod.name;
      accountDetail = _accountController.text.trim();

      var payoutAccount = _selectedAccount;
      if (payoutAccount == null) {
        payoutAccount = await session.savePayoutAccount(
          provider: _selectedMethod.provider,
          accountHolderName: _holderController.text.trim(),
          accountIdentifier: accountDetail,
          makeDefault: session.payoutAccounts.isEmpty,
        );
        if (mounted) setState(() => _selectedAccount = payoutAccount);
      }
      if (!payoutAccount.isVerified) {
        if (mounted) setState(() => _submitting = false);
        if (!mounted) return;
        await _showVerificationPending();
        return;
      }
      submittedWithdrawal = await session.requestWithdrawal(
        clientRequestId: _clientRequestId,
        amount: amount,
        method: methodName,
        accountDetail: accountDetail,
        payoutAccountId: payoutAccount.id,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة نجاح داخل دائرة ناعمة بدخول نابض.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .5, end: 1),
              duration: AppDurations.slow,
              curve: AppCurves.spring,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 34,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              WalletStrings.requestReceivedTitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          WalletStrings.requestReceivedBody(
            formatIqd(amount),
            methodName,
            fee: formatIqd(submittedWithdrawal.transferFee),
            netAmount: formatIqd(submittedWithdrawal.netAmount),
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          PrimaryButton(
            label: WalletStrings.ok,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showVerificationPending() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(WalletStrings.payoutVerificationPendingTitle),
      content: Text(WalletStrings.payoutVerificationPendingBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(WalletStrings.ok),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(WalletStrings.withdrawRequest),
        actions: [SessionRefreshButton(onRefresh: session.refreshWallet)],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          return SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const Entrance(child: _AvailableBalanceCard()),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 1,
                    child: AppTextField(
                      fieldKey: const ValueKey('withdrawal_amount_field'),
                      label: WalletStrings.amountLabel,
                      controller: _amountController,
                      hint: WalletStrings.amountExample(
                        formatNumber(session.minWithdrawalAmount),
                      ),
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.payments_outlined,
                      inputFormatters: const [_ThousandsInputFormatter()],
                      validator: _validateAmount,
                      onChanged: (_) => setState(() {}),
                      suffix: TextButton(
                        onPressed: _fillMaxAmount,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(WalletStrings.withdrawAll),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    WalletStrings.minWithdrawal(
                      formatIqd(session.minWithdrawalAmount),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (session.payoutAccounts.isNotEmpty) ...[
                    Entrance(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            WalletStrings.savedPayoutAccounts,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final account in session.payoutAccounts)
                                ChoiceChip(
                                  selected: _selectedAccount?.id == account.id,
                                  label: Text(
                                    '${account.providerLabel} •••• '
                                    '${account.identifierLast4}'
                                    '${account.isVerified ? '' : ' • ${WalletStrings.awaitingVerification}'}',
                                  ),
                                  avatar: Icon(
                                    account.isVerified
                                        ? Icons.verified_rounded
                                        : Icons.account_balance_wallet_outlined,
                                    size: 18,
                                  ),
                                  onSelected: (_) =>
                                      _selectSavedAccount(account),
                                ),
                              ChoiceChip(
                                selected: _selectedAccount == null,
                                label: Text(WalletStrings.useNewPayoutAccount),
                                onSelected: (_) => setState(() {
                                  _selectedAccount = null;
                                  _holderController.clear();
                                  _accountController.clear();
                                }),
                              ),
                            ],
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: _managePayoutAccounts,
                              icon: const Icon(Icons.settings_outlined),
                              label: Text(WalletStrings.managePayoutAccounts),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Entrance(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          WalletStrings.receiveMethod,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        Row(
                          children: [
                            for (final method in _methods) ...[
                              Expanded(
                                child: _MethodCard(
                                  method: method,
                                  selected: identical(method, _selectedMethod),
                                  onTap: () => _selectMethod(method),
                                ),
                              ),
                              if (!identical(method, _methods.last))
                                const SizedBox(width: AppSpacing.sm + 4),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_selectedAccount == null) ...[
                    Entrance(
                      index: 4,
                      child: AppTextField(
                        fieldKey: const ValueKey(
                          'withdrawal_account_holder_field',
                        ),
                        label: WalletStrings.accountHolderRegisteredName,
                        controller: _holderController,
                        hint: WalletStrings.accountHolderHint,
                        prefixIcon: Icons.badge_outlined,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(160),
                        ],
                        validator: (value) => (value ?? '').trim().length < 3
                            ? WalletStrings.accountHolderRequired
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Entrance(
                    index: 5,
                    child: AppTextField(
                      fieldKey: const ValueKey('withdrawal_account_field'),
                      label: _selectedMethod.accountLabel,
                      controller: _accountController,
                      hint: _selectedMethod.accountHint,
                      keyboardType: TextInputType.number,
                      prefixIcon: _selectedMethod.icon,
                      inputFormatters: payoutAccountInputFormatters(
                        _selectedMethod.provider,
                      ),
                      validator: _validateAccount,
                      onChanged: (_) => setState(() => _selectedAccount = null),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 6,
                    child: _SummaryCard(
                      amount: _amount,
                      method: _selectedMethod,
                      accountDetail: _accountController.text.trim(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 7,
                    child: AppCard(
                      color: AppColors.infoSoft,
                      shadows: const [],
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.policy_outlined, color: AppColors.info),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  WalletStrings.withdrawalPolicyNotice,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.7,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                TextButton(
                                  key: const ValueKey('withdrawal_policy_link'),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => LegalDocumentScreen(
                                        document: LegalDocuments.earnings,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    WalletStrings.readWithdrawalPolicy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 8,
                    child: PrimaryButton(
                      label: WalletStrings.submitWithdrawRequest,
                      icon: Icons.send_rounded,
                      accented: true,
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PayoutAccountsSheet extends StatefulWidget {
  const _PayoutAccountsSheet({required this.onSelect, required this.onDeleted});

  final ValueChanged<PayoutAccount> onSelect;
  final ValueChanged<String> onDeleted;

  @override
  State<_PayoutAccountsSheet> createState() => _PayoutAccountsSheetState();
}

class _PayoutAccountsSheetState extends State<_PayoutAccountsSheet> {
  String? _busyAccountId;

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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      widget.onDeleted(account.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyAccountId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                WalletStrings.managePayoutAccounts,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                WalletStrings.managePayoutAccountsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (session.payoutAccounts.isEmpty)
                Text(WalletStrings.noSavedPayoutAccounts)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: session.payoutAccounts.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final account = session.payoutAccounts[index];
                      final busy = _busyAccountId == account.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: busy ? null : () => widget.onSelect(account),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentSoft,
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.accentStrong,
                          ),
                        ),
                        title: Text(
                          '${account.providerLabel} •••• '
                          '${account.identifierLast4}',
                        ),
                        subtitle: Text(
                          !account.isVerified
                              ? WalletStrings.awaitingVerification
                              : account.isDefault
                              ? WalletStrings.defaultPayoutAccount
                              : account.accountHolderName,
                        ),
                        trailing: busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'default') {
                                    _makeDefault(account);
                                  } else if (value == 'delete') {
                                    _delete(account);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!account.isDefault)
                                    PopupMenuItem(
                                      value: 'default',
                                      child: Text(
                                        WalletStrings.makePayoutDefault,
                                      ),
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة الرصيد المتاح أعلى الشاشة — تدرج داكن مصغر بزخرفة ذهبية.
class _AvailableBalanceCard extends StatelessWidget {
  const _AvailableBalanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      gradient: AppColors.darkGradient,
      shadows: AppShadows.floating,
      clip: true,
      child: Stack(
        children: [
          PositionedDirectional(
            top: -44,
            end: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: .10),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -50,
            start: -34,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: .07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WalletStrings.availableBalance,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          formatIqd(session.availableBalance),
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 26,
                    color: AppColors.accent.withValues(alpha: .95),
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

/// بطاقة اختيار طريقة الدفع — المختارة بحد ذهبي متوهج وعلامة صح نابضة.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.base,
        curve: AppCurves.emphasized,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: selected ? AppShadows.accentGlow : AppShadows.card,
        ),
        child: Column(
          children: [
            Icon(
              method.icon,
              size: 26,
              color: selected
                  ? AppColors.accentStrong
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              method.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppColors.accentStrong
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppDurations.base,
              switchInCurve: AppCurves.spring,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: selected
                  ? Container(
                      key: const ValueKey('selected'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      key: const ValueKey('unselected'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.divider,
                          width: 1.6,
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

/// ملخص صغير قبل إرسال الطلب.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.amount,
    required this.method,
    required this.accountDetail,
  });

  final int amount;
  final _PayMethod method;
  final String accountDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validAmount =
        amount > 0 &&
        amount >= session.minWithdrawalAmount &&
        amount <= session.availableBalance;
    final transferFee = session.withdrawalFeeFor(method.provider);
    final netAmount = amount > transferFee ? amount - transferFee : 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  size: 16,
                  color: AppColors.accentStrong,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  WalletStrings.requestSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          _row(
            context,
            WalletStrings.amount,
            amount > 0 ? formatIqd(amount) : '—',
          ),
          _row(
            context,
            WalletStrings.transferFee,
            amount > 0 ? formatIqd(transferFee) : '—',
          ),
          _row(
            context,
            WalletStrings.netPayout,
            amount > 0 ? formatIqd(netAmount) : '—',
            bold: true,
          ),
          _row(context, WalletStrings.receiveMethod, method.name),
          _row(
            context,
            method.accountLabel,
            accountDetail.isEmpty ? '—' : accountDetail,
            ltrValue: accountDetail.isNotEmpty,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _row(
            context,
            WalletStrings.balanceAfterWithdrawal,
            validAmount ? formatIqd(session.availableBalance - amount) : '—',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool ltrValue = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ltrValue ? TextDirection.ltr : null,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// منسّق إدخال يعرض المبلغ بفواصل الآلاف أثناء الكتابة.
class _ThousandsInputFormatter extends TextInputFormatter {
  const _ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (digits.length > 9) digits = digits.substring(0, 9);
    final formatted = formatNumber(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
