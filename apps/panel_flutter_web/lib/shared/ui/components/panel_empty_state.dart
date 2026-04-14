import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'panel_section_card.dart';

class PanelEmptyState extends StatelessWidget {
  const PanelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return PanelSectionCard(
      child: AppEmptyState(
        icon: icon,
        title: title,
        description: description,
        ctaLabel: ctaLabel,
        onCta: onCta,
      ),
    );
  }
}
