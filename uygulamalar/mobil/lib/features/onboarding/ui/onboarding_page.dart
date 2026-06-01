import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/brand_widgets.dart';
import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/privacy/consent_guard.dart';
import '../../../core/storage/app_launch_prefs.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const int _pageCount = 3;
  final _controller = PageController();
  int _index = 0;
  bool _notificationsGranted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < _pageCount - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    unawaited(
      ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.onboardingComplete,
            source: 'onboarding_page',
            meta: {
              'slide_index': _index,
              'notifications_granted': _notificationsGranted,
            },
          ),
    );
    await AppLaunchPrefs.setSeenOnboarding(true);
    if (!mounted) return;
    await ConsentGuard.checkAndShow(context, ref);
    if (!mounted) return;
    context.go('/discover');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withValues(alpha: 0.65),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withValues(alpha: 0.45),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BrandMascot(size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_index + 1}/$_pageCount',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _finish, child: Text(t.notNow)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / _pageCount,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (v) => setState(() => _index = v),
                      children: [
                        _PriceValueSlide(t: t),
                        _CommunitySlide(t: t),
                        _NotificationSlide(
                          granted: _notificationsGranted,
                          onAllow: () async {
                            unawaited(
                              ref
                                  .read(analyticsRepositoryProvider)
                                  .logEvent(
                                    eventName:
                                        AppEvents.onboardingNotificationAllow,
                                    source: 'onboarding_page',
                                  ),
                            );
                            try {
                              final settings = await FirebaseMessaging.instance
                                  .requestPermission(
                                    alert: true,
                                    badge: true,
                                    sound: true,
                                  );
                              final authorized =
                                  settings.authorizationStatus ==
                                      AuthorizationStatus.authorized ||
                                  settings.authorizationStatus ==
                                      AuthorizationStatus.provisional;
                              if (!mounted) return;
                              setState(
                                () => _notificationsGranted = authorized,
                              );
                            } catch (_) {}
                            if (!mounted) return;
                            await _next();
                          },
                          onLater: () async {
                            unawaited(
                              ref
                                  .read(analyticsRepositoryProvider)
                                  .logEvent(
                                    eventName:
                                        AppEvents.onboardingNotificationSkip,
                                    source: 'onboarding_page',
                                  ),
                            );
                            await _next();
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: i == _index ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _index == _pageCount - 1
                              ? t.getStarted
                              : t.continueAction,
                          key: ValueKey(_index == _pageCount - 1),
                        ),
                      ),
                    ),
                  ),
                  if (_index == _pageCount - 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/login?mode=signin'),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: Text(t.login),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/login?mode=signup'),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                            ),
                            label: Text(t.register),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSlide extends StatelessWidget {
  const _NotificationSlide({
    required this.granted,
    required this.onAllow,
    required this.onLater,
  });

  final bool granted;
  final Future<void> Function() onAllow;
  final Future<void> Function() onLater;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.onboardingNotificationTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              t.onboardingNotificationDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (granted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.onboardingNotificationsEnabled,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAllow,
                  child: Text(t.onboardingAllowNotifications),
                ),
              ),
              TextButton(
                onPressed: onLater,
                child: Text(t.onboardingSkipNotifications),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceValueSlide extends StatelessWidget {
  const _PriceValueSlide({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final bullets = [
      t.onboardingPriceBody1,
      t.onboardingPriceBody2,
      t.onboardingPriceBody3,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.price_check_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.onboardingPriceTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            for (final bullet in bullets) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunitySlide extends StatelessWidget {
  const _CommunitySlide({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final bullets = [
      t.onboardingCommunityBody1,
      t.onboardingCommunityBody2,
      t.onboardingCommunityBody3,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.onboardingCommunityTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              t.onboardingCommunitySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            for (final bullet in bullets) ...[
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
