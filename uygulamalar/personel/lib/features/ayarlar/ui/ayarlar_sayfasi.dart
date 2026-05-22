import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../../core/tema_tercihleri.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../../uygulama/tema/renkler.dart';
import 'ayarlar_yardimci.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// Basit sağlayıcılar
final _siparisBildirimProvider = NotifierProvider<_BoolTercihBildiricisi, bool>(
  () => _BoolTercihBildiricisi(true),
);
final _yorumBildirimProvider = NotifierProvider<_BoolTercihBildiricisi, bool>(
  () => _BoolTercihBildiricisi(true),
);
final _pinKilidiProvider = NotifierProvider<_BoolTercihBildiricisi, bool>(
  () => _BoolTercihBildiricisi(false),
);
final _biyometrikProvider = NotifierProvider<_BoolTercihBildiricisi, bool>(
  () => _BoolTercihBildiricisi(false),
);
// P-35: Titreşim bildirimi tercihi
final _titresimProvider = NotifierProvider<_BoolTercihBildiricisi, bool>(
  () => _BoolTercihBildiricisi(true),
);

class _BoolTercihBildiricisi extends Notifier<bool> {
  _BoolTercihBildiricisi(this._ilkDeger);

  final bool _ilkDeger;

  @override
  bool build() => _ilkDeger;

  void ayarla(bool deger) => state = deger;
}

class AyarlarSayfasi extends ConsumerWidget {
  const AyarlarSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    final isletmeAdi = kimlik is KimlikGirilmis ? kimlik.isletmeAdi : '';
    final email = kimlik is KimlikGirilmis ? kimlik.user.email ?? '' : '';
    final siparisBildirim = ref.watch(_siparisBildirimProvider);
    final yorumBildirim = ref.watch(_yorumBildirimProvider);
    final pinKilidi = ref.watch(_pinKilidiProvider);
    final biyometrik = ref.watch(_biyometrikProvider);
    final titresim = ref.watch(_titresimProvider);
    final themeMode = ref.watch(temaModeProvider).valueOrNull ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          if (isletmeAdi.isNotEmpty)
            AyarlarInfoKutucusu(isletmeAdi: isletmeAdi, email: email),
          const Divider(height: 1),

