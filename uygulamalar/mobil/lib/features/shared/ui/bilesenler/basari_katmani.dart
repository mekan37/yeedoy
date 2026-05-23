import 'package:flutter/material.dart';

import '../../../../uygulama/tema/uygulama_tokenleri.dart';
import '../../../../uygulama/tema/renkler.dart';

/// Animated success banner — fades and scales in with [AppTokens.elasticPop].
/// Typically shown inline after a successful form submission or action.
///
/// Usage:
/// ```dart
/// if (_success)
///   SuccessOverlay(message: l10n.saved)
/// ```
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({super.key, required this.message});

  final String message;

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(begin: 0.76, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppTokens.elasticPop),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.30),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
