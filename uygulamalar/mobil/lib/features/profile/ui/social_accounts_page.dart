import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
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

List<_PlatformDef> _platformDefs(BuildContext context) => <_PlatformDef>[
  _PlatformDef(
    key: 'instagram',
    label: context.l10n.socialAccountsInstagramLabel,
    description: context.l10n.socialAccountsInstagramDescription,
    icon: FontAwesomeIcons.instagram,
    iconColor: const Color(0xFFE1306C),
    iconBg: const Color(0xFFFCE4EC),
    buttonColor: const Color(0xFFE1306C),
    hintText: context.l10n.socialAccountsInstagramHint,
  ),
  _PlatformDef(
    key: 'facebook',
    label: context.l10n.socialAccountsFacebookLabel,
    description: context.l10n.socialAccountsFacebookDescription,
    icon: FontAwesomeIcons.facebookF,
    iconColor: const Color(0xFF1877F2),
    iconBg: const Color(0xFFE3F2FD),
    buttonColor: const Color(0xFF1877F2),
    hintText: context.l10n.socialAccountsFacebookHint,
  ),
  _PlatformDef(
    key: 'x',
    label: context.l10n.socialAccountsXLabel,
    description: context.l10n.socialAccountsXDescription,
    icon: FontAwesomeIcons.xTwitter,
    iconColor: const Color(0xFF000000),
    iconBg: const Color(0xFFF3F4F6),
    buttonColor: const Color(0xFF000000),
    hintText: context.l10n.socialAccountsXHint,
  ),
  _PlatformDef(
    key: 'linkedin',
    label: context.l10n.socialAccountsLinkedinLabel,
    description: context.l10n.socialAccountsLinkedinDescription,
    icon: FontAwesomeIcons.linkedinIn,
    iconColor: const Color(0xFF0A66C2),
    iconBg: const Color(0xFFE8F0FB),
    buttonColor: const Color(0xFF0A66C2),
    hintText: context.l10n.socialAccountsLinkedinHint,
  ),
  _PlatformDef(
    key: 'youtube',
    label: context.l10n.socialAccountsYoutubeLabel,
    description: context.l10n.socialAccountsYoutubeDescription,
    icon: FontAwesomeIcons.youtube,
    iconColor: const Color(0xFFFF0000),
    iconBg: const Color(0xFFFFEBEE),
    buttonColor: const Color(0xFFFF0000),
    hintText: context.l10n.socialAccountsYoutubeHint,
  ),
  _PlatformDef(
    key: 'tiktok',
    label: context.l10n.socialAccountsTiktokLabel,
    description: context.l10n.socialAccountsTiktokDescription,
    icon: FontAwesomeIcons.tiktok,
    iconColor: const Color(0xFF000000),
    iconBg: const Color(0xFFF3F4F6),
    buttonColor: const Color(0xFF000000),
    hintText: context.l10n.socialAccountsTiktokHint,
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
    setState(() => _links = updated);
    try {
      await ref.read(profileRepositoryProvider).updateSocialLinks(updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.socialAccountsSaveError)),
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
        title: Text(ctx.l10n.socialAccountsDisconnectDialogTitle(platform.label)),
        content: Text(ctx.l10n.socialAccountsDisconnectDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.socialAccountsCancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.socialAccountsRemoveButton),
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
    final platforms = _platformDefs(context);
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
                              Text(
                                context.l10n.socialAccountsPageTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textStrong,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.socialAccountsPageSubtitle,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.socialAccountsSecureConnectionTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.socialAccountsSecureConnectionBody,
                                  style: const TextStyle(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      context.l10n.socialAccountsAddAccountSectionTitle,
                      style: const TextStyle(
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
                          for (int i = 0; i < platforms.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, color: AppColors.border),
                            _PlatformRow(
                              platform: platforms[i],
                              connectedUrl: _links[platforms[i].key],
                              onConnect: () =>
                                  _connectPlatform(platforms[i]),
                              onDisconnect: () =>
                                  _disconnectPlatform(platforms[i]),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.socialAccountsWhyAddTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.l10n.socialAccountsWhyAddBody,
                                    style: const TextStyle(
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
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetContext.l10n.socialAccountsInfoSheetTitle,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              sheetContext.l10n.socialAccountsInfoSheetBody,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
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
                  _isConnected
                      ? context.l10n.socialAccountsConnectedLabel
                      : platform.description,
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
                    context.l10n.socialAccountsConnectedBadge,
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
              child: Text(
                context.l10n.socialAccountsConnectButton,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
      builder: (sheetContext) => Container(
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
                title: Text(sheetContext.l10n.socialAccountsEditUrlAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onConnect();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.link_off_rounded, color: AppColors.danger),
                title: Text(
                  sheetContext.l10n.socialAccountsRemoveLinkAction,
                  style: const TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
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
            context.l10n.socialAccountsLinkDialogPrompt,
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
          child: Text(context.l10n.socialAccountsCancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: Text(context.l10n.socialAccountsConnectButton),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(widget.controller.text.trim());
  }
}
