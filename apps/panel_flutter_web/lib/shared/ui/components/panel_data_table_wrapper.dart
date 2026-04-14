import 'package:flutter/material.dart';

import 'panel_section_card.dart';

class PanelDataTableWrapper extends StatelessWidget {
  const PanelDataTableWrapper({
    super.key,
    required this.controller,
    required this.child,
    this.minWidth,
    this.height,
  });

  final ScrollController controller;
  final Widget child;
  final double? minWidth;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return PanelSectionCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedMinWidth = minWidth == null
              ? constraints.maxWidth
              : (minWidth! < constraints.maxWidth
                    ? constraints.maxWidth
                    : minWidth!);
          final content = ConstrainedBox(
            constraints: BoxConstraints(minWidth: resolvedMinWidth),
            child: height == null ? child : SizedBox(height: height, child: child),
          );
          return Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: content,
            ),
          );
        },
      ),
    );
  }
}
