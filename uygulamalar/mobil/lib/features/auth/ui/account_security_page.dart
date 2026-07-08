import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FactorType;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../legal/legal_repository.dart';
import '../data/auth_service_provider.dart';
import '../domain/auth_providers.dart';

// ── Bar colours (kötü → orta → iyi) ──────────────────────────────────────────

const _kBarColors = [
  Color(0xFFEF4444), // red — kötü
  Color(0xFFF97316), // orange
  Color(0xFFEAB308), // yellow — orta
  Color(0xFF84CC16), // lime
  Color(0xFF22C55E), // green — iyi
];

Color _ringColorFor(int score, int total) {
  if (total == 0) return Colors.grey;
  final ratio = score / total;
  if (ratio < 0.4) return const Color(0xFFEF4444);
  if (ratio < 0.8) return const Color(0xFFEAB308);
  return AppColors.success;
}

String _scoreLabelFor(int score, int total) {
  if (total == 0) return '…';
  final ratio = score / total;
  if (ratio < 0.4) return 'Düşük';
  if (ratio < 0.8) return 'Orta';
  return 'Yüksek';
}

// ── Page ─────────────────────────────────────────────────────────────────────

class AccountSecurityPage extends ConsumerStatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  ConsumerState<AccountSecurityPage> createState() =>
      _AccountSecurityPageState();
}

