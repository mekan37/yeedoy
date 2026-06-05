import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/colors.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';

class YerlestirSayfasi extends StatefulWidget {
  final String businessId;
  const YerlestirSayfasi({super.key, required this.businessId});

  @override
  State<YerlestirSayfasi> createState() => _YerlestirSayfasiState();
}

class _YerlestirSayfasiState extends State<YerlestirSayfasi>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _secilenBoyut = '600x400';
  bool _otomatikGuncelle = true;
  bool _karanlikMod = false;

  static const _boyutlar = [
    {
      'etiket': 'Küçük (300×200)',
      'deger': '300x200',
      'en': 300.0,
      'boy': 200.0,
    },
    {'etiket': 'Orta (600×400)', 'deger': '600x400', 'en': 600.0, 'boy': 400.0},
    {
      'etiket': 'Geniş (900×600)',
      'deger': '900x600',
      'en': 900.0,
      'boy': 600.0,
    },
    {
      'etiket': 'Özel (tam genişlik)',
      'deger': '100%x400',
      'en': null,
      'boy': 400.0,
    },
  ];

  String get _menuUrl => 'https://yeedoy.com/gomulu/menu/${widget.businessId}';
  String get _publicMenuUrl => 'https://yeedoy.com/m/${widget.businessId}';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _embedKodu {
    final boyut = _boyutlar.firstWhere((b) => b['deger'] == _secilenBoyut);
    final en = boyut['en'] == null
        ? '100%'
        : '${(boyut['en'] as double).toInt()}px';
    final boy = '${(boyut['boy'] as double).toInt()}px';
    final tema = _karanlikMod ? 'dark' : 'light';
    final base = 'https://yeedoy.com';
    return '<iframe\n'
        '  src="$base/gomulu/menu/${widget.businessId}?theme=$tema&auto=${_otomatikGuncelle ? '1' : '0'}"\n'
        '  width="$en"\n'
        '  height="$boy"\n'
        '  frameborder="0"\n'
        '  loading="lazy"\n'
        '  allowtransparency="true"\n'
        '  title="Yeedoy Menü Widget"\n'
        '></iframe>';
  }

  String get _jsKodu {
    final tema = _karanlikMod ? 'dark' : 'light';
    return '<div id="yeedoy-menu" data-business="${widget.businessId}" data-theme="$tema"></div>\n'
        '<script src="https://yeedoy.com/embed.js" async></script>';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: Text('Menüyü Web Sitene Yerleştir')),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'iframe Kodu'),
              Tab(text: 'JS Widget'),
              Tab(text: 'Paylaşım'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _IframeTab(
                  embedKodu: _embedKodu,
                  boyutlar: _boyutlar,
                  secilenBoyut: _secilenBoyut,
                  otomatikGuncelle: _otomatikGuncelle,
                  karanlikMod: _karanlikMod,
                  onBoyutSecildi: (v) => setState(() => _secilenBoyut = v),
                  onOtomatikGuncelle: (v) =>
                      setState(() => _otomatikGuncelle = v),
                  onKaranlikMod: (v) => setState(() => _karanlikMod = v),
                ),
                _JsTab(jsKodu: _jsKodu),
                _PaylasimTab(
                  businessId: widget.businessId,
                  menuUrl: _menuUrl,
                  publicMenuUrl: _publicMenuUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IframeTab extends StatelessWidget {
  final String embedKodu;
  final List<Map<String, Object?>> boyutlar;
  final String secilenBoyut;
  final bool otomatikGuncelle;
  final bool karanlikMod;
  final ValueChanged<String> onBoyutSecildi;
  final ValueChanged<bool> onOtomatikGuncelle;
  final ValueChanged<bool> onKaranlikMod;

  const _IframeTab({
    required this.embedKodu,
    required this.boyutlar,
    required this.secilenBoyut,
    required this.otomatikGuncelle,
    required this.karanlikMod,
    required this.onBoyutSecildi,
    required this.onOtomatikGuncelle,
    required this.onKaranlikMod,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecmeBaslik('Boyut'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: boyutlar.map((b) {
              final secili = secilenBoyut == b['deger'];
              return FilterChip(
                label: Text(b['etiket'] as String),
                selected: secili,
                onSelected: (_) => onBoyutSecildi(b['deger'] as String),
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _SecmeBaslik('Seçenekler'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Otomatik Güncelleme',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Menü değişikliklerini otomatik yansıt',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            value: otomatikGuncelle,
            activeThumbColor: AppColors.primary,
            onChanged: onOtomatikGuncelle,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Karanlık Mod',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Widget\'ı karanlık temada göster',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            value: karanlikMod,
            activeThumbColor: AppColors.primary,
            onChanged: onKaranlikMod,
          ),
          const SizedBox(height: 16),
          const _SecmeBaslik('Embed Kodu'),
          const SizedBox(height: 8),
          _KodBlok(kod: embedKodu),
        ],
      ),
    );
  }
}

class _JsTab extends StatelessWidget {
  final String jsKodu;
  const _JsTab({required this.jsKodu});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: const Text(
                    'JS widget, iframe\'e göre daha esnek özelleştirme sunar ve SEO için optimize edilmiştir.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SecmeBaslik('JS Kodu'),
          const SizedBox(height: 8),
          _KodBlok(kod: jsKodu),
          const SizedBox(height: 16),
          const _SecmeBaslik('data-* Özellikleri'),
          const SizedBox(height: 8),
          _OzellikSatiri(
            ozellik: 'data-business',
            aciklama: 'İşletme ID\'si (zorunlu)',
          ),
          _OzellikSatiri(
            ozellik: 'data-theme',
            aciklama: '"light" veya "dark"',
          ),
          _OzellikSatiri(ozellik: 'data-lang', aciklama: '"tr" veya "en"'),
          _OzellikSatiri(
            ozellik: 'data-max-items',
            aciklama: 'Gösterilecek maksimum ürün sayısı',
          ),
        ],
      ),
    );
  }
}

// ── Sosyal Paylaşım Tab ───────────────────────────────────────────────────────

class _PaylasimTab extends StatelessWidget {
  final String businessId;
  final String menuUrl;
  final String publicMenuUrl;

  const _PaylasimTab({
    required this.businessId,
    required this.menuUrl,
    required this.publicMenuUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social preview card
          const _SecmeBaslik('Sosyal Medya Önizlemesi'),
          const SizedBox(height: 12),
          _SosyalOnizlemeKarti(url: publicMenuUrl),

          const SizedBox(height: 24),
          const _SecmeBaslik('Menü Linki'),
          const SizedBox(height: 8),

          // URL display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    publicMenuUrl,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  color: AppColors.muted,
                  tooltip: 'Kopyala',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: publicMenuUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link kopyalandı!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Share buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Paylaş'),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: '🍽️ Menümüze göz atın!\n$publicMenuUrl',
                        subject: 'Yeedoy Menü',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_outlined, size: 18),
                  label: const Text('QR Kodu İndir'),
                  onPressed: () => _showQrDialog(context, publicMenuUrl),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const _SecmeBaslik('Paylaşım Kanalları'),
          const SizedBox(height: 12),

          // Platform share hints
          _PaylasimKanali(
            ikon: Icons.message_outlined,
            baslik: 'WhatsApp',
            aciklama: 'Menü linkini WhatsApp grubunuza gönderin',
            onTap: () {
              final whatsappUrl =
                  'https://wa.me/?text=${Uri.encodeComponent('🍽️ Menümüze bakın: $publicMenuUrl')}';
              Clipboard.setData(ClipboardData(text: whatsappUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WhatsApp linki kopyalandı!')),
              );
            },
          ),
          _PaylasimKanali(
            ikon: Icons.camera_alt_outlined,
            baslik: 'Instagram',
            aciklama: 'Menü QR kodunu Story olarak paylaşın',
            onTap: () => _showQrDialog(context, publicMenuUrl),
          ),
          _PaylasimKanali(
            ikon: Icons.language_outlined,
            baslik: 'Web Sitenize Yerleştirin',
            aciklama: 'iframe veya JS widget ile sitenize entegre edin',
            onTap: () {
              DefaultTabController.of(context).animateTo(0);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showQrDialog(BuildContext context, String url) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Menü QR Kodu', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              url,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'QR kodunu ekran görüntüsü alarak paylaşabilirsiniz.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Paylaş'),
            onPressed: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(
                ShareParams(text: 'Menü QR: $url', subject: 'Yeedoy Menü QR'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SosyalOnizlemeKarti extends StatelessWidget {
  final String url;
  const _SosyalOnizlemeKarti({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (hero)
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_menu_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeedoy — Menümüze Bakın',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tüm menü ürünlerimiz, fiyatlarımız ve kampanyalarımız burada.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  url,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaylasimKanali extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _PaylasimKanali({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(ikon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        baslik,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        aciklama,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      onTap: onTap,
    );
  }
}

// ── Kod bloğu ─────────────────────────────────────────────────────────────────

class _KodBlok extends StatelessWidget {
  final String kod;
  const _KodBlok({required this.kod});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF252836),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Text(
                  'HTML',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: kod));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kod kopyalandı!')),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_outlined,
                        size: 14,
                        color: Color(0xFF8B949E),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kopyala',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              kod,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFE6EDF3),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecmeBaslik extends StatelessWidget {
  final String baslik;
  const _SecmeBaslik(this.baslik);

  @override
  Widget build(BuildContext context) {
    return Text(
      baslik.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _OzellikSatiri extends StatelessWidget {
  final String ozellik;
  final String aciklama;
  const _OzellikSatiri({required this.ozellik, required this.aciklama});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ozellik,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aciklama,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
