import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../legal_catalog.dart';
import '../legal_linking.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Yasal ve Gizlilik',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _IntroCard(),
          const SizedBox(height: 16),
          _LinkGroup(
            title: 'Zorunlu sözleşmeler',
            items: [
              ...LegalCatalog.requiredAcceptanceLinks,
              LegalCatalog.cookies,
            ],
          ),
          const SizedBox(height: 16),
          _LinkGroup(
            title: 'Topluluk ve güven',
            items: LegalCatalog.trustLinks,
          ),
          const SizedBox(height: 16),
          const _ActionCard(),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ana legal merkezi yeedoy.com üzerinde yayınlanır.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Mobil uygulama; kullanım şartları, gizlilik politikası, çerez politikası, topluluk kuralları ve trust & safety sayfalarını doğrudan ana web yüzündeki legal merkezine açar. Veri talebi ve hesap silme işlemlerini profil ayarlarından başlatabilirsiniz.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _LinkGroup extends StatelessWidget {
  const _LinkGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<LegalLinkDescriptor> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            _LinkItem(item: items[index]),
            if (index != items.length - 1)
              const Divider(height: 18, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  const _LinkItem({required this.item});

  final LegalLinkDescriptor item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
      subtitle: Text(item.description),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => _openUrl(context, item.url),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kullanıcı işlemleri',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Hesap silme, verilerimi dışa aktar ve gizlilik başvurusu aksiyonları profil ayarlarında yer alır. Bu akışlar kullanıcı hesabına bağlı olarak backend üzerinde kayıt altına alınır ve bekleyen başvurular tekrar gönderilmez.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  try {
    await openLegalUrl(url);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppErrorMapper.message(error))),
    );
  }
}
