import 'package:flutter/material.dart';

import 'app_profile_action.dart';
import '../../../../app/theme/colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.titleSpacing,
    this.bottom,
    this.showProfileAction = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;
  final bool showProfileAction;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final effectiveLeading = leading ?? (canPop ? const BackButton() : null);
    final List<Widget> effectiveActions = [
      if (actions != null) ...actions!,
      if (showProfileAction) const _AppBarProfileAction(),
    ];

    return AppBar(
      title: title,
      actions: effectiveActions.isEmpty ? null : effectiveActions,
      leading: effectiveLeading,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onPrimary,
      iconTheme: const IconThemeData(color: AppColors.onPrimary),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.header, AppColors.headerAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarProfileAction extends StatelessWidget {
  const _AppBarProfileAction();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: kToolbarHeight,
      child: Center(
        child: AppProfileAction(variant: AppProfileVariant.inverse),
      ),
    );
  }
}

