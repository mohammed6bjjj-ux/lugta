import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_strings.dart';

/// شاشات التعريف — 3 شرائح تشرح فكرة المنصة مع مؤشر نقاط وزر تخطٍّ.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static List<_OnboardSlide> get _slides => [
    _OnboardSlide(
      icon: Icons.storefront_outlined,
      title: AuthStrings.onboardTitle1,
      body: AuthStrings.onboardBody1,
    ),
    _OnboardSlide(
      icon: Icons.campaign_outlined,
      title: AuthStrings.onboardTitle2,
      body: AuthStrings.onboardBody2,
    ),
    _OnboardSlide(
      icon: Icons.payments_outlined,
      title: AuthStrings.onboardTitle3,
      body: AuthStrings.onboardBody3,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLast() {
    _controller.animateToPage(
      _slides.length - 1,
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
    );
  }

  void _next() {
    _controller.nextPage(
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              // زر تخطٍّ — يقفز إلى الشريحة الأخيرة.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: AppDurations.fast,
                    child: TextButton(
                      onPressed: _isLast ? null : _goToLast,
                      child: Text(AuthStrings.skip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              // مؤشر النقاط — المختارة تتوسع إلى كبسولة ذهبية متدرجة.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: AppDurations.base,
                      curve: AppCurves.emphasized,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? null : AppColors.divider,
                        gradient: i == _page ? AppColors.goldGradient : null,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: AnimatedSwitcher(
                  duration: AppDurations.base,
                  switchInCurve: AppCurves.emphasized,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _isLast
                      ? Column(
                          key: const ValueKey('actions'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PrimaryButton(
                              key: const ValueKey(
                                'onboarding_create_account_button',
                              ),
                              label: AuthStrings.createAccount,
                              icon: Icons.person_add_alt_1_outlined,
                              gold: true,
                              onPressed: () =>
                                  Navigator.pushNamed(context, Routes.register),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SecondaryButton(
                              key: const ValueKey('onboarding_login_button'),
                              label: AuthStrings.haveAccount,
                              onPressed: () =>
                                  Navigator.pushNamed(context, Routes.login),
                            ),
                          ],
                        )
                      : PrimaryButton(
                          key: const ValueKey('onboarding_next_button'),
                          label: AuthStrings.next,
                          onPressed: _next,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 460;
        final artworkSize = compact ? 132.0 : 176.0;
        final iconCircleSize = compact ? 84.0 : 112.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // دائرة ناعمة كبيرة بتدرج ذهبي هادئ تحتضن دائرة ذهبية متوهجة.
                Entrance(
                  child: Container(
                    width: artworkSize,
                    height: artworkSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Colors.white, AppColors.goldSoft],
                      ),
                      boxShadow: AppShadows.card,
                    ),
                    child: Container(
                      width: iconCircleSize,
                      height: iconCircleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: AppShadows.goldGlow,
                      ),
                      child: Icon(
                        slide.icon,
                        size: compact ? 40 : 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                Entrance(
                  index: 1,
                  child: Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                Entrance(
                  index: 2,
                  child: Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
