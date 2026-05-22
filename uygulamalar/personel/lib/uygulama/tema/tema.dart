import 'package:flutter/material.dart';
import 'renkler.dart';

ThemeData buildPersonelLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Sora',
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: PColors.primary,
      brightness: Brightness.light,
      primary: PColors.primary,
      onPrimary: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xFF0F172A),
      titleTextStyle: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: Color(0xFF0F172A),
      ),
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: PColors.primarySoft.withValues(alpha: 0.5),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: states.contains(WidgetState.selected)
              ? PColors.primary
              : const Color(0xFF64748B),
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? PColors.primary
              : const Color(0xFF64748B),
          size: 22,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.disabled)
                ? const Color(0xFFCBD5E1)
                : PColors.primary),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: PColors.primary.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 0.5,
      space: 0.5,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData buildPersonelTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Sora',
    scaffoldBackgroundColor: PColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PColors.primary,
      brightness: Brightness.dark,
      primary: PColors.primary,
      onPrimary: PColors.onPrimary,
      surface: PColors.surface,
      surfaceContainerHighest: PColors.surfaceAlt,
      outline: PColors.borderStrong,
    ),
    cardTheme: CardThemeData(
      color: PColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PColors.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: PColors.textStrong,
      titleTextStyle: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: PColors.textStrong,
      ),
      iconTheme: IconThemeData(color: PColors.textStrong),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PColors.surface,
      indicatorColor: PColors.primarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: states.contains(WidgetState.selected)
              ? PColors.primaryStrong
              : PColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? PColors.primaryStrong
              : PColors.muted,
          size: 22,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.disabled)
                ? PColors.border
                : PColors.primary),
        foregroundColor: WidgetStateProperty.all(PColors.onPrimary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(PColors.text),
        side: WidgetStateProperty.all(const BorderSide(color: PColors.border)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 48)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PColors.surfaceAlt,
      hintStyle: const TextStyle(color: PColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: PColors.primaryStrong.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: PColors.border,
      thickness: 0.5,
      space: 0.5,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PColors.surfaceAlt,
      side: const BorderSide(color: PColors.border),
      labelStyle: const TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w700,
        color: PColors.text,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: PColors.cardElevated,
      contentTextStyle: const TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w600,
        color: PColors.textStrong,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
