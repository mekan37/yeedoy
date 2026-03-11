import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../legal/data/legal_registry.dart';
import '../../legal/legal_routes.dart';
import 'widgets/site_footer.dart';

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopNav(
                            onBusinessLogin: () => context.go('/isletme-giris'),
                            onBusinessRegister: () =>
                                context.go('/isletme-kayit'),
                          ),
                          const SizedBox(height: 28),
                          _HeroSection(
                            onBusinessLogin: () => context.go('/isletme-giris'),
                            onBusinessRegister: () =>
                                context.go('/isletme-kayit'),
                            onOpenLegalHub: () =>
                                context.go(LegalRoutes.hub),
                          ),
                          const SizedBox(height: 32),
                          const _AssuranceStrip(),
                          const SizedBox(height: 24),
                          const _FeatureSection(),
                          const SizedBox(height: 24),
                          const _HowItWorksSection(),
                          const SizedBox(height: 24),
                          const _BenefitSection(),
                          const SizedBox(height: 24),
                          const _TrustSection(),
                          const SizedBox(height: 24),
                          _CtaSection(
                            onBusinessLogin: () => context.go('/isletme-giris'),
                            onBusinessRegister: () =>
                                context.go('/isletme-kayit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  static Future<void> _openExternal(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.onBusinessLogin,
    required this.onBusinessRegister,
  });

  final VoidCallback onBusinessLogin;
  final VoidCallback onBusinessRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Yeedoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          const Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _NavLabel('Ürün'),
              _NavLabel('QR Akışı'),
              _NavLabel('Güven'),
              _NavLabel('Legal'),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onBusinessLogin,
                child: const Text('İşletme Girişi'),
              ),
              FilledButton(
                onPressed: onBusinessRegister,
                child: const Text('İşletme Kaydı'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.slate,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onBusinessLogin,
    required this.onBusinessRegister,
    required this.onOpenLegalHub,
  });

  final VoidCallback onBusinessLogin;
  final VoidCallback onBusinessRegister;
  final VoidCallback onOpenLegalHub;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F1D1D), Color(0xFF0F172A)],
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 24,
        spacing: 24,
        children: [
          SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Kurumsal QR menü operasyonu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Yeedoy, restoran ve işletmeler için güven veren dijital menü ve QR dağıtım altyapısı kurar.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Landing, legal merkezi ve işletme paneli aynı mimaride birleşir. Menü yönetimi panelde kalır; public QR deneyimi hızlı, okunabilir ve güncel kalır.',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 16,
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onBusinessRegister,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('İşletmemi Başlat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onBusinessLogin,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Panel Girişi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => WebHomePage._openExternal(
                        AppConfig.publicQrWebUrl,
                      ),
                      icon: const Icon(Icons.qr_code_2_outlined),
                      label: const Text('Public QR Deneyimi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenLegalHub,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Legal Merkezi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _HeroChip(label: 'Güncel menü yayınları'),
                    _HeroChip(label: 'Trust & Safety politikaları'),
                    _HeroChip(label: 'Mobil kabul ve veri talebi akışları'),
                  ],
                ),
              ],
            ),
          ),
          const _MetricPanel(
            title: 'Yeedoy akışı',
            lines: [
              '1. Panelde menü oluştur',
              '2. QR ile masaya taşı',
              '3. Mobilde kabul ve veri haklarını yönet',
              '4. Trust & Safety ile yayını koru',
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 14),
          for (final line in lines) ...[
            Text(
              line,
              style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.7),
            ),
            const SizedBox(height: 8),
          ],
          const Divider(color: Colors.white24, height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _StoreButton(
                label: 'Google Play',
                icon: Icons.android,
                url: AppConfig.playStoreUrl,
              ),
              _StoreButton(
                label: 'App Store',
                icon: Icons.phone_iphone,
                url: AppConfig.appStoreUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => WebHomePage._openExternal(url),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssuranceStrip extends StatelessWidget {
  const _AssuranceStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SectionCard(
          title: '${LegalRegistry.count} hukuki doküman',
          body:
              'Ana web yüzündeki legal merkezi; kullanım, gizlilik, trust & safety ve işletme koşullarını tek URL yapısında sunar.',
        ),
        _SectionCard(
          title: 'Sürüm ${LegalRegistry.currentVersion}',
          body:
              'Mobil acceptance ve panel business acceptance kayıtları aktif policy sürümü ile eşleşecek şekilde tasarlanmıştır.',
        ),
        _SectionCard(
          title: _formatMarketingDate(LegalRegistry.currentLastUpdated),
          body:
              'Son güncelleme tarihi görünür tutulur; yeni sürüm yayınlandığında tekrar kabul akışları güvenli şekilde tetiklenebilir.',
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      runSpacing: 16,
      spacing: 16,
      children: [
        _SectionCard(
          title: 'Ürün ne yapar?',
          body:
              'Yeedoy; restoranların QR menü, dijital menü, halka açık paylaşım ve işletme paneli ihtiyaçlarını tek mimaride toplar.',
        ),
        _SectionCard(
          title: 'Nasıl çalışır?',
          body:
              'İşletme panelde menüsünü günceller, public QR deneyimi Next.js katmanında yayınlanır, kullanıcı kabul ve veri hakları ise mobil uygulamada yönetilir.',
        ),
        _SectionCard(
          title: 'Neden güven verir?',
          body:
              'Legal merkezi, trust & safety politikaları, versiyonlanan dokümanlar ve kabul kayıt altyapısı ana web yüzünde merkezi olarak yayımlanır.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 370),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(color: AppColors.slate, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'QR menü sistemi nasıl çalışır?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StepCard(
                index: '01',
                title: 'Panelde kur',
                body:
                    'İşletme bilgileri, menü yapısı, görseller ve paylaşım akışları panelden yönetilir.',
              ),
              _StepCard(
                index: '02',
                title: 'QR üret ve dağıt',
                body:
                    'Public menü bağlantısı QR ile fiziksel masaya, paket sipariş akışına veya vitrine taşınır.',
              ),
              _StepCard(
                index: '03',
                title: 'Kullanıcı güvenini koru',
                body:
                    'Mobil kabul, veri talebi, hesap silme ve şeffaf legal linkler tüm ekosisteme entegre olur.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(color: AppColors.slate, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitSection extends StatelessWidget {
  const _BenefitSection();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _BenefitTile(
          icon: Icons.restaurant_menu_outlined,
          title: 'Restoran ve işletme için faydalar',
          items: [
            'Güncel menüyü panelden tek merkezde yönetme',
            'QR menüyü fiziksel deneyime hızlı taşıma',
            'İşletme koşulları ve doğruluk beyanını süreç içine yerleştirme',
          ],
        ),
        _BenefitTile(
          icon: Icons.verified_user_outlined,
          title: 'Neden Yeedoy?',
          items: [
            'Landing, panel, legal merkezi ve mobil kabul akışları aynı mimaride kurgulanır',
            'Next.js yalnızca public QR yüzeyi olarak sınırlandırılır',
            'Versiyonlanan policy acceptance yapısı büyümeye uygundur',
          ],
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 572,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 14),
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.slate,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        spacing: 18,
        children: const [
          SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güven, şeffaflık ve güncellik',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Legal sayfalar ana web yüzünde yayımlanır, mobil kullanıcılar aynı belgelere doğrudan erişir ve kabul kayıtları versiyon bazında saklanır. Böylece yeni sürüm çıktığında tekrar kabul akışı güvenle tetiklenebilir.',
                  style: TextStyle(color: AppColors.slate, height: 1.7),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 420,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TrustBadge(label: 'Footer legal linkleri'),
                _TrustBadge(label: 'Versiyonlanan policies'),
                _TrustBadge(label: 'Hesap silme ve veri talepleri'),
                _TrustBadge(label: 'DMCA / DSA / Trust & Safety'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection({
    required this.onBusinessLogin,
    required this.onBusinessRegister,
  });

  final VoidCallback onBusinessLogin;
  final VoidCallback onBusinessRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        spacing: 18,
        children: [
          const SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İşletmenin QR menü altyapısını kur, legal çerçeveyi dağınık bırakma.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Panel, ana web yüzü, legal merkezi ve mobil acceptance akışı birlikte çalışacak şekilde tasarlanmıştır.',
                  style: TextStyle(color: Color(0xFFCBD5E1), height: 1.7),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: onBusinessRegister,
                child: const Text('İşletme Kaydını Başlat'),
              ),
              OutlinedButton(
                onPressed: onBusinessLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Panele Git'),
              ),
              OutlinedButton(
                onPressed: () => context.go(LegalRoutes.hub),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Legal Merkezi Aç'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatMarketingDate(DateTime value) {
  const months = <int, String>{
    1: 'Ocak',
    2: 'Şubat',
    3: 'Mart',
    4: 'Nisan',
    5: 'Mayıs',
    6: 'Haziran',
    7: 'Temmuz',
    8: 'Ağustos',
    9: 'Eylül',
    10: 'Ekim',
    11: 'Kasım',
    12: 'Aralık',
  };
  return '${value.day} ${months[value.month]} ${value.year}';
}
