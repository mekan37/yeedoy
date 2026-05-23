import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yeedoy_shared_ui_components/yeedoy_shared_ui_components.dart'
    show AppDarkColors;

import 'renkler.dart';
import 'uygulama_metni.dart';
import 'uygulama_tokenleri.dart';

/// Shared token extension values (same physical sizes for both themes).
AppTokens _buildTokens() => AppTokens(
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
    );

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Sora',
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
    extensions: [_buildTokens()],
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
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.muted,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      indicator: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F1D1D).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      elevation: 48,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

/// Dark variant — mirrors [buildAppTheme] structure using [AppDarkColors].
ThemeData buildDarkAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Sora',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppDarkColors.primary,
      brightness: Brightness.dark,
      primary: AppDarkColors.primary,
      onPrimary: AppDarkColors.onPrimary,
      surface: AppDarkColors.card,
      surfaceContainerHighest: AppDarkColors.cardAlt,
      outline: AppDarkColors.borderStrong,
    ),
    scaffoldBackgroundColor: AppDarkColors.bg,
  );

  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textTheme: buildAppTextTheme(base.textTheme).apply(
      bodyColor: AppDarkColors.text,
      displayColor: AppDarkColors.textStrong,
    ),
    extensions: [_buildTokens()],
    cardTheme: CardThemeData(
      color: AppDarkColors.cardAlt,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: AppDarkColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppDarkColors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppDarkColors.header,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppDarkColors.onPrimary,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: AppDarkColors.borderStrong, width: 0.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppDarkColors.card,
      indicatorColor: AppDarkColors.primarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w800,
          color: states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : AppDarkColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : AppDarkColors.muted,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: AppDarkColors.muted,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      indicator: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F1D1D).withValues(alpha: 0.36),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppDarkColors.bg,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: AppDarkColors.border,
      thickness: 0.5,
      space: 0.5,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppDarkColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      elevation: 48,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppDarkColors.primary),
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
        foregroundColor: WidgetStateProperty.all(AppDarkColors.textStrong),
        side: WidgetStateProperty.all(
          BorderSide(color: AppDarkColors.borderStrong),
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
      selectedColor: AppDarkColors.primarySoft,
      backgroundColor: AppDarkColors.cardAlt,
      side: BorderSide(color: AppDarkColors.border),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppDarkColors.text,
      ),
      secondaryLabelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppDarkColors.text,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDarkColors.cardAlt,
      hintStyle: TextStyle(color: AppDarkColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppDarkColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppDarkColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppDarkColors.primaryStrong.withValues(alpha: 0.9),
        ),
      ),
    ),
  );
}


