import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

/// Compact inline badge displayed on sponsored business tiles in Discovery.
///
/// Renders a small pill with a verified-outline icon and "Sponsorlu" label
/// using the primary brand colour at low opacity so it stays unobtrusive.
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            'Sponsorlu',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
