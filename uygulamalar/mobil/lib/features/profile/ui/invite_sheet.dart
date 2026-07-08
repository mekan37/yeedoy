import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../data/referral_repository.dart';
import '../domain/referral_provider.dart';

void showInviteSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _InviteSheet(),
  );
}

class _InviteSheet extends ConsumerWidget {
  const _InviteSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(referralStatsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Header row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Arkadaşını Davet Et',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Topluluk büyüdükçe içerikler daha zenginleşir.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(
                child: Text(
                  'Davet bilgileri yüklenemedi.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              data: (stats) => _InviteContent(stats: stats, scrollController: controller),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _InviteContent extends StatelessWidget {
  const _InviteContent({required this.stats, required this.scrollController});

  final ReferralStats stats;
  final ScrollController scrollController;

  String get _inviteLink => 'https://yeedoy.app/davet/${stats.referralCode.toLowerCase()}';
  String get _shareText =>
      'Seni Yeedoy\'a davet ediyorum! Yakınındaki restoranları keşfet, '
      'menü ve fiyatlarını karşılaştır. Davet kodum: ${stats.referralCode} — $_inviteLink';

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _IllustrationCard(),
        const SizedBox(height: 12),
        _CommunityCard(invitedCount: stats.invitedCount),
        const SizedBox(height: 20),
        _CodeSection(referralCode: stats.referralCode),
        const SizedBox(height: 12),
        _LinkSection(inviteLink: _inviteLink),
        const SizedBox(height: 20),
        _ShareOptions(inviteLink: _inviteLink, shareText: _shareText),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: _shareText),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Davet Gönder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Daha sonra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Illustration card ─────────────────────────────────────────────────────────

class _IllustrationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 14,
            left: 40,
            child: Icon(Icons.add, size: 10, color: AppColors.primary),
          ),
          const Positioned(
            top: 22,
            right: 55,
            child: Icon(Icons.star_rounded, size: 8, color: AppColors.primary),
          ),
          const Positioned(
            bottom: 18,
            left: 60,
            child: Icon(Icons.star_rounded, size: 6, color: AppColors.primary),
          ),
          const Positioned(
            bottom: 14,
            right: 40,
            child: Icon(Icons.add, size: 10, color: AppColors.primary),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PersonCircle(),
              const SizedBox(width: 12),
              _ArrowIcon(),
              const SizedBox(width: 12),
              _PersonCircle(),
              const SizedBox(width: 12),
              _ArrowIcon(),
              const SizedBox(width: 12),
              _PersonCircle(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary.withValues(alpha: 0.6),
        size: 26,
      ),
    );
  }
}

class _ArrowIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: AppColors.primary.withValues(alpha: 0.4),
      size: 22,
    );
  }
}

// ── Community card (replaces fake RewardCard) ─────────────────────────────────

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.invitedCount});
  final int invitedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatSide(
                icon: Icons.group_rounded,
                label: 'Davet ettiğin',
                value: '$invitedCount kişi',
              ),
            ),
            VerticalDivider(
              color: AppColors.primary.withValues(alpha: 0.2),
              thickness: 1,
              width: 32,
            ),
            const Expanded(
              child: _StatSide(
                icon: Icons.restaurant_menu_rounded,
                label: 'Topluluk',
                value: 'Yeedoy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSide extends StatelessWidget {
  const _StatSide({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Code section ──────────────────────────────────────────────────────────────

class _CodeSection extends StatelessWidget {
  const _CodeSection({required this.referralCode});
  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Davet Kodun',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  referralCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(
                onTap: () => _copy(context, referralCode, 'Kod kopyalandı'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Link section ──────────────────────────────────────────────────────────────

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.inviteLink});
  final String inviteLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Davet Linkin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.muted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inviteLink,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(
                onTap: () => _copy(context, inviteLink, 'Link kopyalandı'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Share options ─────────────────────────────────────────────────────────────

class _ShareOptions extends StatelessWidget {
  const _ShareOptions({required this.inviteLink, required this.shareText});
  final String inviteLink;
  final String shareText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paylaş',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ShareButton(
                label: 'WhatsApp',
                iconWidget: _CircleIcon(
                  color: const Color(0xFF25D366),
                  child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                ),
                onTap: () => _launchUrl(
                  'whatsapp://send?text=${Uri.encodeComponent(shareText)}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                label: 'Telegram',
                iconWidget: _CircleIcon(
                  color: const Color(0xFF2AABEE),
                  child: const Icon(Icons.telegram_rounded, color: Colors.white, size: 22),
                ),
                onTap: () => _launchUrl(
                  'tg://msg?text=${Uri.encodeComponent(shareText)}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                label: 'SMS',
                iconWidget: _CircleIcon(
                  color: const Color(0xFF34C759),
                  child: const Icon(Icons.sms_rounded, color: Colors.white, size: 22),
                ),
                onTap: () => _launchUrl(
                  'sms:?body=${Uri.encodeComponent(shareText)}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                label: 'Kopyala',
                iconWidget: _CircleIcon(
                  color: AppColors.primarySoft,
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                onTap: () => _copy(context, inviteLink, 'Link kopyalandı'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

// ── Copy button ───────────────────────────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 14, color: AppColors.textStrong),
            SizedBox(width: 4),
            Text(
              'Kopyala',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _copy(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
