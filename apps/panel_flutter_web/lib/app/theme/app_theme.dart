import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';
import 'app_text.dart';
import 'app_tokens.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.card,
      surfaceContainerHighest: AppColors.cardAlt,
      outline: AppColors.borderStrong,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textTheme: buildAppTextTheme(base.textTheme),
    extensions: [
      AppTokens(
        space4: 4.w,
        space8: 8.w,
        space12: 12.w,
        space16: 16.w,
        space20: 20.w,
        space24: 24.w,
        radius12: 12.r,
        radius16: 16.r,
        radius20: 20.r,
        radius24: 24.r,
        elevation1: 1,
        elevation2: 4,
        elevation3: 8,
        minHitTarget: 44,
        fast: const Duration(milliseconds: 150),
        medium: const Duration(milliseconds: 180),
        slow: const Duration(milliseconds: 220),
      ),
    ],
    cardTheme: const CardThemeData(
      color: AppColors.cardAlt,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.header,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.onPrimary,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderStrong, width: 0.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w800,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.textStrong,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.primaryStrong,
      labelStyle: TextStyle(fontWeight: FontWeight.w800),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0.5,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primary),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.textStrong),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.borderStrong),
        ),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(44, 44)),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.cardAlt,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardAlt,
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primaryStrong.withValues(alpha: 0.9),
        ),
      ),
    ),
  );
}
