import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hata_esleyici.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../domain/kimlik_bildiricisi.dart';
import '../domain/kimlik_durum.dart';
import '../../shared/ui/p_logo.dart';
import '../../../uygulama/tema/renkler.dart';

class GirisSayfasi extends ConsumerStatefulWidget {
  const GirisSayfasi({super.key});

  @override
  ConsumerState<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends ConsumerState<GirisSayfasi> {
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _sifreGoster = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _sifremiUnuttumDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    bool gonderiliyor = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Şifre Sıfırla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'E-posta adresinize şifre sıfırlama bağlantısı gönderilecektir.',
                style: TextStyle(fontSize: 13, color: PColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: gonderiliyor
                  ? null
                  : () async {
                      final email = ctrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) return;
                      setDialogState(() => gonderiliyor = true);
                      try {
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(email);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Sıfırlama bağlantısı $email adresine gönderildi.'),
                              backgroundColor: PColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(HataEsleyici.mesaj(e)),
                              backgroundColor: PColors.danger,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setDialogState(() => gonderiliyor = false);
                      }
                    },
              child: gonderiliyor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _girisYap() async {
    final email = _emailCtrl.text.trim();
    final sifre = _sifreCtrl.text;
    if (email.isEmpty || sifre.isEmpty) return;
    await ref
        .read(kimlikProvider.notifier)
        .girisYap(email: email, sifre: sifre);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kimlikProvider);
    final yukleniyor = state.isLoading;
    final hata = state.hasError
        ? HataEsleyici.mesaj(state.error!)
        : state.valueOrNull is KimlikYetkisiz
            ? (state.valueOrNull as KimlikYetkisiz).mesaj
            : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PLogo(),
                  const SizedBox(height: 8),
                  Text(
                    'İşletme Paneli',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _sifreCtrl,
                    obscureText: !_sifreGoster,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _girisYap(),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_sifreGoster
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _sifreGoster = !_sifreGoster),
                      ),
                    ),
                  ),
                  if (hata != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: PColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: PColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        hata,
                        style: const TextStyle(
                          color: PColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: yukleniyor ? null : _girisYap,
                    child: yukleniyor
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Giriş Yap'),
                  ),
                  // P-11: Şifremi unuttum
                  TextButton(
                    onPressed: () => _sifremiUnuttumDialog(context),
                    child: const Text('Şifremi unuttum'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
