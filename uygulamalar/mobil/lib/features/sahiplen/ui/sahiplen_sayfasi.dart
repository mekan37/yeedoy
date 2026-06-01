import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../domain/sahiplen_saglayicisi.dart';

class SahiplenSayfasi extends ConsumerStatefulWidget {
  final String? isletmeId;
  const SahiplenSayfasi({super.key, this.isletmeId});

  @override
  ConsumerState<SahiplenSayfasi> createState() => _SahiplenSayfasiState();
}

class _SahiplenSayfasiState extends ConsumerState<SahiplenSayfasi> {
  int _adim = 0;
  final _adimlar = 3;

  // Form alanları
  final _isletmeAdCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _belgeBilgiCtrl = TextEditingController();
  bool _gonderiyor = false;
  String? _hata;
  bool _basarili = false;

  @override
  void dispose() {
    _isletmeAdCtrl.dispose();
    _telefonCtrl.dispose();
    _emailCtrl.dispose();
    _belgeBilgiCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (_isletmeAdCtrl.text.trim().isEmpty) {
      setState(() => _hata = 'İşletme adı zorunludur.');
      return;
    }
    if (_telefonCtrl.text.trim().isEmpty) {
      setState(() => _hata = 'Telefon numarası zorunludur.');
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) {
      context.go('/login?redirect=/sahiplen');
      return;
    }

    setState(() {
      _gonderiyor = true;
      _hata = null;
    });

    try {
      await ref
          .read(sahiplenBasvuruProvider.notifier)
          .gonder(
            isletmeId: widget.isletmeId,
            isletmeAdi: _isletmeAdCtrl.text.trim(),
            telefon: _telefonCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            belgeBilgi: _belgeBilgiCtrl.text.trim(),
          );
      if (mounted) {
        setState(() {
          _basarili = true;
          _gonderiyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hata = 'Başvuru gönderilemedi: $e';
          _gonderiyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(title: const Text('İşletmeyi Sahiplen')),
      body: _basarili
          ? _BasvuruBasarili(isletmeAdi: _isletmeAdCtrl.text)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IlerlemeGostergesi(adim: _adim, toplamAdim: _adimlar),
                  const SizedBox(height: 24),
                  if (_adim == 0)
                    ..._adim0()
                  else if (_adim == 1)
                    ..._adim1()
                  else
                    ..._adim2(),
                  const SizedBox(height: 24),
                  if (_hata != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _hata!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  Row(
                    children: [
                      if (_adim > 0)
                        OutlinedButton(
                          onPressed: () => setState(() => _adim--),
                          child: const Text('Geri'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _gonderiyor
                            ? null
                            : () {
                                if (_adim < _adimlar - 1) {
                                  setState(() {
                                    _hata = null;
                                    _adim++;
                                  });
                                } else {
                                  _gonder();
                                }
                              },
                        child: _gonderiyor
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_adim < _adimlar - 1 ? 'Devam' : 'Başvur'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _adim0() => [
    const _BaslikBlok(
      numara: '1',
      baslik: 'İşletme Bilgileri',
      aciklama: 'Sahiplenmek istediğiniz işletmenin temel bilgilerini girin.',
    ),
    const SizedBox(height: 20),
    if (widget.isletmeId != null)
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.store_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seçili işletme için başvuru yapıyorsunuz',
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    if (widget.isletmeId != null) const SizedBox(height: 16),
    TextField(
      controller: _isletmeAdCtrl,
      decoration: const InputDecoration(
        labelText: 'İşletme Adı *',
        prefixIcon: Icon(Icons.store_outlined),
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _telefonCtrl,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'İş Telefonu *',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    ),
  ];

  List<Widget> _adim1() => [
    const _BaslikBlok(
      numara: '2',
      baslik: 'İletişim & Belge',
      aciklama: 'Doğrulama için iletişim bilgisi ve işletme belgesini girin.',
    ),
    const SizedBox(height: 20),
    TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'İş E-postası',
        prefixIcon: Icon(Icons.email_outlined),
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _belgeBilgiCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Vergi No / Ticaret Sicil No',
        hintText: 'İşletme tescil bilgilerinizi girin',
        prefixIcon: Icon(Icons.description_outlined),
        alignLabelWithHint: true,
      ),
    ),
  ];

  List<Widget> _adim2() => [
    const _BaslikBlok(
      numara: '3',
      baslik: 'Onay',
      aciklama: 'Bilgilerinizi kontrol edin ve başvuruyu gönderin.',
    ),
    const SizedBox(height: 20),
    _OzetSatir(etiket: 'İşletme Adı', deger: _isletmeAdCtrl.text),
    _OzetSatir(etiket: 'Telefon', deger: _telefonCtrl.text),
    if (_emailCtrl.text.isNotEmpty)
      _OzetSatir(etiket: 'E-posta', deger: _emailCtrl.text),
    if (_belgeBilgiCtrl.text.isNotEmpty)
      _OzetSatir(etiket: 'Belge', deger: _belgeBilgiCtrl.text),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'Başvurunuz 1-3 iş günü içinde incelenecektir. Doğrulama sonucu kayıtlı e-postanıza iletilecektir.',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    ),
  ];
}

class _IlerlemeGostergesi extends StatelessWidget {
  final int adim;
  final int toplamAdim;
  const _IlerlemeGostergesi({required this.adim, required this.toplamAdim});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adım ${adim + 1} / $toplamAdim',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (adim + 1) / toplamAdim,
            minHeight: 6,
            backgroundColor: AppColors.card,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _BaslikBlok extends StatelessWidget {
  final String numara;
  final String baslik;
  final String aciklama;
  const _BaslikBlok({
    required this.numara,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numara,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                aciklama,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OzetSatir extends StatelessWidget {
  final String etiket;
  final String deger;
  const _OzetSatir({required this.etiket, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              etiket,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasvuruBasarili extends StatelessWidget {
  final String isletmeAdi;
  const _BasvuruBasarili({required this.isletmeAdi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Başvurunuz Alındı!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '"$isletmeAdi" için sahiplenme başvurunuz ekibimize iletildi. 1-3 iş günü içinde incelenecektir.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
