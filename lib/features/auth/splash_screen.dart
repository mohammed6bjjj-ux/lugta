import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entrance.dart';
import '../../data/backend.dart';
import '../../data/session.dart';
import 'auth_navigation.dart';
import 'auth_strings.dart';

/// شاشة البداية الرسمية للعلامة، ثم انتقال تلقائي بعد تجهيز الجلسة.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.bootstrap});

  final Future<void> Function()? bootstrap;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumDisplayTime = Duration(milliseconds: 450);
  static const _profileTimeout = Duration(seconds: 10);

  bool _starting = false;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    if (mounted) setState(() => _startupError = null);
    final minimumDelay = Future<void>.delayed(_minimumDisplayTime);

    try {
      await (widget.bootstrap?.call() ?? Future<void>.value());
      // Verifying a recovery OTP creates a genuine Supabase Auth session. If
      // the app was killed before the password was changed (or the flow was
      // otherwise abandoned), the durable recovery gate prevents that
      // temporary session from becoming a normal signed-in app session.
      await appBackend.auth.abandonPasswordRecovery();
      if (appBackend.auth.hasSession) {
        await (() async {
          await appBackend.auth.completePendingRegistration();
          if (session.seller.id.isEmpty) {
            await session.refreshCurrentProfile();
          }
        })().timeout(_profileTimeout);
      }
      await minimumDelay;
      if (!mounted) return;
      if (!appBackend.auth.hasSession) {
        Navigator.pushReplacementNamed(context, Routes.onboarding);
        _refreshPublicDataInBackground();
      } else {
        openAuthenticatedDestination(context);
        _refreshSignedInDataInBackground();
      }
    } catch (error) {
      await minimumDelay;
      if (!mounted) return;
      setState(() => _startupError = error);
    } finally {
      _starting = false;
    }
  }

  void _refreshPublicDataInBackground() {
    unawaited(() async {
      try {
        await session.refreshPublicData();
      } catch (_) {
        // The destination stays usable and its refresh action can retry.
      }
    }());
  }

  void _refreshSignedInDataInBackground() {
    unawaited(() async {
      try {
        await Future.wait<void>([
          session.refreshPublicData(),
          session.refreshAuthenticatedData(refreshProfile: false),
        ]);
      } catch (_) {
        // Individual screens expose the shared refresh action on failure.
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF191713),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF191713)),
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                const Entrance(child: LugtaWordmark(height: 74, inverse: true)),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      AuthStrings.splashTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFFAF6ED),
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                if (_startupError == null)
                  const Entrance(index: 2, child: _SplashProgress())
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Text(
                          AuthStrings.startupFailed,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(
                              0xFFFAF6ED,
                            ).withValues(alpha: .72),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          key: const Key('startup-retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1B9E6A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _starting
                              ? null
                              : () => unawaited(_start()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AuthStrings.retryStartup),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// مؤشر تحميل رفيع بلون أخضر العلامة.
class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: const SizedBox(
        width: 132,
        height: 4,
        child: LinearProgressIndicator(
          backgroundColor: Color(0x33FAF6ED),
          color: Color(0xFF1B9E6A),
        ),
      ),
    );
  }
}