class _AccountSecurityPageState extends ConsumerState<AccountSecurityPage> {
  int _scoreDone = 0;
  static const int _scoreTotal = 5;
  bool _scoreLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadScore);
  }

  Future<void> _loadScore() async {
    if (!mounted) return;
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    if (user == null) return;

    int done = 0;

    // 1. E-posta doğrulandı
    if (user.emailConfirmedAt != null) done++;

    // 2. Telefon numarası eklendi
    if ((user.phone ?? '').isNotEmpty) done++;

    // 3. İki Adımlı Doğrulama aktif
    try {
      final res = await client.auth.mfa.listFactors();
      final verified = (res.totp as List?)
              ?.where((f) => (f.status as String?) == 'verified')
              .toList() ??
          [];
      if (verified.isNotEmpty) done++;
    } catch (_) {}

    // 4. Profil tamamlandı (display_name)
    try {
      final row = await client
          .from('user_profiles')
          .select('display_name')
          .eq('user_id', user.id)
          .maybeSingle();
      final dn = row?['display_name'] as String?;
      if (dn != null && dn.trim().isNotEmpty) done++;
    } catch (_) {}

    // 5. Güvenilen cihaz kayıtlı
    try {
      final rows =
          await client.from('user_devices').select('id').limit(1);
      if ((rows as List).isNotEmpty) done++;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _scoreDone = done;
        _scoreLoaded = true;
      });
    }
  }

  Future<void> _downloadData() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(legalRepositoryProvider).submitPrivacyRequest(
            requestType: 'data_export',
          );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Veri export talebiniz alındı. En kısa sürede e-postanıza iletilecektir.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Talep gönderilemedi. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse(
      'mailto:destek@yeedoy.com?subject=Hesap%20G%C3%BCvenli%C4%9Fi%20Destek',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta uygulaması açılamadı. destek@yeedoy.com adresine yazın.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final ringColor = _ringColorFor(_scoreDone, _scoreTotal);
    final scoreLabel = _scoreLabelFor(_scoreDone, _scoreTotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
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
                    child: Column(
                      children: [
                        Text(
                          'Hesap Güvenliği',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          'Hesabınızı koruyun, güvende kalın.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.primarySoft,
                    shape: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Security score card ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SecurityScoreCard(
                score: _scoreDone,
                total: _scoreTotal,
                barColors: _kBarColors,
                ringColor: ringColor,
                scoreLabel: scoreLabel,
                loading: !_scoreLoaded,
              ),
            ),

            const SizedBox(height: 24),

            // ── Güvenlik Ayarları ─────────────────────────────────────
            const _SectionLabel('Güvenlik Ayarları'),
            const SizedBox(height: 10),
            _SecurityGroup(
              items: [
                _SecurityRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Şifre',
                  subtitle: 'Şifrenizi düzenleyin',
                  trailing: const _MetaText('Son değişiklik: 15.05.2024'),
                  onTap: () => _showChangePassword(context),
                ),
                _SecurityRow(
                  icon: Icons.smartphone_rounded,
                  title: 'İki Adımlı Doğrulama',
                  subtitle: 'Hesabınıza ekstra güvenlik katın',
                  trailing: const _ActiveBadge(),
                  onTap: () => _show2FASheet(context),
                ),
                _SecurityRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'E-posta Adresi',
                  subtitle: 'E-posta adresinizi yönetin',
                  trailing: _MetaText(user?.email ?? ''),
                  onTap: () => _showChangeEmail(context),
                ),
                _SecurityRow(
                  icon: Icons.phone_android_rounded,
                  title: 'Güvenilen Cihazlar',
                  subtitle: 'Hesabınıza giriş yapan cihazları yönetin',
                  onTap: () => _showTrustedDevices(context),
                ),
                _SecurityRow(
                  icon: Icons.key_rounded,
                  title: 'Oturum Yönetimi',
                  subtitle: 'Açık oturumlarınızı görüntüleyin',
                  onTap: () => _showSessionManagement(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Tips card ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TipsCard(),
            ),

            const SizedBox(height: 24),

            // ── Hesap İşlemleri ───────────────────────────────────────
            const _SectionLabel('Hesap İşlemleri'),
            const SizedBox(height: 10),
            _SecurityGroup(
              items: [
                _SecurityRow(
                  icon: Icons.download_outlined,
                  iconBgColor: const Color(0xFFF1F5F9),
                  iconColor: AppColors.textStrong,
                  title: 'Verilerinizi İndirin',
                  subtitle:
                      'Hesabınıza ait verilerin bir kopyasını indirin.',
                  onTap: _downloadData,
                ),
                _SecurityRow(
                  icon: Icons.delete_outline_rounded,
                  iconBgColor: const Color(0xFFF1F5F9),
                  iconColor: AppColors.textStrong,
                  title: 'Hesabımı Sil',
                  subtitle: 'Hesabınızı kalıcı olarak silin.',
                  onTap: () => _showDeleteAccount(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Support banner ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SupportBanner(onSupport: _contactSupport),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _show2FASheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TwoFactorSheet(ref: ref),
    );
  }

  void _showTrustedDevices(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TrustedDevicesSheet(ref: ref),
    );
  }

  void _showSessionManagement(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SessionManagementSheet(ref: ref),
    );
  }

  Future<void> _showChangePassword(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangePasswordSheet(ref: ref),
    );
  }

  Future<void> _showChangeEmail(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangeEmailSheet(ref: ref),
    );
  }

  void _showDeleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final confirmationController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final canSubmit =
                confirmationController.text.trim().toUpperCase() == 'SIL';
            return AlertDialog(
              title: const Text('Hesabımı Sil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu işlem hesabınıza erişimi kapatır ve silinebilir veriler için silme sürecini başlatır.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Silme nedeni',
                      hintText: 'İsterseniz nedeninizi paylaşın',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmationController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Onay',
                      hintText: 'Devam etmek için SIL yazın',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Silme Talebi Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(legalRepositoryProvider)
          .submitAccountDeletionRequest(reason: reasonController.text.trim());
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Silme talebiniz iletildi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Talep gönderilemedi.')),
        );
      }
    } finally {
      reasonController.dispose();
      confirmationController.dispose();
    }
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

// ── Security score card ───────────────────────────────────────────────────────

class _SecurityScoreCard extends StatelessWidget {
  const _SecurityScoreCard({
    required this.score,
    required this.total,
    required this.barColors,
    required this.ringColor,
    required this.scoreLabel,
    this.loading = false,
  });
  final int score;
  final int total;
  final List<Color> barColors;
  final Color ringColor;
  final String scoreLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : score / total;
    final bgColor = score == 0
        ? const Color(0xFFFEE2E2)
        : score < 3
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7);
    final iconColor = score == 0
        ? AppColors.danger
        : score < 3
            ? const Color(0xFFF59E0B)
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress ring
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 7,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: loading
                          ? const CircularProgressIndicator(
                              strokeWidth: 7,
                              color: AppColors.primary,
                            )
                          : CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 7,
                              backgroundColor: Colors.transparent,
                              color: ringColor,
                              strokeCap: StrokeCap.round,
                            ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: iconColor,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          const TextSpan(text: 'Güvenlik Skorunuz: '),
                          TextSpan(
                            text: scoreLabel,
                            style: TextStyle(
                              color: ringColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hesabınızı korumak için tüm güvenlik önerilerini tamamlayın.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score number
              loading
                  ? const SizedBox(
                      width: 48,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$score',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: ringColor,
                            ),
                          ),
                          TextSpan(
                            text: ' /$total',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress segments — each bar has its own colour
          Row(
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: (!loading && i < score)
                          ? barColors[i]
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Security rows & group ─────────────────────────────────────────────────────

class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup({required this.items});
  final List<_SecurityRow> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconBgColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconBgColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor ?? const Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
    );
  }
}

// ── Trailing widgets ──────────────────────────────────────────────────────────

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.muted, size: 20),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aktif',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
      ],
    );
  }
}

