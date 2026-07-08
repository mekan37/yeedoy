import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/media/app_image_cache_manager.dart';
import '../../../core/media/app_network_image.dart';
import 'package:flutter/services.dart';
import '../../auth/data/auth_service_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../../legal/legal_repository.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';
import '../../../core/privacy/name_masking.dart';
import '../../taste_twin/domain/taste_twin_controllers.dart';

// ── Provider: loads my profile once ─────────────────────────────────────────
final _myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  return ref.read(profileRepositoryProvider).fetchMyProfile();
});

// ── Page ─────────────────────────────────────────────────────────────────────

class AccountInfoPage extends ConsumerStatefulWidget {
  const AccountInfoPage({super.key});

  @override
  ConsumerState<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends ConsumerState<AccountInfoPage> {
  bool _uploadingAvatar = false;

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(profileRepositoryProvider).pickAndUploadAvatar();
      ref.invalidate(publicProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf güncellenemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showEditNameSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditNameSheet(onSaved: () {
        ref.invalidate(_myProfileProvider);
        ref.invalidate(publicProfileProvider);
      }),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  static String _genderLabel(String? g) => switch (g) {
        'male' => 'Erkek',
        'female' => 'Kadın',
        'other' => 'Diğer',
        'prefer_not_to_say' => 'Belirtmek İstemiyorum',
        _ => 'Ekle',
      };

  void _showPhoneSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditPhoneSheet(ref: ref),
    );
  }

