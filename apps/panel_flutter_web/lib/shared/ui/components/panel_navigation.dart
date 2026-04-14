import 'package:flutter/material.dart';

class PanelNavItem {
  const PanelNavItem({
    required this.title,
    required this.route,
    required this.icon,
    this.description,
    this.selectedIcon,
    this.badgeCount = 0,
    this.children = const <PanelNavItem>[],
  });

  final String title;
  final String route;
  final IconData icon;
  final String? description;
  final IconData? selectedIcon;
  final int badgeCount;
  final List<PanelNavItem> children;

  bool matches(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;
    final routeUri = Uri.tryParse(route);
    final routePath = routeUri?.path ?? route;
    return path == routePath || path.startsWith('$routePath/');
  }
}

class PanelNavSection {
  const PanelNavSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<PanelNavItem> items;
}

class PanelFooterAction {
  const PanelFooterAction({
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final bool danger;
}
