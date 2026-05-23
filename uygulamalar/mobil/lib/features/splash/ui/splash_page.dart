import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/storage/app_launch_prefs.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
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
    context.go(seenOnboarding ? '/discover' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.displayMedium?.copyWith(
          color: AppColors.textStrong,
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ) ??
        const TextStyle(
          color: AppColors.textStrong,
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final opacity = (_fadeIn.value * (1 - (_fadeOut.value * 0.25)))
                    .clamp(0.0, 1.0);
                final shimmerT = _shimmer.value;
                final shimmerCenter = -1.2 + (shimmerT * 2.4);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('Yeedoy', style: textStyle),
                        ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(shimmerCenter - 0.8, 0),
                              end: Alignment(shimmerCenter + 0.8, 0),
                              colors: const [
                                Color(0x00FFFFFF),
                                Color(0x33FFFFFF),
                                Color(0xB3FFFFFF),
                                Color(0x33FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text('Yeedoy', style: textStyle),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