  void _showBirthDateSheet(BuildContext context, DateTime? current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditBirthDateSheet(
        ref: ref,
        current: current,
        onSaved: () => ref.invalidate(_myProfileProvider),
      ),
    );
  }

  void _showGenderSheet(BuildContext context, String? current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditGenderSheet(
        ref: ref,
        current: current,
        onSaved: () => ref.invalidate(_myProfileProvider),
      ),
    );
  }

  void _showDeleteAccountSheet() async {
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
              title: const Text('Hesabımı sil'),
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
      await ref.read(legalRepositoryProvider).submitAccountDeletionRequest(
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme talebiniz iletildi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talep gönderilemedi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final profileAsync = ref.watch(_myProfileProvider);
    final profile = profileAsync.asData?.value;
    final pubProfile = user != null
        ? ref.watch(publicProfileProvider(user.id)).asData?.value
        : null;
    final avatarUrl = pubProfile?.avatarUrl ?? '';
    final displayName = profile != null
        ? '${profile.firstName} ${profile.lastName}'.trim()
        : (pubProfile?.displayName ?? '');
    final langCode = profile?.languageCode;
    final birthDate = profile?.birthDate;
    final gender = profile?.gender;

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
                          'Hesap Bilgileri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          'Hesap bilgilerinizi görüntüleyin ve güncelleyin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: buildAvatarUrl(
                                        avatarUrl,
                                        size: 144,
                                      ),
                                      cacheManager: AppImageCacheManager.instance,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                            ),
                          ),
                          if (_uploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + email + phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName
                                      : 'Kullanıcı',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                          if ((user?.email ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if ((user?.phone ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Photo button
                    OutlinedButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Fotoğraf Değiştir',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Kişisel Bilgiler ──────────────────────────────────────
            _SectionLabel('Kişisel Bilgiler'),
            const SizedBox(height: 10),
            _InfoGroup(
              items: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Ad Soyad',
                  value: displayName.isNotEmpty ? displayName : 'Ekle',
                  valueColor: displayName.isEmpty ? AppColors.primary : null,
                  onTap: _showEditNameSheet,
                ),
                _InfoRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'E-posta Adresi',
                  value: user?.email ?? '—',
                  onTap: () {},
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  title: 'Telefon Numarası',
                  value: (user?.phone?.isNotEmpty == true)
                      ? user!.phone!
                      : 'Ekle',
                  valueColor: (user?.phone?.isEmpty != false)
                      ? AppColors.primary
                      : null,
                  onTap: () => _showPhoneSheet(context),
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Doğum Tarihi',
                  value: birthDate != null ? _formatDate(birthDate) : 'Ekle',
                  valueColor: birthDate == null ? AppColors.primary : null,
                  onTap: () => _showBirthDateSheet(context, birthDate),
                ),
                _InfoRow(
                  icon: Icons.people_outline_rounded,
                  title: 'Cinsiyet',
                  value: _genderLabel(gender),
                  valueColor: gender == null ? AppColors.primary : null,
                  onTap: () => _showGenderSheet(context, gender),
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Hesap Ayarları ────────────────────────────────────────
            _SectionLabel('Hesap Ayarları'),
            const SizedBox(height: 10),
            _InfoGroup(
              items: [
                _InfoRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi düzenleyin',
                  onTap: () => context.push('/account-security'),
                ),
                _InfoRow(
                  icon: Icons.notifications_outlined,
                  title: 'Bildirim Tercihleri',
                  subtitle: 'Bildirim ayarlarınızı yönetin',
                  onTap: () => context.push('/notification-preferences'),
                ),
                _InfoRow(
                  icon: Icons.shield_outlined,
                  title: 'Güvenlik Ayarları',
                  subtitle: 'Hesabınızın güvenliğini artırın',
                  onTap: () => context.push('/account-security'),
                ),
                _InfoRow(
                  icon: Icons.language_rounded,
                  title: 'Dil Tercihi',
                  value: _langLabel(langCode),
                  trailing: _ActionBadge('Değiştir'),
                  onTap: () => _showLanguageSheet(context, langCode),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Hesabı Sil ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  onTap: _showDeleteAccountSheet,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Hesabı Sil',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Hesabınızı kalıcı olarak silmek isterseniz buradan işlem yapabilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, String? current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Dil Tercihi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
            for (final (code, label) in [
              (null, 'Sistem Varsayılanı'),
              ('tr', 'Türkçe'),
              ('en', 'English'),
            ])
              ListTile(
                title: Text(label),
                trailing: current == code
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(code);
                  ref.invalidate(_myProfileProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  static String _langLabel(String? code) => switch (code) {
        'tr' => 'Türkçe',
        'en' => 'English',
        _ => 'Sistem Varsayılanı',
      };

}

// ── Helper widgets ────────────────────────────────────────────────────────────

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

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.items});
  final List<_InfoRow> items;

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.trailing,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: value != null
          ? Text(
              value!,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppColors.muted,
              ),
            )
          : subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                )
              : null,
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.muted,
          size: 20,
        ),
      ],
    );
  }
}

// ── Name edit sheet ───────────────────────────────────────────────────────────

