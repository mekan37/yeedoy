import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Wraps [child] with a sweeping shimmer highlight animation.
/// All skeleton widgets use this internally — no change needed at call sites.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final pos = _ctrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-2 + 4 * pos, 0),
            end: Alignment(-1 + 4 * pos, 0),
            colors: const [
              Color(0xFFD5D5D5),
              Color(0xFFEEEEEE),
              Color(0xFFD5D5D5),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class AppSkeletonLine extends StatelessWidget {
  const AppSkeletonLine({super.key, this.width, this.height = 10});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({super.key, required this.height, this.width});
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(tokens.radius12),
        ),
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.lines = 2});
  final int lines;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeletonBox(height: 14),
            for (var i = 0; i < lines; i++) ...[
              SizedBox(height: tokens.space8),
              AppSkeletonLine(width: 160 - (i * 20).toDouble()),
            ],
          ],
        ),
      ),
    );
  }
}
