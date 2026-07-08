import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../legal_linking.dart';

// ── Item definitions ─────────────────────────────────────────────────────────

enum _LegalAction { openUrl, deleteRequest, support }

class _LegalItem {
  const _LegalItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    this.url,
  });

  final IconData icon;
  final String title;
  final String description;
  final _LegalAction action;
  final String? url;
}

final _kItems = <_LegalItem>[
  _LegalItem(
    icon: Icons.article_outlined,
    title: 'Kullanım Şartları',
    description: 'Uygulamamızı kullanırken uymanız gereken kurallar ve koşullar.',
    action: _LegalAction.openUrl,
    url: AppConfig.termsUrl,
  ),
  _LegalItem(
    icon: Icons.verified_user_outlined,
    title: 'Gizlilik Politikası',
    description:
        'Kişisel verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu inceleyin.',
    action: _LegalAction.openUrl,
    url: AppConfig.privacyPolicyUrl,
  ),
  _LegalItem(
    icon: Icons.cookie_outlined,
    title: 'Çerez Politikası',
    description:
        'Çerezlerin nasıl kullanıldığını ve tercihlerinizi nasıl yönetebileceğinizi öğrenin.',
    action: _LegalAction.openUrl,
    url: AppConfig.cookiesUrl,
  ),
  _LegalItem(
    icon: Icons.copyright_outlined,
    title: 'Telif Hakkı Politikası',
    description: 'Uygulama içeriği, marka ve diğer fikri mülkiyet haklarına dair bilgiler.',
    action: _LegalAction.openUrl,
    url: AppConfig.copyrightPolicyUrl,
  ),
  _LegalItem(
    icon: Icons.person_outline,
    title: 'KVKK Aydınlatma Metni',
    description: 'Kişisel Verilerin Korunması Kanunu kapsamında aydınlatma metnimiz.',
    action: _LegalAction.openUrl,
    url: AppConfig.kvkkUrl,
  ),
  _LegalItem(
    icon: Icons.balance_outlined,
    title: 'Mesafeli Satış Sözleşmesi',
    description: 'Mesafeli satışa ilişkin sözleşme şartlarını görüntüleyin.',
    action: _LegalAction.openUrl,
    url: AppConfig.legalUrl('distance-sales'),
  ),
  _LegalItem(
    icon: Icons.delete_outline_rounded,
    title: 'Veri Silme Talebi',
    description:
        'Kişisel verilerinizin silinmesi veya anonim hale getirilmesi için talepte bulunun.',
    action: _LegalAction.deleteRequest,
  ),
  _LegalItem(
    icon: Icons.headset_mic_outlined,
    title: 'Yasal Destek',
    description: 'Yasal konularla ilgili destek almak için bizimle iletişime geçin.',
    action: _LegalAction.support,
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/discover'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textStrong,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Yasal İşlemler',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  _NotificationBell(),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Subtitle ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Uygulamamızı kullanırken haklarınızı, yükümlülüklerinizi ve verilerinizin nasıl işlendiğini öğrenin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Items list ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _kItems.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 72,
                        ),
                      _LegalRow(
                        item: _kItems[i],
                        onTap: () => _handleTap(context, _kItems[i]),
                        isFirst: i == 0,
                        isLast: i == _kItems.length - 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Footer card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Haklarınızı korumak ve şeffaflık sağlamak bizim için önemlidir. Herhangi bir sorunuzda destek ekibimizle iletişime geçebilirsiniz.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, _LegalItem item) async {
    switch (item.action) {
      case _LegalAction.openUrl:
        if (item.url != null) {
          try {
            await openLegalUrl(item.url!);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppErrorMapper.message(e))),
            );
          }
        }
      case _LegalAction.deleteRequest:
        if (context.mounted) context.push('/data-deletion');
      case _LegalAction.support:
        if (context.mounted) context.push('/help-support');
    }
  }

}

// ── Legal row ─────────────────────────────────────────────────────────────────

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.item,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  final _LegalItem item;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/inbox'),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textStrong,
              size: 18,
            ),
          ),
        ),
        const Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            radius: 4,
            backgroundColor: AppColors.danger,
          ),
        ),
      ],
    );
  }
}
