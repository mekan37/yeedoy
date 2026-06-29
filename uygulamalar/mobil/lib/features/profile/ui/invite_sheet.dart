import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';

void showInviteSheet(BuildContext context, {required String referralCode}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _InviteSheet(referralCode: referralCode),
  );
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.referralCode});

  final String referralCode;

  String get _inviteLink => 'yeedoy.app.link/${referralCode.toLowerCase()}';
  String get _shareText =>
      'Yeedoy\'da harika restoranlar keşfediyorum! Sen de katıl, '
      'davet kodum ile 25 TL indirim kazan: https://$_inviteLink';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
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
            'Davet ettiğin her arkadaş için ödül kazan!',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          // ── Scrollable content ───────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _IllustrationCard(),
                const SizedBox(height: 12),
                _RewardCard(),
                const SizedBox(height: 20),
                _CodeSection(referralCode: referralCode),
                const SizedBox(height: 12),
                _LinkSection(inviteLink: _inviteLink),
                const SizedBox(height: 20),
                _ShareOptions(inviteLink: _inviteLink, shareText: _shareText),
                const SizedBox(height: 12),
                _StatsBar(),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration card ─────────────────────────────────────────────────────────

class _IllustrationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // sparkle decorations
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
          // Main row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PersonCircle(),
              const SizedBox(width: 16),
              _GiftCircle(),
              const SizedBox(width: 16),
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary.withValues(alpha: 0.6),
        size: 32,
      ),
    );
  }
}

class _GiftCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }
}

// ── Reward card ───────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
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
              child: _RewardSide(
                icon: Icons.star_rounded,
                label: 'Sen kazan:',
                value: '50 puan',
              ),
            ),
            VerticalDivider(
              color: AppColors.primary.withValues(alpha: 0.2),
              thickness: 1,
              width: 32,
            ),
            Expanded(
              child: _RewardSide(
                icon: Icons.local_offer_rounded,
                label: 'Arkadaşın kazan:',
                value: '25 TL indirim',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardSide extends StatelessWidget {
  const _RewardSide({
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
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
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
          'Referans Kodun',
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(
                onTap: () => _copy(context, referralCode, 'Referans kodu kopyalandı'),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(
                onTap: () => _copy(
                  context,
                  'https://$inviteLink',
                  'Davet linki kopyalandı',
                ),
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
          'Paylaşım Seçenekleri',
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
                label: 'Bağlantıyı\nKopyala',
                iconWidget: _CircleIcon(
                  color: AppColors.primarySoft,
                  child: const Icon(
                    Icons.link_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                onTap: () => _copy(
                  context,
                  'https://$inviteLink',
                  'Davet linki kopyalandı',
                ),
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

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '3 arkadaş katıldı',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            '150 puan kazandın',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
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
