import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../domain/notification_preferences_provider.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _Channel {
  const _Channel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

class _Category {
  _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
    required this.enabled,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  bool enabled;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool _showBanner = true;

  // Channel toggles
  bool _appNotifs = true;
  bool _emailNotifs = true;
  bool _smsNotifs = false;

  // Categories
  final List<_Category> _categories = [
    _Category(
      icon: Icons.campaign_outlined,
      title: 'Duyurular',
      subtitle: 'Önemli duyuru ve güncellemeler',
      iconColor: const Color(0xFF8B5CF6),
      iconBg: const Color(0xFFEDE9FE),
      enabled: true,
    ),
    _Category(
      icon: Icons.card_giftcard_outlined,
      title: 'Kampanyalar',
      subtitle: 'Özel kampanya ve fırsat bildirimleri',
      iconColor: const Color(0xFF3B82F6),
      iconBg: const Color(0xFFDBEAFE),
      enabled: true,
    ),
    _Category(
      icon: Icons.emoji_events_outlined,
      title: 'Başarılar ve Rozetler',
      subtitle: 'Rozet kazandığınızda ve başarılarınızda',
      iconColor: const Color(0xFFF97316),
      iconBg: const Color(0xFFFFEDD5),
      enabled: true,
    ),
    _Category(
      icon: Icons.calendar_month_outlined,
      title: 'Etkinlikler',
      subtitle: 'Etkinlik hatırlatmaları ve takvim bildirimleri',
      iconColor: const Color(0xFFEF4444),
      iconBg: const Color(0xFFFEE2E2),
      enabled: false,
    ),
    _Category(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Sosyal Bildirimler',
      subtitle: 'Arkadaş aktiviteleri ve sosyal bildirimler',
      iconColor: const Color(0xFF14B8A6),
      iconBg: const Color(0xFFCCFBF1),
      enabled: false,
    ),
    _Category(
      icon: Icons.notifications_outlined,
      title: 'Hatırlatmalar',
      subtitle: 'Görev, randevu ve diğer hatırlatmalar',
      iconColor: const Color(0xFFF59E0B),
      iconBg: const Color(0xFFFEF3C7),
      enabled: true,
    ),
  ];

  static const List<_Channel> _channels = [
    _Channel(
      icon: Icons.smartphone_outlined,
      title: 'Uygulama İçi Bildirimler',
      subtitle: 'Uygulama içindeki bildirimleri alın',
    ),
    _Channel(
      icon: Icons.mail_outline_rounded,
      title: 'E-posta Bildirimleri',
      subtitle: 'E-posta adresinize bildirim gönderilsin',
    ),
    _Channel(
      icon: Icons.sms_outlined,
      title: 'SMS Bildirimleri',
      subtitle: 'Telefon numaranıza SMS gönderilsin',
    ),
  ];

  bool _channelValue(int index) {
    return [_appNotifs, _emailNotifs, _smsNotifs][index];
  }

  void _setChannel(int index, bool value) {
    setState(() {
      if (index == 0) _appNotifs = value;
      if (index == 1) _emailNotifs = value;
      if (index == 2) _smsNotifs = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header ────────────────────────────────────────────────
            _buildHeader(context),
            const SizedBox(height: 20),

            // ── Info banner ───────────────────────────────────────────
            if (_showBanner) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InfoBanner(onDismiss: () => setState(() => _showBanner = false)),
              ),
              const SizedBox(height: 20),
            ],

            // ── Bildirim Kanalları ────────────────────────────────────
            const _SectionLabel('Bildirim Kanalları'),
            const SizedBox(height: 10),
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
                    for (int i = 0; i < _channels.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 56),
                      _ChannelRow(
                        channel: _channels[i],
                        value: _channelValue(i),
                        onChanged: (v) => _setChannel(i, v),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Bildirim Kategorileri ─────────────────────────────────
            const _SectionLabel('Bildirim Kategorileri'),
            const SizedBox(height: 10),
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
                    for (int i = 0; i < _categories.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 56),
                      _CategoryRow(
                        category: _categories[i],
                        onTap: () => setState(
                          () => _categories[i].enabled = !_categories[i].enabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Sessiz Saatler ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  onTap: () => _showSilentHoursSheet(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bedtime_outlined,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Sessiz Saatler',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Bu saatler arasında bildirim almayın.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '22:00 - 08:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Pazarlama E-postaları (global platform izni) ──────────
            // Bu bölüm yalnızca user_profiles.marketing_email_opt_in
            // alanını okur/günceller. business_follows.is_subscribed_email
            // (işletme bazlı abonelik) bu sayfada YÖNETİLMEZ.
            const _SectionLabel('Pazarlama E-postaları'),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MarketingEmailSection(
                onError: (message) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Footer note ───────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Bildirim ayarlarınızı istediğiniz zaman değiştirebilirsiniz.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Bildirim Tercihleri',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Material(
                color: AppColors.primarySoft,
                shape: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hangi bildirimleri almak istediğinizi seçin.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _showSilentHoursSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sessiz Saatler',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seçilen saatler arasında bildirim almayacaksınız.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeChip(label: 'Başlangıç', time: '22:00'),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.muted, size: 18),
                    _TimeChip(label: 'Bitiş', time: '08:00'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bildirimler sizden haberdar olmanızı sağlar.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Önemli güncellemeleri ve fırsatları kaçırmayın.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Daha fazla bilgi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Channel row (with toggle) ─────────────────────────────────────────────────

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.value,
    required this.onChanged,
  });
  final _Channel channel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFDCFCE7),
          shape: BoxShape.circle,
        ),
        child: Icon(channel.icon, color: AppColors.success, size: 18),
      ),
      title: Text(
        channel.title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        channel.subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.success,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD1D5DB),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Category row (with status badge) ─────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});
  final _Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: category.iconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(category.icon, color: category.iconColor, size: 18),
      ),
      title: Text(
        category.title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        category.subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.enabled ? 'Açık' : 'Kapalı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: category.enabled ? AppColors.textStrong : AppColors.muted,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ── Marketing email section ───────────────────────────────────────────────────
//
// Global platform pazarlama e-posta izni yönetimi.
// Source of truth: user_profiles.marketing_email_opt_in (Supabase RPC)
// business_follows.is_subscribed_email bu bileşende KULLANILMAZ.

class _MarketingEmailSection extends ConsumerWidget {
  const _MarketingEmailSection({required this.onError});

  final void Function(String message) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: prefsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, st) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.muted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tercih yüklenemedi. Tekrar denemek için sayfayı yenileyin.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (prefs) => _MarketingEmailTile(
          value: prefs.marketingEmailOptIn,
          onChanged: (v) => _toggle(ref, v),
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, bool value) async {
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .setMarketingEmailOptIn(enabled: value);
    } catch (_) {
      onError(
        'Pazarlama e-posta tercihiniz kaydedilemedi. '
        'Lütfen tekrar deneyin.',
      );
    }
  }
}

class _MarketingEmailTile extends StatelessWidget {
  const _MarketingEmailTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFCE7F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFFDB2777),
              size: 18,
            ),
          ),
          title: const Text(
            'Pazarlama e-postaları',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              fontSize: 14,
            ),
          ),
          subtitle: const Text(
            'Yeedoy kampanyaları, yenilikleri ve fırsatları hakkında '
            'e-posta almak istiyorum.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text(
            'Bu izni dilediğiniz zaman kapatabilirsiniz.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.time});
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
        ),
      ],
    );
  }
}
