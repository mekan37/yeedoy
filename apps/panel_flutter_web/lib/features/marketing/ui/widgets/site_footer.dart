import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../legal/legal_routes.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0x1F334155))),
      ),
      padding: EdgeInsets.fromLTRB(24, compact ? 12 : 28, 24, compact ? 12 : 28),
      child: compact ? _CompactFooter() : _FullFooter(),
    );
  }
}

class _CompactFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            const Text(
              'Yeedoy © 2026',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                for (final link in LegalRoutes.footerLinks)
                  InkWell(
                    onTap: () => context.go(LegalRoutes.detail(link.slug)),
                    child: Text(
                      link.label,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () => context.go(LegalRoutes.hub),
                  child: const Text(
                    'Legal Merkezi',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FullFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 28,
          spacing: 28,
          children: [
            const _FooterLead(),
            _FooterColumn(
              title: 'Legal',
              items: LegalRoutes.footerLinks
                  .map(
                    (link) => _FooterItem(
                      link.label,
                      LegalRoutes.detail(link.slug),
                    ),
                  )
                  .toList(),
            ),
            _FooterColumn(
              title: 'Ürün',
              items: LegalRoutes.productLinks
                  .map(
                    (link) => _FooterItem(
                      link.label,
                      LegalRoutes.detail(link.slug),
                    ),
                  )
                  .toList(),
            ),
            _FooterColumn(
              title: 'Uygulamalar',
              items: [
                _FooterItem(
                  'Google Play',
                  AppConfig.playStoreUrl,
                  external: true,
                ),
                _FooterItem(
                  'App Store',
                  AppConfig.appStoreUrl,
                  external: true,
                ),
                _FooterItem('Tüm Legal Belgeler', LegalRoutes.hub),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLead extends StatelessWidget {
  const _FooterLead();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Yeedoy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Yeedoy, QR menü ve dijital menü operasyonlarını şeffaf, güncel ve güven veren bir yapıda sunmak için tasarlanmış aracı hizmet sağlayıcı platformdur.',
            style: TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
          ),
          SizedBox(height: 12),
          Text(
            'Kurumsal bilgiler yayına alınırken aşağıdaki alanlar güncellenecektir: [Şirket Adı], [Adres], [Vergi No], [Hukuki E-posta]',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});

  final String title;
  final List<_FooterItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in items)
            InkWell(
              onTap: () => item.external
                  ? _openExternal(item.href)
                  : context.go(item.href),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  item.label,
                  style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterItem {
  const _FooterItem(this.label, this.href, {this.external = false});

  final String label;
  final String href;
  final bool external;
}

Future<void> _openExternal(String raw) async {
  final uri = Uri.tryParse(raw);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