class _EditNameSheet extends ConsumerStatefulWidget {
  const _EditNameSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<_EditNameSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(profileRepositoryProvider).fetchMyProfile();
    if (mounted && p != null) {
      _firstCtrl.text = p.firstName;
      _lastCtrl.text = p.lastName;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final existing = await ref.read(profileRepositoryProvider).fetchMyProfile();
      final updated = Profile(
        id: existing?.id ?? '',
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        privacyMode: existing?.privacyMode ?? NamePrivacyMode.full,
        languageCode: existing?.languageCode,
        socialLinks: existing?.socialLinks ?? {},
      );
      await ref.read(profileRepositoryProvider).upsertMyProfile(updated);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: _loading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ad Soyad Düzenle',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstCtrl,
                        decoration: const InputDecoration(labelText: 'Ad'),
                        validator: (v) =>
                            (v?.trim().isEmpty == true) ? 'Zorunlu' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastCtrl,
                        decoration: const InputDecoration(labelText: 'Soyad'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Telefon düzenleme sheet ───────────────────────────────────────────────────

class _EditPhoneSheet extends StatefulWidget {
  const _EditPhoneSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_EditPhoneSheet> createState() => _EditPhoneSheetState();
}

class _EditPhoneSheetState extends State<_EditPhoneSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Geçerli bir telefon numarası girin (ör: +905XXXXXXXXX).');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.ref.read(authServiceProvider).requestPhoneChange(phone);
      if (mounted) setState(() { _otpSent = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'OTP gönderilemedi. Telefon numarasını ve SMS ayarlarını kontrol edin.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 haneli kodu girin.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.ref.read(authServiceProvider).verifyPhoneChange(
        phone: _phoneCtrl.text.trim(),
        token: code,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Kod hatalı veya süresi dolmuş.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Telefon Numarası',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            _otpSent
                ? 'Telefon numaranıza gönderilen 6 haneli kodu girin.'
                : 'Yeni telefon numaranızı E.164 formatında girin (ör: +905XXXXXXXXX).',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            const SizedBox(height: 8),
          ],
          if (!_otpSent) ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                hintText: '+905XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _sendOtp,
              child: Text(_loading ? 'Gönderiliyor…' : 'Doğrulama Kodu Gönder'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(color: AppColors.muted, letterSpacing: 8),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _verifyOtp,
              child: Text(_loading ? 'Doğrulanıyor…' : 'Onayla'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() { _otpSent = false; _error = null; _otpCtrl.clear(); }),
              child: const Text('Numarayı Değiştir'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Doğum tarihi sheet ────────────────────────────────────────────────────────

class _EditBirthDateSheet extends StatefulWidget {
  const _EditBirthDateSheet({
    required this.ref,
    required this.current,
    required this.onSaved,
  });
  final WidgetRef ref;
  final DateTime? current;
  final VoidCallback onSaved;

  @override
  State<_EditBirthDateSheet> createState() => _EditBirthDateSheetState();
}

class _EditBirthDateSheetState extends State<_EditBirthDateSheet> {
  late DateTime? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: 'Doğum tarihinizi seçin',
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  Future<void> _clearDate() async {
    setState(() { _saving = true; _selected = null; });
    try {
      await widget.ref.read(profileRepositoryProvider).updateBirthDate(null);
      widget.onSaved();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.ref.read(profileRepositoryProvider).updateBirthDate(_selected);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _selected != null
        ? '${_selected!.day.toString().padLeft(2, '0')}.${_selected!.month.toString().padLeft(2, '0')}.${_selected!.year}'
        : 'Seçilmedi';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Doğum Tarihi',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _selected != null
                            ? AppColors.textStrong
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_saving || _selected == null) ? null : _save,
            child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
          ),
          if (widget.current != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : _clearDate,
              child: const Text('Tarihi Kaldır',
                  style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Cinsiyet sheet ────────────────────────────────────────────────────────────

class _EditGenderSheet extends StatefulWidget {
  const _EditGenderSheet({
    required this.ref,
    required this.current,
    required this.onSaved,
  });
  final WidgetRef ref;
  final String? current;
  final VoidCallback onSaved;

  @override
  State<_EditGenderSheet> createState() => _EditGenderSheetState();
}

class _EditGenderSheetState extends State<_EditGenderSheet> {
  late String? _selected;
  bool _saving = false;

  static const _options = [
    ('male', 'Erkek', Icons.male_rounded),
    ('female', 'Kadın', Icons.female_rounded),
    ('other', 'Diğer', Icons.transgender_rounded),
    ('prefer_not_to_say', 'Belirtmek İstemiyorum', Icons.do_not_disturb_alt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.ref.read(profileRepositoryProvider).updateGender(_selected);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cinsiyet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu bilgi yalnızca size özel içerik önerileri için kullanılır.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ...List.generate(_options.length, (i) {
            final (value, label, icon) = _options[i];
            final isSelected = _selected == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selected = value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySoft
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.muted,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textStrong,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (_saving || _selected == null) ? null : _save,
            child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
          ),
        ],
      ),
    );
  }
}
