import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import 'panel_icon.dart';
import 'panel_navigation.dart';

class PanelSidebar extends StatelessWidget {
  const PanelSidebar({
    super.key,
    required this.location,
    required this.sections,
    required this.footerActions,
    required this.collapsed,
    required this.brandIcon,
    required this.brandLabel,
    required this.panelLabel,
    this.onToggleCollapse,
  });

  final String location;
  final List<PanelNavSection> sections;
  final List<PanelFooterAction> footerActions;
  final bool collapsed;
  final IconData brandIcon;
  final String brandLabel;
  final String panelLabel;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = collapsed || constraints.maxWidth < 208;
        final compactPadding = iconOnly ? tokens.space12 : tokens.space20;
        return Container(
          color: AppColors.card,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  compactPadding,
                  tokens.space20,
                  compactPadding,
                  tokens.space16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final headerIconOnly =
                        iconOnly || headerConstraints.maxWidth < 176;
                    if (headerIconOnly) {
                      return Column(
                        children: [
                          _BrandMark(icon: brandIcon),
                          if (onToggleCollapse != null) ...[
                            SizedBox(height: tokens.space16),
                            _SidebarToggleButton(
                              collapsed: collapsed,
                              onPressed: onToggleCollapse!,
                            ),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        _BrandMark(icon: brandIcon),
                        SizedBox(width: tokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brandLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.titleStyle.copyWith(fontSize: 20),
                              ),
                              SizedBox(height: tokens.space4),
                              Text(
                                panelLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.captionStyle,
                              ),
                            ],
                          ),
                        ),
                        if (onToggleCollapse != null) ...[
                          SizedBox(width: tokens.space8),
                          _SidebarToggleButton(
                            collapsed: collapsed,
                            onPressed: onToggleCollapse!,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    iconOnly ? tokens.space8 : tokens.space12,
                    tokens.space16,
                    iconOnly ? tokens.space8 : tokens.space12,
                    tokens.space16,
                  ),
                  children: [
                    for (final section in sections) ...[
                      if (!iconOnly && section.title.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            tokens.space12,
                            tokens.space8,
                            tokens.space12,
                            tokens.space8,
                          ),
                          child: Text(
                            section.title.toUpperCase(),
                            style: context.captionStyle.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      for (final item in section.items)
                        PanelSidebarItem(
                          item: item,
                          location: location,
                          collapsed: iconOnly,
                          onTap: () => context.go(item.route),
                        ),
                      SizedBox(height: tokens.space8),
                    ],
                  ],
                ),
              ),
              if (footerActions.isNotEmpty)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    iconOnly ? tokens.space8 : tokens.space12,
                    tokens.space12,
                    iconOnly ? tokens.space8 : tokens.space12,
                    tokens.space16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final action in footerActions)
                        _SidebarFooterAction(
                          action: action,
                          collapsed: iconOnly,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PanelSidebarItem extends StatelessWidget {
  const PanelSidebarItem({
    super.key,
    required this.item,
    required this.location,
    required this.collapsed,
    required this.onTap,
    this.depth = 0,
  });

  final PanelNavItem item;
  final String location;
  final bool collapsed;
  final VoidCallback onTap;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final active = item.matches(location);
    final iconColor = active ? AppColors.primary : AppColors.slate;
    final labelStyle = context.bodyStyle.copyWith(
      color: active ? AppColors.textStrong : AppColors.slate,
      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
    );

    final button = LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = collapsed || constraints.maxWidth < 170;
        final tile = AnimatedContainer(
          duration: tokens.medium,
          curve: Curves.easeOutCubic,
          height: 48,
          margin: EdgeInsets.only(
            bottom: tokens.space8,
            left: iconOnly ? 0 : depth * tokens.space16,
          ),
          decoration: BoxDecoration(
            color: active
                ? Color.alphaBlend(
                    AppColors.primarySoft.withValues(alpha: 0.48),
                    AppColors.card,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radius16),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              if (!iconOnly)
                AnimatedContainer(
                  duration: tokens.medium,
                  width: 3,
                  height: 22,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: iconOnly ? 0 : 14,
                  ),
                  child: Row(
                    mainAxisAlignment: iconOnly
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      PanelIcon(
                        icon: active ? item.selectedIcon ?? item.icon : item.icon,
                        color: iconColor,
                        materialSize: 18,
                        awesomeSize: 15,
                      ),
                      if (!iconOnly) ...[
                        SizedBox(width: tokens.space12),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle,
                          ),
                        ),
                        if (item.badgeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.radius16),
            child: tile,
          ),
        );
      },
    );

    return Column(
      children: [
        collapsed
            ? Tooltip(
                message: item.title,
                waitDuration: Duration.zero,
                child: button,
              )
            : button,
        if (!collapsed)
          for (final child in item.children)
            PanelSidebarItem(
              item: child,
              location: location,
              collapsed: false,
              onTap: () => context.go(child.route),
              depth: depth + 1,
            ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Center(
        child: PanelIcon(
          icon: icon,
          color: Colors.white,
          materialSize: 18,
          awesomeSize: 15,
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  const _SidebarToggleButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? 'Menüyü genişlet' : 'Menüyü daralt',
      waitDuration: Duration.zero,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
        ),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textStrong,
          backgroundColor: AppColors.cardAlt,
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooterAction extends StatelessWidget {
  const _SidebarFooterAction({
    required this.action,
    required this.collapsed,
  });

  final PanelFooterAction action;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final foreground = action.danger ? AppColors.danger : AppColors.textStrong;
    final button = LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = collapsed || constraints.maxWidth < 170;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap ??
                (action.route == null ? null : () => context.go(action.route!)),
            borderRadius: BorderRadius.circular(tokens.radius16),
            child: Container(
              height: 46,
              margin: EdgeInsets.only(bottom: tokens.space8),
              decoration: BoxDecoration(
                color: action.danger ? const Color(0xFFFFF5F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(tokens.radius16),
                border: Border.all(
                  color: action.danger
                      ? const Color(0xFFF4CACA)
                      : AppColors.border.withValues(alpha: 0.82),
                ),
              ),
              child: Row(
                mainAxisAlignment: iconOnly
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 14),
                    child: PanelIcon(
                      icon: action.icon,
                      color: foreground,
                      materialSize: 18,
                      awesomeSize: 15,
                    ),
                  ),
                  if (!iconOnly)
                    Expanded(
                      child: Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return collapsed
        ? Tooltip(
            message: action.title,
            waitDuration: Duration.zero,
            child: button,
          )
        : button;
  }
}
