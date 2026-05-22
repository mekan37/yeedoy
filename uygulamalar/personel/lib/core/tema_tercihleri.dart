import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'p_theme_mode';

class TemaPrefs {
  static Future<ThemeMode> oku() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_kKey)) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };
  }

  static Future<void> yaz(ThemeMode mod) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, switch (mod) {
      ThemeMode.light  => 'light',
      ThemeMode.dark   => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

class TemaModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() => TemaPrefs.oku();

  Future<void> degistir(ThemeMode mod) async {
    await TemaPrefs.yaz(mod);
    state = AsyncData(mod);
  }

  Future<void> toggle() async {
    final current = state.asData?.value ?? ThemeMode.system;
    await degistir(switch (current) {
      ThemeMode.light  => ThemeMode.dark,
      ThemeMode.dark   => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    });
  }
}

final temaModeProvider =
    AsyncNotifierProvider<TemaModeNotifier, ThemeMode>(TemaModeNotifier.new);
