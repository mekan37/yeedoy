import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/colors.dart';
import 'panel_content_surface.dart';
import 'panel_navigation.dart';
import 'panel_sidebar.dart';
import 'panel_shell_scope.dart';

class PanelShell extends StatefulWidget {
  const PanelShell({
    super.key,
    required this.location,
    required this.panelTitle,
    required this.currentTitle,
    required this.currentDescription,
    required this.userLabel,
    required this.sections,
    required this.child,
    this.metaLabel,
    this.headerSearch,
    this.topBarTrailing,
    this.banner,
    this.contextBar,
    this.footerActions = const <PanelFooterAction>[],
    this.brandIcon = FontAwesomeIcons.compass,
    this.brandLabel = 'YEEDOY',
  });

  final String location;
  final String panelTitle;
  final String currentTitle;
  final String currentDescription;
  final String userLabel;
  final String? metaLabel;
  final List<PanelNavSection> sections;
  final Widget child;
  final Widget? headerSearch;
  final Widget? topBarTrailing;
  final Widget? banner;
  final Widget? contextBar;
  final List<PanelFooterAction> footerActions;
  final IconData brandIcon;
  final String brandLabel;

  static PanelNavItem? activeItem(
    List<PanelNavSection> sections,
    String location,
  ) {
    final allItems = <PanelNavItem>[];
    for (final section in sections) {
      for (final item in section.items) {
        allItems.add(item);
        allItems.addAll(item.children);
      }
    }
    allItems.sort((a, b) => b.route.length.compareTo(a.route.length));
    for (final item in allItems) {
      if (item.matches(location)) return item;
    }
    return allItems.isEmpty ? null : allItems.first;
  }

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  bool? _collapsedOverride;

  void _toggleSidebar({required bool defaultCollapsed}) {
    final current = _collapsedOverride ?? defaultCollapsed;
    setState(() => _collapsedOverride = !current);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showDesktopSidebar = width >= 960;
    final defaultCollapsed = showDesktopSidebar && width < 1280;
    final collapsed = showDesktopSidebar &&
        (_collapsedOverride ?? defaultCollapsed);
    final tokens = AppTokens.of(context);

    final body = Row(
      children: [
        if (showDesktopSidebar)
          FocusTraversalGroup(
            child: AnimatedContainer(
            duration: tokens.medium,
            curve: Curves.easeOutCubic,
            width: collapsed ? 84 : 256,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                right: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.92),
                ),
              ),
            ),
            child: PanelSidebar(
              location: widget.location,
              sections: widget.sections,
              footerActions: widget.footerActions,
              collapsed: collapsed,
              brandIcon: widget.brandIcon,
              brandLabel: widget.brandLabel,
              panelLabel: widget.panelTitle,
              onToggleCollapse: () => _toggleSidebar(
                defaultCollapsed: defaultCollapsed,
              ),
            ),
          ),
          ),
        Expanded(
          child: FocusTraversalGroup(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.bg),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.space20,
                      tokens.space16,
                      tokens.space20,
                      tokens.space16,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1520),
                        child: _PanelTopBar(
                          showDrawerButton: !showDesktopSidebar,
                          panelTitle: widget.panelTitle,
                          currentTitle: widget.currentTitle,
                          currentDescription: widget.currentDescription,
                          userLabel: widget.userLabel,
                          metaLabel: widget.metaLabel,
                          isSidebarCollapsed: collapsed,
                          headerSearch: widget.headerSearch,
                          topBarTrailing: widget.topBarTrailing,
                          onToggleSidebar: showDesktopSidebar
                              ? () => _toggleSidebar(
                                  defaultCollapsed: defaultCollapsed,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.banner != null)
                  _ConstrainedStrip(
                    padding: EdgeInsets.fromLTRB(
                      tokens.space20,
                      tokens.space16,
                      tokens.space20,
                      0,
                    ),
                    child: widget.banner!,
                  ),
                if (widget.contextBar != null)
                  _ConstrainedStrip(
                    padding: EdgeInsets.fromLTRB(
                      tokens.space20,
                      tokens.space16,
                      tokens.space20,
                      0,
                    ),
                    child: widget.contextBar!,
                  ),
                Expanded(
                  child: PanelShellScope(
                    child: PanelContentSurface(
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: showDesktopSidebar
          ? null
          : Drawer(
              width: 276,
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
              child: SafeArea(
                child: PanelSidebar(
                  location: widget.location,
                  sections: widget.sections,
                  footerActions: widget.footerActions,
                  collapsed: false,
                  brandIcon: widget.brandIcon,
                  brandLabel: widget.brandLabel,
                  panelLabel: widget.panelTitle,
                ),
              ),
            ),
      body: SafeArea(child: body),
    );
  }
}

class _ConstrainedStrip extends StatelessWidget {
  const _ConstrainedStrip({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1520),
          child: child,
        ),
      ),
    );
  }
}

class _PanelTopBar extends StatelessWidget {
  const _PanelTopBar({
    required this.showDrawerButton,
    required this.panelTitle,
    required this.currentTitle,
    required this.currentDescription,
    required this.userLabel,
    required this.isSidebarCollapsed,
    this.metaLabel,
    this.headerSearch,
    this.topBarTrailing,
    this.onToggleSidebar,
  });

  final bool showDrawerButton;
  final String panelTitle;
  final String currentTitle;
  final String currentDescription;
  final String userLabel;
  final bool isSidebarCollapsed;
  final String? metaLabel;
  final Widget? headerSearch;
  final Widget? topBarTrailing;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1160;
        final navButton = showDrawerButton
            ? Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menüyü aç',
                  icon: const Icon(Icons.menu_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.cardAlt,
                    side: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              )
            : (onToggleSidebar == null
                  ? null
                  : IconButton(
                      onPressed: onToggleSidebar,
                      tooltip: isSidebarCollapsed
                          ? 'Menüyü genişlet'
                          : 'Menüyü daralt',
                      icon: Icon(
                        isSidebarCollapsed
                            ? Icons.menu_rounded
                            : Icons.menu_open_rounded,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.cardAlt,
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.88),
                        ),
                      ),
                    ));

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: tokens.space8,
              runSpacing: tokens.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...?navButton == null ? null : [navButton],
                Text(
                  panelTitle.toUpperCase(),
                  style: context.captionStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '/',
                  style: context.captionStyle.copyWith(
                    color: AppColors.borderStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  currentTitle,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                currentDescription,
                maxLines: stacked ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: context.subtitleStyle.copyWith(height: 1.4),
              ),
            ),
            if (metaLabel != null) ...[
              SizedBox(height: tokens.space4),
              Text(metaLabel!, style: context.captionStyle),
            ],
          ],
        );

        final profileCard = Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space12,
            vertical: tokens.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(tokens.radius16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.88),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, cardConstraints) {
              final compactProfile = cardConstraints.maxWidth < 170;
              return Row(
                mainAxisSize: compactProfile ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      _initials(userLabel),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!compactProfile) ...[
                    SizedBox(width: tokens.space8),
                    Expanded(
                      child: Text(
                        userLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyStyle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );

        final utilities = Wrap(
          spacing: tokens.space12,
          runSpacing: tokens.space12,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (headerSearch != null)
              SizedBox(
                width: stacked ? constraints.maxWidth : 360,
                child: headerSearch!,
              ),
            ...?topBarTrailing == null ? null : [topBarTrailing!],
            profileCard,
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              SizedBox(height: tokens.space16),
              utilities,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: info),
            SizedBox(width: tokens.space20),
            Flexible(child: utilities),
          ],
        );
      },
    );
  }

  String _initials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}
