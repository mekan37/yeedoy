import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import 'kimlik_durum.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final kimlikProvider = AsyncNotifierProvider<KimlikBildiricisi, KimlikDurum>(
  KimlikBildiricisi.new,
);

class KimlikBildiricisi extends AsyncNotifier<KimlikDurum> {
  @override
  Future<KimlikDurum> build() async {
    final supabase = ref.watch(supabaseProvider);

    // Auth state stream dinle
    supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        state = const AsyncData(KimlikGirilmemis());
      } else if (event.event == AuthChangeEvent.signedIn && event.session != null) {
        _dogrulaVeYukle(supabase, event.session!.user);
      }
    });

    final session = supabase.auth.currentSession;
    if (session == null) return const KimlikGirilmemis();

    return _ownerClaimsKontrol(supabase, session.user);
  }

  Future<void> _dogrulaVeYukle(SupabaseClient supabase, User user) async {
    state = const AsyncLoading();
    state = AsyncData(KimlikDogrulaniyor(user));
    final durum = await _ownerClaimsKontrol(supabase, user);
    state = AsyncData(durum);
  }

  Future<KimlikDurum> _ownerClaimsKontrol(SupabaseClient supabase, User user) async {
    try {
      final rows = await supabase
          .from('owner_claims')
          .select('status, business_id, businesses(name)')
          .eq('user_id', user.id)
          .eq('status', 'approved')
          .limit(1);

      if (rows.isEmpty) {
        return const KimlikYetkisiz(
          mesaj: 'Bu uygulamaya erişim için onaylı işletme kaydı gereklidir.',
        );
      }

      final row = rows.first;
      final businesses = row['businesses'] as Map<String, dynamic>?;
      return KimlikGirilmis(
        user: user,
        isletmeId: row['business_id'] as String,
        isletmeAdi: businesses?['name'] as String? ?? 'İşletme',
      );
    } catch (_) {
      return const KimlikYetkisiz();
    }
  }

  Future<void> girisYap({required String email, required String sifre}) async {
    state = const AsyncLoading();
    try {
      final supabase = ref.read(supabaseProvider);
      final res = await supabase.auth.signInWithPassword(email: email, password: sifre);
      if (res.user == null) {
        state = AsyncError('Giriş başarısız.', StackTrace.current);
        return;
      }
      final durum = await _ownerClaimsKontrol(supabase, res.user!);
      state = AsyncData(durum);
      // Biyometrik için token kaydet
      if (res.session != null) {
        await _secureStorage.write(key: 'p_access_token', value: res.session!.accessToken);
        if (res.session!.refreshToken != null) {
          await _secureStorage.write(key: 'p_refresh_token', value: res.session!.refreshToken);
        }
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> cikisYap() async {
    await ref.read(supabaseProvider).auth.signOut();
    state = const AsyncData(KimlikGirilmemis());
  }
}
