import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.primary : AppColors.textStrong;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.cardAlt,
          border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: leading == null
            ? Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading!,
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
                  ),
                ],
              ),
      ),
    );
  }
}
