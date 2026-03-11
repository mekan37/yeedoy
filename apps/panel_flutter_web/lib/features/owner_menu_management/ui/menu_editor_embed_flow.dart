import 'package:flutter/material.dart';

import '../../menus/ui/public_menu_share_page.dart';

class MenuEditorPreviewPage extends StatelessWidget {
  const MenuEditorPreviewPage({
    super.key,
    required this.menuId,
  });

  final String menuId;

  @override
  Widget build(BuildContext context) {
    return PublicMenuSharePage(menuId: menuId);
  }
}
