import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/session.dart';
import 'auth_strings.dart';

/// Final state shown after an administrator completes the seller's deletion
/// request. The local and remote sessions are cleared automatically and there
/// is deliberately no status retry action.
class AccountDeletedScreen extends StatefulWidget {
  const AccountDeletedScreen({super.key});

  @override
  State<AccountDeletedScreen> createState() => _AccountDeletedScreenState();
}

class _AccountDeletedScreenState extends State<AccountDeletedScreen> {
  bool _cleared = false;

  @override
  void initState() {
    super.initState();
    _clearSession();
  }

  Future<void> _clearSession() async {
    try {
      await session.signOut();
    } catch (_) {
      // A deleted/disabled Auth identity may already reject token revocation.
    } finally {
      if (mounted) setState(() => _cleared = true);
    }
  }

  void _returnToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.errorSoft,
                      ),
                      child: Icon(
                        Icons.person_off_outlined,
                        size: 44,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AuthStrings.deletedTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AuthStrings.deletedSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: AuthStrings.returnToLogin,
                      icon: Icons.login_rounded,
                      loading: !_cleared,
                      onPressed: _cleared ? _returnToLogin : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