// ── Tips card ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEDEAA)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Güvenliğinizi Artırın',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textStrong,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Aşağıdaki önerileri uygulayarak hesabınızı daha da güvenli hale getirin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          _TipRow(
            icon: Icons.shield_outlined,
            title: 'Güçlü bir şifre kullanın',
            subtitle: 'Tahmin edilmesi zor, güçlü bir şifre seçin.',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _TipRow(
            icon: Icons.smartphone_outlined,
            title: 'İki adımlı doğrulamayı etkinleştirin',
            subtitle: 'Hesabınıza ekstra koruma ekleyin.',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFED7AA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFF97316), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 20,
      ),
    );
  }
}

// ── Support banner ────────────────────────────────────────────────────────────

class _SupportBanner extends StatelessWidget {
  const _SupportBanner({required this.onSupport});
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yardıma mı ihtiyacınız var?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Güvenlik ile ilgili sorularınız için destek ekibimizle iletişim geçin.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onSupport,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: const Text('Destek Al'),
          ),
        ],
      ),
    );
  }
}

// ── İki Adımlı Doğrulama sheet ───────────────────────────────────────────────

enum TfaState { checking, notEnrolled, enrolling, enrolled, disabling }

class _TwoFactorSheet extends StatefulWidget {
  const _TwoFactorSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_TwoFactorSheet> createState() => _TwoFactorSheetState();
}

