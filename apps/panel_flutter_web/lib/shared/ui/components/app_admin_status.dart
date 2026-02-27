import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class AppSlaBadge extends StatelessWidget {
  const AppSlaBadge({super.key, this.label = 'SLA'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class AppSlaBanner extends StatelessWidget {
  const AppSlaBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppPriorityBadge extends StatelessWidget {
  const AppPriorityBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (score) {
      >= 80 => ('P1', AppColors.danger),
      >= 50 => ('P2', AppColors.warning),
      _ => ('P3', AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label ($score)',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class AppAutoBadge extends StatelessWidget {
  const AppAutoBadge({super.key, this.label = 'Otomatik'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

WidgetStateProperty<Color?> appAdminRowColor({
  required bool active,
  required bool slaBreached,
}) {
  if (active) {
    return WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.12));
  }
  if (slaBreached) {
    return WidgetStatePropertyAll(AppColors.danger.withValues(alpha: 0.08));
  }
  return const WidgetStatePropertyAll(null);
}

WidgetStateProperty<Color?> appAdminSlaRowColor(bool slaBreached) {
  if (slaBreached) {
    return WidgetStatePropertyAll(AppColors.danger.withValues(alpha: 0.08));
  }
  return const WidgetStatePropertyAll(null);
}