          // Bildirim tercihleri
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'BİLDİRİM TERCİHLERİ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: PColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.receipt_long_outlined,
              color: PColors.primary,
            ),
            title: const Text(
              'Yeni Sipariş Bildirimleri',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: PColors.textStrong,
              ),
            ),
            subtitle: const Text(
              'Masa siparişi geldiğinde bildirim al',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: siparisBildirim,
            activeThumbColor: PColors.primary,
            onChanged: (v) {
              ref.read(_siparisBildirimProvider.notifier).ayarla(v);
              _kaydetTercih('siparis_bildirim', v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.star_outline, color: PColors.primary),
            title: const Text(
              'Yorum Bildirimleri',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: PColors.textStrong,
              ),
            ),
            subtitle: const Text(
              'Yeni yorum geldiğinde bildirim al',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: yorumBildirim,
            activeThumbColor: PColors.primary,
            onChanged: (v) {
              ref.read(_yorumBildirimProvider.notifier).ayarla(v);
              _kaydetTercih('yorum_bildirim', v);
            },
          ),
          // P-35: Titreşim tercihi
          SwitchListTile(
            secondary: const Icon(Icons.vibration_outlined, color: PColors.primary),
            title: const Text(
              'Titreşim Bildirimi',
              style: TextStyle(fontWeight: FontWeight.w700, color: PColors.textStrong),
            ),
            subtitle: const Text(
              'Yeni sipariş geldiğinde cihaz titreşsin',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: titresim,
            activeThumbColor: PColors.primary,
            onChanged: (v) {
              ref.read(_titresimProvider.notifier).ayarla(v);
              _kaydetTercih('titresim_bildirim', v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline, color: PColors.primary),
            title: const Text(
              'PIN Kilidi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: PColors.textStrong,
              ),
            ),
            subtitle: const Text(
              'Uygulama arka plana geçince PIN ile kilitle',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: pinKilidi,
            activeThumbColor: PColors.primary,
            onChanged: (v) async {
              if (v) {
                // PIN kurulum dialogu
                final pin = await _pinDialog(context);
                if (pin != null && pin.length == 4) {
                  ref.read(_pinKilidiProvider.notifier).ayarla(true);
                  await _kaydetTercih('pin_kilidi', true);
                  // P-2: PIN şifrelenmiş depolamaya kaydediliyor (SharedPreferences'tan taşındı)
                  await _secureStorage.write(key: 'app_pin', value: pin);
                  // Eski düz metin kaydı varsa temizle
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('app_pin');
                }
              } else {
                ref.read(_pinKilidiProvider.notifier).ayarla(false);
                await _kaydetTercih('pin_kilidi', false);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(
              Icons.fingerprint_outlined,
              color: PColors.primary,
            ),
            title: const Text(
              'Biyometrik Kimlik Doğrulama',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: PColors.textStrong,
              ),
            ),
            subtitle: const Text(
              'Parmak izi veya yüz tanıma ile giriş',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: biyometrik,
            activeThumbColor: PColors.primary,
            onChanged: (v) async {
              if (v) {
                final auth = LocalAuthentication();
                final destekleniyor = await auth.canCheckBiometrics;
                if (!destekleniyor) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bu cihaz biyometrik doğrulamayı desteklemiyor.',
                        ),
                        backgroundColor: PColors.danger,
                      ),
                    );
                  }
                  return;
                }
                final dogrulandi = await auth.authenticate(
                  localizedReason:
                      'Biyometrik doğrulamayı etkinleştirmek için kimliğinizi doğrulayın',
                  options: const AuthenticationOptions(
                    biometricOnly: false,
                    stickyAuth: true,
                  ),
                );
                if (dogrulandi) {
                  ref.read(_biyometrikProvider.notifier).ayarla(true);
                  await _kaydetTercih('biyometrik_kilidi', true);
                  await _secureStorage.write(key: 'p_biometric_enabled', value: 'true');
                }
              } else {
                ref.read(_biyometrikProvider.notifier).ayarla(false);
                await _kaydetTercih('biyometrik_kilidi', false);
                await _secureStorage.write(key: 'p_biometric_enabled', value: 'false');
              }
            },
          ),
          const Divider(height: 1),

          // Tema tercihi
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'GÖRÜNÜM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: PColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : themeMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.brightness_auto_outlined,
              color: PColors.primary,
            ),
            title: const Text(
              'Tema',
              style: TextStyle(fontWeight: FontWeight.w700, color: PColors.textStrong),
            ),
            subtitle: Text(
              themeMode == ThemeMode.dark
                  ? 'Koyu'
                  : themeMode == ThemeMode.light
                      ? 'Açık'
                      : 'Sistem',
              style: const TextStyle(fontSize: 12, color: PColors.muted),
            ),
            trailing: const Icon(Icons.chevron_right, color: PColors.muted),
            onTap: () async {
              final secim = await showDialog<ThemeMode>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Tema Seçin'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, ThemeMode.system),
                      child: const ListTile(
                        leading: Icon(Icons.brightness_auto_outlined),
                        title: Text('Sistem'),
                      ),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, ThemeMode.light),
                      child: const ListTile(
                        leading: Icon(Icons.light_mode_outlined),
                        title: Text('Açık'),
                      ),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
                      child: const ListTile(
                        leading: Icon(Icons.dark_mode_outlined),
                        title: Text('Koyu'),
                      ),
                    ),
                  ],
                ),
              );
              if (secim != null) {
                await ref.read(temaModeProvider.notifier).degistir(secim);
              }
            },
          ),
          const Divider(height: 1),

          // Vardiya bilgisi
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'VARDİYA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: PColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.access_time_outlined,
              color: PColors.muted,
            ),
            title: const Text(
              'Vardiya Başlangıcı',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: PColors.textStrong,
              ),
            ),
            subtitle: Text(
              _bugunTarih(),
              style: const TextStyle(fontSize: 12, color: PColors.muted),
            ),
          ),
          const Divider(height: 1),

          // Hesap işlemleri
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'HESAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: PColors.muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // P-34: Şifre değiştir (e-posta ile sıfırlama)
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined, color: PColors.muted),
            title: const Text(
              'Şifre Değiştir',
              style: TextStyle(fontWeight: FontWeight.w700, color: PColors.textStrong),
            ),
            subtitle: const Text(
              'E-posta ile şifre sıfırlama bağlantısı gönderilir',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            trailing: const Icon(Icons.chevron_right, color: PColors.muted),
            onTap: () async {
              final kimlik = ref.read(kimlikProvider).valueOrNull;
              final email = kimlik is KimlikGirilmis ? kimlik.user.email ?? '' : '';
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-posta adresi bulunamadı')),
                );
                return;
              }
              try {
                final supabase = ref.read(supabaseProvider);
                await supabase.auth.resetPasswordForEmail(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Şifre sıfırlama bağlantısı $email adresine gönderildi'),
                      backgroundColor: PColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-posta gönderilemedi'),
                      backgroundColor: PColors.danger,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: PColors.danger),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: PColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () async {
              final onay = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Uygulamadan çıkmak istiyor musunuz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: PColors.danger,
                      ),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (onay == true) {
                await ref.read(kimlikProvider.notifier).cikisYap();
              }
            },
          ),
          const SizedBox(height: 24),
          const AyarlarSurumGoster(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<String?> _pinDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN Belirle'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: '4 haneli PIN',
            hintText: '0000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  String _bugunTarih() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} itibarıyla';
  }

  Future<void> _kaydetTercih(String anahtar, bool deger) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(anahtar, deger);
    } catch (_) {
      /* opsiyonel */
    }
  }
}
