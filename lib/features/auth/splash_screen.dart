import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      if (session.isGuest) {
        Navigator.pushReplacementNamed(context, Routes.shell);
        _refreshPublicDataInBackground();
      } else if (!appBackend.auth.hasSession) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF37379B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF37379B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PositionedDirectional(
              top: -126,
              end: -104,
              child: _BrandOrbit(size: 286, color: Color(0xFFFCC803)),
            ),
            PositionedDirectional(
              bottom: -174,
              start: -152,
              child: _BrandOrbit(
                size: 350,
                color: const Color(0xFFBEB8DA).withValues(alpha: .20),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 24, 28, 34),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    const Entrance(
                      child: LugtaWordmark(height: 86, inverse: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 1,
                      child: Text(
                        AuthStrings.splashTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    if (_startupError == null)
                      const Entrance(index: 2, child: _SplashProgress())
                    else
                      Entrance(
                        index: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(16),
                            child: Column(
                              children: [
                                Text(
                                  AuthStrings.startupFailed,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: .88),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.icon(
                                  key: const Key('startup-retry'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFCC803),
                                    foregroundColor: const Color(0xFF201D12),
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
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandOrbit extends StatelessWidget {
  const _BrandOrbit({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 30),
    ),
  );
}

/// مؤشر تحميل رفيع بأصفر العلامة.
class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        width: 148,
        height: 5,
        child: LinearProgressIndicator(
          backgroundColor: Colors.white.withValues(alpha: .22),
          color: const Color(0xFFFCC803),
        ),
      ),
    );
  }
}