class _TwoFactorSheetState extends State<_TwoFactorSheet> {
  TfaState _state = TfaState.checking;
  String? _factorId;
  String? _totpUri;
  String? _totpSecret;
  String? _error;
  bool _loading = false;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollment() async {
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client.auth.mfa.listFactors();
      final verified = (res.totp as List?)
              ?.where((f) => (f.status as String?) == 'verified')
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          if (verified.isNotEmpty) {
            _state = TfaState.enrolled;
            _factorId = (verified.first as dynamic).id as String?;
          } else {
            _state = TfaState.notEnrolled;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = TfaState.notEnrolled);
    }
  }

  Future<void> _startEnroll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client.auth.mfa.enroll(factorType: FactorType.totp);
      final data = res as dynamic;
      setState(() {
        _totpUri = (data.totp?.uri ?? data.data?.totp?.uri) as String?;
        _totpSecret =
            (data.totp?.secret ?? data.data?.totp?.secret) as String?;
        _factorId = (data.id ?? data.data?.id) as String?;
        _state = TfaState.enrolling;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Kimlik doğrulama uygulaması kurulumu başlatılamadı.';
        _loading = false;
      });
    }
  }

  Future<void> _verifyAndActivate() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 haneli doğrulama kodunu girin.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final challenge =
          await client.auth.mfa.challenge(factorId: _factorId!);
      final challengeId =
          ((challenge as dynamic).id ?? (challenge as dynamic).data?.id)
              as String?;
      await client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challengeId!,
        code: code,
      );
      if (mounted) {
        setState(() {
          _state = TfaState.enrolled;
          _loading = false;
          _codeCtrl.clear();
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Kod hatalı veya süresi dolmuş. Yeni kod deneyin.';
        _loading = false;
      });
    }
  }

  Future<void> _disableConfirm() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 haneli doğrulama kodunu girin.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = widget.ref.read(supabaseProvider);
      final challenge =
          await client.auth.mfa.challenge(factorId: _factorId!);
      final challengeId =
          ((challenge as dynamic).id ?? (challenge as dynamic).data?.id)
              as String?;
      await client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challengeId!,
        code: code,
      );
      await client.auth.mfa.unenroll(_factorId!);
      if (mounted) {
        setState(() {
          _state = TfaState.notEnrolled;
          _loading = false;
          _factorId = null;
          _codeCtrl.clear();
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Kod hatalı veya süresi dolmuş.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İki Adımlı Doğrulama',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textStrong),
                    ),
                    Text(
                      'Kimlik doğrulama uygulaması (TOTP)',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_state == TfaState.checking)
            const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
          else if (_state == TfaState.notEnrolled)
            _buildNotEnrolled()
          else if (_state == TfaState.enrolling)
            _buildEnrolling()
          else if (_state == TfaState.enrolled)
            _buildEnrolled()
          else if (_state == TfaState.disabling)
            _buildDisabling(),
        ],
      ),
    );
  }

  Widget _buildNotEnrolled() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Google Authenticator, Authy veya benzeri bir kimlik doğrulama uygulamasını kullanarak hesabınıza ekstra güvenlik katmanı ekleyebilirsiniz.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.5),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _startEnroll,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_open_rounded, size: 18),
            label: Text(_loading ? 'Başlatılıyor…' : 'Kurulumu Başlat'),
          ),
        ],
      );

  Widget _buildEnrolling() {
    final uri = _totpUri ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. Kimlik doğrulama uygulamanızı açın ve QR kodu okutun.',
          style: TextStyle(
              fontSize: 13, color: AppColors.textStrong, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (uri.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 180,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textStrong,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ),
        if (_totpSecret != null) ...[
          const SizedBox(height: 12),
          const Text('Gizli anahtar (manuel giriş):',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _totpSecret!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anahtar kopyalandı.')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _totpSecret!,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          letterSpacing: 1.5,
                          color: AppColors.textStrong),
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 16, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          '2. Uygulamanın gösterdiği 6 haneli kodu girin:',
          style:
              TextStyle(fontSize: 13, color: AppColors.textStrong),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(_error!,
              style:
                  const TextStyle(color: AppColors.danger, fontSize: 13)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 8),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle:
                TextStyle(color: AppColors.muted, letterSpacing: 8),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _verifyAndActivate,
          child: Text(
              _loading ? 'Doğrulanıyor…' : 'Doğrula ve Aktifleştir'),
        ),
      ],
    );
  }

  Widget _buildEnrolled() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'İki adımlı doğrulama aktif. Hesabınız ek güvenlik katmanıyla korunuyor.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF15803D),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _state = TfaState.disabling),
            icon: const Icon(Icons.lock_open_rounded,
                size: 16, color: AppColors.danger),
            label: const Text('Devre Dışı Bırak',
                style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      );

  Widget _buildDisabling() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Text(
              'Devre dışı bırakmak için kimlik doğrulama uygulamanızdaki kodu girin.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null) ...[
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 13)),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 8),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle:
                  TextStyle(color: AppColors.muted, letterSpacing: 8),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading ? null : _disableConfirm,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child:
                Text(_loading ? 'İşleniyor…' : 'Devre Dışı Bırak'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _state = TfaState.enrolled;
              _error = null;
              _codeCtrl.clear();
            }),
            child: const Text('Vazgeç'),
          ),
        ],
      );
}

// ── Güvenilen Cihazlar sheet ──────────────────────────────────────────────────

class _TrustedDevicesSheet extends StatefulWidget {
  const _TrustedDevicesSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_TrustedDevicesSheet> createState() => _TrustedDevicesSheetState();
}

