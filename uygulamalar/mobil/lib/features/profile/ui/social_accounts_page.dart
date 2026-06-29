import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/network/supabase_provider.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

// ── Platform definitions ──────────────────────────────────────────────────────

class _PlatformDef {
  const _PlatformDef({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.buttonColor,
    required this.hintText,
  });

  final String key;
  final String label;
  final String description;
  final FaIconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color buttonColor;
  final String hintText;
}

const _kPlatforms = <_PlatformDef>[
  _PlatformDef(
    key: 'instagram',
    label: 'Instagram',
    description: 'Fotoğraf ve video paylaşımlarınızı bağlayın.',
    icon: FontAwesomeIcons.instagram,
    iconColor: Color(0xFFE1306C),
    iconBg: Color(0xFFFCE4EC),
    buttonColor: Color(0xFFE1306C),
    hintText: 'https://instagram.com/kullanici_adi',
  ),
  _PlatformDef(
    key: 'facebook',
    label: 'Facebook',
    description: 'Hesabınızı bağlayarak içeriklerinizi paylaşın.',
    icon: FontAwesomeIcons.facebookF,
    iconColor: Color(0xFF1877F2),
    iconBg: Color(0xFFE3F2FD),
    buttonColor: Color(0xFF1877F2),
    hintText: 'https://facebook.com/kullanici_adi',
  ),
  _PlatformDef(
    key: 'x',
    label: 'X (Twitter)',
    description: 'Tweetlerinizi ve etkileşimlerinizi senkronize edin.',
    icon: FontAwesomeIcons.xTwitter,
    iconColor: Color(0xFF000000),
    iconBg: Color(0xFFF3F4F6),
    buttonColor: Color(0xFF000000),
    hintText: 'https://x.com/kullanici_adi',
  ),
  _PlatformDef(
    key: 'linkedin',
    label: 'LinkedIn',
    description: 'Profesyonel profilinizi bağlayın.',
    icon: FontAwesomeIcons.linkedinIn,
    iconColor: Color(0xFF0A66C2),
    iconBg: Color(0xFFE8F0FB),
    buttonColor: Color(0xFF0A66C2),
    hintText: 'https://linkedin.com/in/kullanici_adi',
  ),
  _PlatformDef(
    key: 'youtube',
    label: 'YouTube',
    description: 'Kanalınızı bağlayın ve içeriklerinizi yönetin.',
    icon: FontAwesomeIcons.youtube,
    iconColor: Color(0xFFFF0000),
    iconBg: Color(0xFFFFEBEE),
    buttonColor: Color(0xFFFF0000),
    hintText: 'https://youtube.com/@kanal_adi',
  ),
  _PlatformDef(
    key: 'tiktok',
    label: 'TikTok',
    description: 'Kısa video içeriklerinizi bağlayın.',
    icon: FontAwesomeIcons.tiktok,
    iconColor: Color(0xFF000000),
    iconBg: Color(0xFFF3F4F6),
    buttonColor: Color(0xFF000000),
    hintText: 'https://tiktok.com/@kullanici_adi',
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class SocialAccountsPage extends ConsumerStatefulWidget {
  const SocialAccountsPage({super.key});

  @override
  ConsumerState<SocialAccountsPage> createState() => _SocialAccountsPageState();
}

class _SocialAccountsPageState extends ConsumerState<SocialAccountsPage> {
  Map<String, String> _links = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMyProfile();
      if (mounted) {
        setState(() {
          _links = Map<String, String>.from(profile?.socialLinks ?? {});
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLinks(Map<String, String> updated) async {
    final uid = ref.read(supabaseProvider).auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _links = updated);
    try {
      await ref.read(profileRepositoryProvider).upsertMyProfile(
        Profile(id: uid, firstName: '', lastName: '', socialLinks: updated),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi, tekrar deneyin.')),
        );
      }
    }
  }

  Future<void> _connectPlatform(_PlatformDef platform) async {
    final controller = TextEditingController(text: _links[platform.key] ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => _LinkDialog(
        platform: platform,
        controller: controller,
      ),
    );
    controller.dispose();
    if (result == null) return;
    final updated = Map<String, String>.from(_links);
    if (result.isEmpty) {
      updated.remove(platform.key);
    } else {
      updated[platform.key] = result;
    }
    await _saveLinks(updated);
  }

  Future<void> _disconnectPlatform(_PlatformDef platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${platform.label} bağlantısını kaldır'),
        content: const Text('Bu hesabın bağlantısını kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = Map<String, String>.from(_links)..remove(platform.key);
    await _saveLinks(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── App bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textStrong,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Sosyal Medya Hesapları',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textStrong,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hesabınıza sosyal medya hesaplarınızı\nekleyin ve kolayca yönetin.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showInfoSheet,
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: const Icon(
                              Icons.question_mark_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Güvenli Bağlantı banner ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
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
                                  'Güvenli Bağlantı',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sosyal medya hesaplarınız 256-bit SSL ile korunur. Bilgileriniz bizimle paylaşılmaz.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 44,
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                              const Positioned(
                                right: -6,
                                bottom: -6,
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Hesap Ekle başlık ─────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Hesap Ekle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Platform listesi ──────────────────────────────────
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
                          for (int i = 0; i < _kPlatforms.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, color: AppColors.border),
                            _PlatformRow(
                              platform: _kPlatforms[i],
                              connectedUrl: _links[_kPlatforms[i].key],
                              onConnect: () =>
                                  _connectPlatform(_kPlatforms[i]),
                              onDisconnect: () =>
                                  _disconnectPlatform(_kPlatforms[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Footer info card ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _showInfoSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD8D0F8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF7C3AED),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Neden hesap eklemelisiniz?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sosyal medya hesaplarınızı bağlayarak içerikleri kolayca paylaşabilir ve etkileşimlerinizi tek yerden yönetebilirsiniz.',
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
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neden Sosyal Hesap Eklemeliyim?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Sosyal medya hesaplarınızı Yeedoy\'a bağlayarak:\n\n'
              '• Yorum ve fotoğraflarınızı tek tıkla sosyal medyada paylaşabilirsiniz.\n'
              '• Profiliniz daha güvenilir görünür ve topluluk puanınız artar.\n'
              '• Hesabınız 256-bit SSL şifrelemesi ile korunur.\n'
              '• Bilgileriniz asla üçüncü taraflarla paylaşılmaz.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Platform row ─────────────────────────────────────────────────────────────

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.platform,
    required this.connectedUrl,
    required this.onConnect,
    required this.onDisconnect,
  });

  final _PlatformDef platform;
  final String? connectedUrl;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  bool get _isConnected => connectedUrl != null && connectedUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Platform icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: platform.iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(platform.icon, color: platform.iconColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isConnected ? 'Hesabınız başarıyla bağlandı.' : platform.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action
          if (_isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Bağlandı',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showActionsMenu(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ),
          ] else
            OutlinedButton(
              onPressed: onConnect,
              style: OutlinedButton.styleFrom(
                foregroundColor: platform.buttonColor,
                side: BorderSide(color: platform.buttonColor),
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Bağla',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('URL\'yi Düzenle'),
                onTap: () {
                  Navigator.of(context).pop();
                  onConnect();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.link_off_rounded, color: AppColors.danger),
                title: Text(
                  'Bağlantıyı Kaldır',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onDisconnect();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Link dialog ──────────────────────────────────────────────────────────────

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.platform, required this.controller});

  final _PlatformDef platform;
  final TextEditingController controller;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          FaIcon(widget.platform.icon, color: widget.platform.iconColor, size: 20),
          const SizedBox(width: 8),
          Text(widget.platform.label),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil URL\'nizi veya kullanıcı adınızı girin:',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.platform.hintText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: const Text('Bağla'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(widget.controller.text.trim());
  }
}
