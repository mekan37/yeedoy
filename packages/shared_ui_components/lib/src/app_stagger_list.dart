import 'package:flutter/material.dart';

/// Staggered entrance animation for list items.
///
/// Her child animasyonu `staggerMs` ms arayla sırayla başlar.
/// `AppTokens.spring` easing kullanılır.
///
/// Kullanım:
/// ```dart
/// AppStaggerList(
///   children: items.map((item) => BusinessTile(item: item)).toList(),
/// )
/// ```
class AppStaggerList extends StatefulWidget {
  const AppStaggerList({
    super.key,
    required this.children,
    this.staggerMs = 48,
    this.durationMs = 280,
    this.offsetY = 14.0,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int staggerMs;
  final int durationMs;
  final double offsetY;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  State<AppStaggerList> createState() => _AppStaggerListState();
}

class _AppStaggerListState extends State<AppStaggerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final totalMs =
        widget.durationMs + widget.staggerMs * (widget.children.length - 1).clamp(0, 8);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        final delay = widget.staggerMs * index.clamp(0, 8);
        final delayFraction = delay / _controller.duration!.inMilliseconds;
        final endFraction =
            (delay + widget.durationMs) / _controller.duration!.inMilliseconds;

        final curve = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delayFraction.clamp(0.0, 1.0),
            endFraction.clamp(0.0, 1.0),
            curve: const Cubic(0.22, 1.0, 0.36, 1.0), // spring
          ),
        );

        return AnimatedBuilder(
          animation: curve,
          builder: (context, child) {
            return Opacity(
              opacity: curve.value,
              child: Transform.translate(
                offset: Offset(0, widget.offsetY * (1 - curve.value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}

/// Sadece animasyon saran wrapper — kendi scroll'u yok.
/// Mevcut ListView/Column içindeki tek item'ı animate etmek için kullanılır.
class AppStaggerItem extends StatefulWidget {
  const AppStaggerItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerMs = 48,
    this.durationMs = 280,
    this.offsetY = 14.0,
  });

  final Widget child;
  final int index;
  final int staggerMs;
  final int durationMs;
  final double offsetY;

  @override
  State<AppStaggerItem> createState() => _AppStaggerItemState();
}

class _AppStaggerItemState extends State<AppStaggerItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final delay = widget.staggerMs * widget.index.clamp(0, 8);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: delay + widget.durationMs),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        delay / (delay + widget.durationMs),
        1.0,
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      ),
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
