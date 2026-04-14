import 'package:flutter/material.dart';

import 'panel_content_card.dart';

class PanelSectionCard extends StatelessWidget {
  const PanelSectionCard({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.trailing,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? description;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return PanelContentCard(
      title: title,
      description: description,
      trailing: trailing,
      padding: padding,
      child: child,
    );
  }
}
