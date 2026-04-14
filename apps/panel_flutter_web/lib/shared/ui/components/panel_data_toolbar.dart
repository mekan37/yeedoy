import 'package:flutter/material.dart';

import 'panel_toolbar.dart';

class PanelDataToolbar extends StatelessWidget {
  const PanelDataToolbar({
    super.key,
    required this.children,
    this.footer = const <Widget>[],
  });

  final List<Widget> children;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return PanelToolbar(
      footer: footer,
      children: children,
    );
  }
}
