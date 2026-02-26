import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_providers.dart';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    ref.watch(sessionProvider);
    return const Locale('tr');
  }

  Future<void> setLocale(String? code) async {
    final normalized = _normalizeCode(code);
    state = AsyncData(_toLocale(normalized) ?? const Locale('tr'));

    // Language preference is session-local until a canonical DB field is finalized.
    return;
  }
}

String? _normalizeCode(String? code) {
  final v = (code ?? '').trim().toLowerCase();
  if (v == 'tr' || v == 'en') return v;
  return null;
}

Locale? _toLocale(String? code) {
  if (code == null) return null;
  return Locale(code);
}
