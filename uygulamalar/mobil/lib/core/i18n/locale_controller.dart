import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_providers.dart';
import '../../features/profile/data/profile_repository.dart';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      // Kayıtlı tercihi arka planda yükle — ilk frame'i bloklamadan.
      unawaited(_loadPersistedLocale());
    }
    return const Locale('tr');
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMyProfile();
      final locale = _toLocale(_normalizeCode(profile?.languageCode));
      if (locale != null) {
        state = AsyncData(locale);
      }
    } catch (_) {
      // Kayıtlı tercih okunamadıysa varsayılan TR ile devam edilir.
    }
  }

  Future<void> setLocale(String? code) async {
    final normalized = _normalizeCode(code);
    state = AsyncData(_toLocale(normalized) ?? const Locale('tr'));

    try {
      await ref.read(profileRepositoryProvider).updateLanguageCode(normalized);
    } catch (_) {
      // Backend'e yazılamadıysa bile oturum içi dil değişikliği geçerli kalır.
    }
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