class _TrustedDevicesSheetState extends State<_TrustedDevicesSheet> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = widget.ref.read(supabaseProvider);
      final res = await client
          .from('user_devices')
          .select('id, platform, app_version, last_seen_at, created_at')
          .order('last_seen_at', ascending: false);
      if (mounted) {
        setState(() {
          _devices = List<Map<String, dynamic>>.from(res as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      final client = widget.ref.read(supabaseProvider);
      await client.from('user_devices').delete().eq('id', id);
      setState(() => _devices.removeWhere((d) => d['id'] == id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cihaz kaldırılamadı.')));
      }
    }
  }

  String _relativeTime(String? raw) {
    if (raw == null) return 'Bilinmiyor';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'Bilinmiyor';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} saat önce';
    if (diff.inDays < 30) return '${diff.inDays} gün önce';
    return '${(diff.inDays / 30).round()} ay önce';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.phone_android_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Güvenilen Cihazlar',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textStrong)),
                  Text('Uygulamanın kurulu olduğu cihazlar',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
          else if (_devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text('Kayıtlı cihaz bulunamadı.',
                      style: TextStyle(color: AppColors.muted))),
            )
          else
            ...List.generate(_devices.length, (i) {
              final d = _devices[i];
              final platform = (d['platform'] as String?) ?? 'Bilinmiyor';
              final version = (d['app_version'] as String?) ?? '';
              final lastSeen =
                  _relativeTime(d['last_seen_at'] as String?);
              final isAndroid =
                  platform.toLowerCase().contains('android');
              return Column(
                children: [
                  if (i > 0)
                    const Divider(
                        height: 1, color: AppColors.border),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAndroid
                            ? Icons.android_rounded
                            : Icons.phone_iphone_rounded,
                        color: AppColors.textStrong,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      isAndroid ? 'Android Cihaz' : 'iOS Cihaz',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textStrong),
                    ),
                    subtitle: Text(
                      version.isNotEmpty
                          ? 'v$version · $lastSeen'
                          : lastSeen,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger, size: 20),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cihazı Kaldır'),
                            content: const Text(
                                'Bu cihaz için bildirimler devre dışı bırakılacak. Devam edilsin mi?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Vazgeç')),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.danger),
                                child: const Text('Kaldır'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _remove(d['id'] as String);
                      },
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ── Oturum Yönetimi sheet ─────────────────────────────────────────────────────

class _SessionManagementSheet extends StatelessWidget {
  const _SessionManagementSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final client = ref.read(supabaseProvider);
    final user = client.auth.currentUser;
    final email = user?.email ?? '';
    final lastSignIn = user?.lastSignInAt;
    final createdAt = user?.createdAt;

    String fmt(String? raw) {
      if (raw == null) return 'Bilinmiyor';
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) return 'Bilinmiyor';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: const Icon(Icons.key_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oturum Yönetimi',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textStrong)),
                  Text('Aktif oturumunuzu yönetin',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Current session card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Aktif Oturum',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SessionRow(label: 'E-posta', value: email),
                const SizedBox(height: 6),
                _SessionRow(
                    label: 'Son giriş', value: fmt(lastSignIn)),
                const SizedBox(height: 6),
                _SessionRow(
                    label: 'Hesap oluşturuldu',
                    value: fmt(createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFEDEAA)),
            ),
            child: const Text(
              'Tanımadığınız bir cihazdan giriş yapıldıysa tüm oturumları sonlandırın ve şifrenizi değiştirin.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Tüm Oturumları Kapat'),
                  content: const Text(
                      'Tüm cihazlardaki aktif oturumlarınız sonlandırılacak ve yeniden giriş yapmanız gerekecek.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç')),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Tüm Cihazlarda Oturumu Kapat'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textStrong)),
        ),
      ],
    );
  }
}

// ── Şifre değiştirme sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _newPassCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(authServiceProvider).updatePassword(pass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Şifre Değiştir',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Yeni şifre',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Yeni şifre (tekrar)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _save,
            child:
                Text(_loading ? 'Kaydediliyor…' : 'Şifreyi Güncelle'),
          ),
        ],
      ),
    );
  }
}

// ── E-posta değiştirme sheet ──────────────────────────────────────────────────

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Geçerli bir e-posta girin.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(authServiceProvider).updateEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  '${_emailCtrl.text.trim()} adresine doğrulama e-postası gönderildi. Bağlantıya tıkladıktan sonra e-postanız güncellenecektir.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'E-posta Değiştir',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yeni e-posta adresinize doğrulama bağlantısı gönderilecektir.',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Yeni e-posta adresi',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: Text(
                    _loading
                        ? 'Gönderiliyor…'
                        : 'Doğrulama Bağlantısı Gönder',
                  ),
                ),
              ],
            ),
    );
  }
}
