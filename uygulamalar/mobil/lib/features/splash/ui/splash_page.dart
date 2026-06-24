import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/privacy/consent_guard.dart';
import '../../../core/storage/app_launch_prefs.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _shimmer;
  late final Animation<double> _fadeOut;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final durationMs = widget.redirectPath == null ? 2000 : 550;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _shimmer = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    );
    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goNext();
      }
    });
    _controller.forward();
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final redirectPath = widget.redirectPath;
    if (redirectPath != null && redirectPath.isNotEmpty) {
      context.go(redirectPath);
      return;
    }
    final seenOnboarding = await AppLaunchPrefs.seenOnboarding();
    if (!mounted) return;
    if (seenOnboarding) {
      await ConsentGuard.checkAndShow(context, ref);
      if (!mounted) return;
      context.go('/discover');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final logoSize = (shortestSide * 0.68).clamp(184.0, 280.0);
            return SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final opacity =
                        (_fadeIn.value * (1 - (_fadeOut.value * 0.25))).clamp(
                          0.0,
                          1.0,
                        );
                    final shimmerT = _shimmer.value;
                    final shimmerCenter = -1.2 + (shimmerT * 2.4);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(shimmerCenter - 0.8, 0),
                              end: Alignment(shimmerCenter + 0.8, 0),
                              colors: const [
                                Color(0x00FFFFFF),
                                Color(0x22FFFFFF),
                                Color(0x88FFFFFF),
                                Color(0x22FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ).createShader(bounds);
                          },
                          child: Image.asset(
                            'assets/brand/yeedoy-splash-logo.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
