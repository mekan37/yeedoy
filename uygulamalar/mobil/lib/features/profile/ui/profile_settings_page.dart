import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../legal/legal_providers.dart';
import '../../legal/legal_repository.dart';
import '../data/profile_repository.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  String? _languageCode;
  bool _loading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMyProfile();
      if (!mounted) return;
      _languageCode = profile?.languageCode ?? 'tr';
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showPrivacyRequestDialog({
    required String title,
    required String requestType,
    required String helper,
  }) async {
    final overview = ref.read(legalRequestOverviewProvider).asData?.value;
    if (overview?.hasOpenPrivacyRequest ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bekleyen bir gizlilik başvurunuz zaten var.'),
        ),
      );
      return;
    }

    final controller = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helper, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detaylar',
                    hintText: 'Talebinizi kısaca açıklayın',
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
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Gönder'),
              ),
            ],
          );
        },
      );
      if (submitted != true) return;
      await ref
          .read(legalRepositoryProvider)
          .submitPrivacyRequest(
            requestType: requestType,
            details: controller.text,
          );
      ref.invalidate(legalRequestOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Başvurunuz kaydedildi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(error))));
    } finally {
      controller.dispose();
    }
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
                  // ── Page header ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Merhaba! 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                'Ayarlar',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Uygulama tercihlerini yönet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Promo card ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => context.push('/account-info'),
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
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Uygulamanı kişiselleştir!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textStrong,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bildirimlerden gizliliğe, favori mutfaklardan para birimine kadar her şeyi buradan ayarla.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Hesap ────────────────────────────────────────────
                  _SettingsSectionTitle('Hesap'),
                  const SizedBox(height: 8),
                  _SettingsGroup(
                    items: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Hesap Bilgileri',
                        subtitle: 'Kişisel bilgilerini düzenle',
                        onTap: () => context.push('/account-info'),
                      ),
                      _SettingsTile(
                        icon: Icons.share_outlined,
                        title: 'Sosyal Medya Hesaplarım',
                        subtitle: 'Instagram, TikTok, YouTube ve daha fazlası',
                        onTap: () => context.push('/social-accounts'),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Gizlilik',
                        subtitle: 'Verilerini ve gizlilik ayarlarını yönet',
                        onTap: () => _showPrivacyRequestDialog(
                          title: 'Gizlilik Başvurusu',
                          requestType: 'privacy_application',
                          helper:
                              'Düzeltme, itiraz veya kısıtlama gibi taleplerinizi gönderin.',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Güvenlik',
                        subtitle: 'Şifre, giriş ve güvenlik ayarları',
                        onTap: () => context.push('/account-security'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Uygulama Tercihleri ──────────────────────────────
                  _SettingsSectionTitle('Uygulama Tercihleri'),
                  const SizedBox(height: 8),
                  _SettingsGroup(
                    items: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirim Ayarları',
                        subtitle: 'Bildirim tercihlerini yönet',
                        onTap: () => context.push('/notification-preferences'),
                      ),
                      _SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'Konum Ayarları',
                        subtitle: 'Konum erişimi ve tercihlerini düzenle',
                        onTap: () => context.push('/location-picker'),
                      ),
                      _SettingsTile(
                        icon: Icons.favorite_outline,
                        title: 'Favori Tercihlerim',
                        subtitle: 'Favori mutfaklar, yemekler ve filtreler',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/favorites');
                        },
                      ),
                    ],
                  ),
                  // Dil — custom tile with inline dropdown
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.language_outlined,
                        color: AppColors.textStrong,
                      ),
                      title: const Text(
                        'Dil',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                      subtitle: const Text(
                        'Uygulama dilini seç',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<String?>(
                          value: _languageCode,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: 'tr',
                              child: Text('Türkçe'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (v) async {
                            setState(() => _languageCode = v);
                            await ref
                                .read(localeControllerProvider.notifier)
                                .setLocale(v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Diğer ────────────────────────────────────────────
                  _SettingsSectionTitle('Diğer'),
                  const SizedBox(height: 8),
                  _SettingsGroup(
                    items: [
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Yardım ve Destek',
                        subtitle: 'Sık sorulan sorular ve destek',
                        onTap: () => context.push('/help-support'),
                      ),
                      _SettingsTile(
                        icon: Icons.gavel_rounded,
                        title: 'Yasal İşlemler',
                        subtitle: 'Kullanım şartları, gizlilik ve KVKK',
                        onTap: () => context.push('/legal'),
                      ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        subtitle: 'Hesabından çıkış yap',
                        titleColor: AppColors.primary,
                        onTap: _logout,
                      ),
                    ],
                  ),

                  if (kDebugMode || AppConfig.devToolsEnabled) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        leading: const Icon(Icons.developer_mode_outlined),
                        title: const Text('Developer Tools'),
                        onTap: () => context.push('/dev-tools'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      _appVersion.isNotEmpty ? 'v$_appVersion' : 'v1.0.0',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

// ── Settings page new-design widgets ────────────────────────────────────────

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
}

// Alias so build code can use _SettingsTile directly
typedef _SettingsTile = _SettingsTileData;

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsTileData> items;

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
              if (i > 0)
                const Divider(height: 1, indent: 56),
              _SettingsTileRow(data: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTileRow extends StatelessWidget {
  const _SettingsTileRow({required this.data});
  final _SettingsTileData data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: data.onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(data.icon, color: data.titleColor ?? AppColors.textStrong, size: 18),
      ),
      title: Text(
        data.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: data.titleColor ?? AppColors.textStrong,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        data.subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
    );
  }
}
