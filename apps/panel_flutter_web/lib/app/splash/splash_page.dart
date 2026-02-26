import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/storage/app_launch_prefs.dart';
import '../theme/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 600), () async {
      final seenOnboarding = await AppLaunchPrefs.seenOnboarding();
      if (!mounted) return;
      context.go(seenOnboarding ? '/discover' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoWidth = (width * 0.4).clamp(140.0, 220.0);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: logoWidth,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: 0.7,
                child: Column(
                  children: [
                    Text(context.l10n.appTaglineLine1),
                    Text(context.l10n.appTaglineLine2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
