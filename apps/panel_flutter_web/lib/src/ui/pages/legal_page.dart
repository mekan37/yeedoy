import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/constants/app_strings.dart';
import '../components/app_card.dart';
import '../components/app_scaffold.dart';
import '../components/app_section_header.dart';

class LegalPage extends ConsumerWidget {
  const LegalPage({super.key});

  static const _supportEmail = 'support@yeedoy.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardrails = ref.watch(productGuardrailOverridesProvider);
    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Yasal ve Güven',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const AppSectionHeader(title: 'KVKK / GDPR'),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.appName} kişisel verileri yalnızca hizmeti sunmak için işler. '
            'Açık rıza gerektiren işlemler için onay alınır, talep halinde veriler silinir '
            'veya taşınabilir şekilde paylaşılır.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veri kategorileri: profil, konum, cihaz bilgisi, kullanım analitiği. '
                  'Haklar: erişim, düzeltme, silme, itiraz, taşınabilirlik.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.privacyPolicyUrl),
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Gizlilik Politikası'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.kvkkUrl),
                      icon: const Icon(Icons.gavel_outlined),
                      label: const Text('KVKK Metni'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(AppConfig.gdprUrl),
                      icon: const Icon(Icons.public_outlined),
                      label: const Text('GDPR Metni'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Başvuru: e-posta ile talep oluştur.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionHeader(title: 'Foto Telif Bildirimi'),
          const SizedBox(height: 6),
          const Text(
            'Menü ve mekan fotoğrafları telif hakkına tabi olabilir. '
            'İhlal gördüğünde Bildir > Telif ile iletebilirsin.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telif bildirimi için içerik bağlantısı, kanıt ve kısa açıklama yeterlidir. '
                  'Doğrulanan ihlaller içerikten kaldırılır.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openUrl(AppConfig.copyrightPolicyUrl),
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Telif Politikası'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionHeader(title: 'İşletme Sahipliği İtiraz'),
          const SizedBox(height: 6),
          const Text(
            'Sahiplik talebi reddedildiyse itiraz edebilirsin. '
            'Belgelerin tekrar incelenir.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İtiraz için gerekli bilgiler:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• İşyeri ünvanı ve vergi/ruhsat bilgisi\n'
                  '• Yetkilendirme belgesi\n'
                  '• İletişim telefonu',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _sendMail(_supportEmail),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('İtiraz E-postası Gönder'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionHeader(title: 'Ürün İlkeleri'),
          const SizedBox(height: 6),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yapılmaması gerekenler:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Herkese her şeyi açmak\n'
                  '• Sponsorlu içeriği gizlemek\n'
                  '• Owner hesaba yorum silme yetkisi vermek\n'
                  '• Büyüme için kalite eşiğini gevşetmek',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Policy: sponsor etiketi zorunlu=${guardrails.requireSponsoredLabel}, '
                  'min sponsor trust=${guardrails.minSponsoredTrustScore.toStringAsFixed(2)}, '
                  'owner yorum silme=${guardrails.ownerCanDeleteReviews}.',
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Güncel politika metinleri ve detaylar web sitesinde yayımlanır.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> _sendMail(String email) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {'subject': 'Yeedoy - Sahiplik İtirazı'},
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

