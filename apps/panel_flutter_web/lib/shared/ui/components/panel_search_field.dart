import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/colors.dart';

class PanelSearchField extends StatelessWidget {
  const PanelSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onAction,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.space16,
          vertical: tokens.space12,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onAction == null
            ? null
            : IconButton(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: hintText,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.88),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.88),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.44),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
