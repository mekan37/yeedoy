import 'package:flutter/widgets.dart';

class PanelShellScope extends InheritedWidget {
  const PanelShellScope({
    super.key,
    required super.child,
    this.active = true,
  });

  final bool active;

  static PanelShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PanelShellScope>();
  }

  static bool isActive(BuildContext context) {
    return maybeOf(context)?.active ?? false;
  }

  @override
  bool updateShouldNotify(PanelShellScope oldWidget) {
    return oldWidget.active != active;
  }
}
