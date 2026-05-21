import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../../uygulama/tema/renkler.dart';
import '../../../core/ayarlar/uygulama_ayarlari.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ceviri/yerel_kontrolcusu.dart';
import '../../../core/gizlilik/isim_maskeleme.dart';
import '../../gomulu/ui/gomulu_goruntuleyici_sayfasi.dart';
import '../../yasal/yasal_katalog.dart';
import '../../yasal/yasal_baglanti.dart';
import '../../yasal/yasal_modeller.dart';
import '../../yasal/yasal_saglayicilari.dart';
import '../../yasal/yasal_deposu.dart';
import '../data/profil_modeli.dart';
import '../data/profil_deposu.dart';
import '../../../core/veri/tr_iller.dart';
import '../../../core/depolama/biyometrik_tercihleri.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  NamePrivacyMode _privacyMode = NamePrivacyMode.full;
  String? _languageCode;
  String? _selectedCity;
  String? _selectedDistrict;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _loading = true;
  bool _saving = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadVersion();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final la = LocalAuthentication();
      final supported = await la.canCheckBiometrics && await la.isDeviceSupported();
      final enabled = await BiyometrikTercihleri.isEnabled();
      if (mounted) setState(() { _biometricSupported = supported; _biometricEnabled = enabled; });
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Etkinleştirmek için önce biometric doğrula
      final la = LocalAuthentication();
      final ok = await la.authenticate(
        localizedReason: 'Biyometrik girişi etkinleştirmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) return;
      await BiyometrikTercihleri.setEnabled(true);
      // Mevcut oturumu kaydet
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.refreshToken != null) {
        await BiyometrikTercihleri.saveTokens(
          accessToken:  session.accessToken,
          refreshToken: session.refreshToken!,
        );
      }
    } else {
      await BiyometrikTercihleri.setEnabled(false);
    }
    if (mounted) setState(() => _biometricEnabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Biyometrik giriş etkinleştirildi' : 'Biyometrik giriş devre dışı')),
      );
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.fetchMyProfile();
      if (!mounted) return;
      if (profile != null) {
        _firstNameCtrl.text = profile.firstName;
        _lastNameCtrl.text = profile.lastName;
        _phoneCtrl.text = profile.phone ?? '';
        _privacyMode = profile.privacyMode;
        _languageCode = profile.languageCode;
        _selectedCity = profile.city;
        _selectedDistrict = profile.district;
        _instagramCtrl.text = profile.socialLinks['instagram'] ?? '';
        _youtubeCtrl.text = profile.socialLinks['youtube'] ?? '';
        _facebookCtrl.text = profile.socialLinks['facebook'] ?? '';
      }
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = AppLocalizations.of(context);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.loginRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      final first = _firstNameCtrl.text.trim();
      final last = _lastNameCtrl.text.trim();
      final profile = Profile(
        id: uid,
        firstName: first,
        lastName: last,
        privacyMode: _privacyMode,
        displayName: formatDisplayName(
          firstName: first,
          lastName: last,
          mode: _privacyMode,
        ),
        socialLinks: {
          'instagram': _instagramCtrl.text.trim(),
          'youtube': _youtubeCtrl.text.trim(),
          'facebook': _facebookCtrl.text.trim(),
        },
        city: _selectedCity,
        district: _selectedDistrict,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      await ref.read(profileRepositoryProvider).upsertMyProfile(profile);
      await ref
          .read(localeControllerProvider.notifier)
          .setLocale(_languageCode);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.profileSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.saveError(AppErrorMapper.message(e)))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _previewName() {
    final first = _firstNameCtrl.text.trim().isEmpty
        ? 'Osman'
        : _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim().isEmpty
        ? 'Karabacak'
        : _lastNameCtrl.text.trim();
    return formatDisplayName(
      firstName: first,
      lastName: last,
      mode: _privacyMode,
    );
  }

  String? _validateSocial(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final normalized = normalizeSocialUrl(v);
    if (normalized == null) return AppLocalizations.of(context).invalidLink;
    return null;
  }

  Future<void> _openLinkPreview(String raw) async {
    final normalized = normalizeSocialUrl(raw);
    if (normalized == null || normalized.isEmpty) return;
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmbedViewerPage(
            url: normalized,
            title: AppLocalizations.of(context).socialPreview,
          ),
        ),
      );
      return;
    } catch (_) {}

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openLegalUrl(String url) async {
    try {
      await openLegalUrl(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    }
  }

  Future<void> _showPrivacyRequestDialog({
    required String title,
    required String requestType,
    required String helper,
  }) async {
    final overview = ref.read(legalRequestOverviewProvider).asData?.value;
    if (overview?.hasOpenPrivacyRequest ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bekleyen bir gizlilik başvurunuz zaten var.')),
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
                Text(
                  helper,
                  style: const TextStyle(color: AppColors.muted),
                ),
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
      await ref.read(legalRepositoryProvider).submitPrivacyRequest(
            requestType: requestType,
            details: controller.text,
          );
      ref.invalidate(legalRequestOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başvurunuz kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showAccountDeletionDialog() async {
    final overview = ref.read(legalRequestOverviewProvider).asData?.value;
    if (overview?.hasOpenAccountDeletionRequest ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bekleyen bir hesap silme talebiniz zaten var.')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final confirmationController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final canSubmit =
                  confirmationController.text.trim().toUpperCase() == 'SIL';
              return AlertDialog(
                title: const Text('Hesabımı sil'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu işlem hesabınıza erişimi kapatır ve silinebilir veriler için silme sürecini başlatır. Yasal saklama yükümlülükleri kapsamındaki kayıtlar tutulabilir.',
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
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
                    const SizedBox(height: 8),
                    const Text(
                      'Yanlışlıkla silme talebi oluşturulmaması için onay alanına SIL yazmanız gerekir.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
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
      await ref.read(legalRepositoryProvider).submitAccountDeletionRequest(
            reason: reasonController.text,
          );
      ref.invalidate(legalRequestOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap silme talebiniz kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    } finally {
      reasonController.dispose();
      confirmationController.dispose();
    }
  }

  String _requestStatusText(LegalRequestRecord? request) {
    if (request == null) return '';
    final date = _formatLegalDate(request.submittedAt);
    switch (request.status) {
      case 'submitted':
      case 'requested':
        return 'Bekleyen talep • $date';
      case 'in_review':
        return 'İncelemede • $date';
      case 'resolved':
      case 'completed':
        return 'Tamamlandı • $date';
      case 'rejected':
        return 'Reddedildi • $date';
      case 'cancelled':
        return 'İptal edildi • $date';
      default:
        return '${request.status} • $date';
    }
  }

  Widget _buildLegalRequestOverview(LegalRequestOverview? overview) {
    if (overview == null ||
        (!overview.hasOpenPrivacyRequest &&
            !overview.hasOpenAccountDeletionRequest)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bekleyen başvurular',
            style: TextStyle(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (overview.privacyRequest != null) ...[
            const SizedBox(height: 8),
            Text(
              'Gizlilik başvurusu: ${_requestStatusText(overview.privacyRequest)}',
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
          if (overview.accountDeletionRequest != null) ...[
            const SizedBox(height: 8),
            Text(
              'Hesap silme: ${_requestStatusText(overview.accountDeletionRequest)}',
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final legalOverviewAsync = ref.watch(legalRequestOverviewProvider);
    final legalOverview = legalOverviewAsync.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileSettings),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? t.saving : t.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionCard(
                    title: t.namePrivacy,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration: InputDecoration(labelText: t.firstName),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration: InputDecoration(labelText: t.lastName),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<NamePrivacyMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment<NamePrivacyMode>(
                              value: NamePrivacyMode.full,
                              label: Text(t.showFullName),
                            ),
                            ButtonSegment<NamePrivacyMode>(
                              value: NamePrivacyMode.maskLastName,
                              label: Text(t.hideLastName),
                            ),
                            ButtonSegment<NamePrivacyMode>(
                              value: NamePrivacyMode.maskBoth,
                              label: Text(t.hideBothNames),
                            ),
                          ],
                          selected: <NamePrivacyMode>{_privacyMode},
                          onSelectionChanged: (selected) {
                            if (selected.isEmpty) return;
                            setState(() => _privacyMode = selected.first);
                          },
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${t.preview}: ',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _previewName(),
                                style: const TextStyle(
                                  color: AppColors.textStrong,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'İletişim ve Konum',
                    child: Column(
                      children: [
                        // Telefon
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Telefon (opsiyonel)',
                            hintText: '05XX XXX XX XX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // İl seçimi
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'İl (opsiyonel)',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Seçin'),
                            ),
                            ...kTrIller.map((il) => DropdownMenuItem<String>(
                              value: il,
                              child: Text(il),
                            )),
                          ],
                          onChanged: (value) => setState(() {
                            _selectedCity = value;
                            _selectedDistrict = null; // İl değişince ilçeyi sıfırla
                          }),
                        ),
                        const SizedBox(height: 12),
                        // İlçe seçimi (il seçilmişse aktif)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict,
                          decoration: InputDecoration(
                            labelText: 'İlçe (opsiyonel)',
                            prefixIcon: const Icon(Icons.map_outlined),
                            enabled: _selectedCity != null,
                          ),
                          items: _selectedCity == null
                              ? const [DropdownMenuItem<String>(value: null, child: Text('Önce il seçin'))]
                              : [
                                  const DropdownMenuItem<String>(value: null, child: Text('Seçin')),
                                  ...(kTrIlceler[_selectedCity] ?? []).map((ilce) =>
                                    DropdownMenuItem<String>(value: ilce, child: Text(ilce)),
                                  ),
                                ],
                          onChanged: _selectedCity == null
                              ? null
                              : (value) => setState(() => _selectedDistrict = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: t.socialMedia,
                    child: Column(
                      children: [
                        _SocialField(
                          label: 'Instagram',
                          icon: FontAwesomeIcons.instagram,
                          controller: _instagramCtrl,
                          validator: _validateSocial,
                          helperText: t.pasteLinkHelper,
                          onPreview: () =>
                              _openLinkPreview(_instagramCtrl.text),
                        ),
                        const SizedBox(height: 10),
                        _SocialField(
                          label: 'YouTube',
                          icon: FontAwesomeIcons.youtube,
                          controller: _youtubeCtrl,
                          validator: _validateSocial,
                          helperText: t.pasteLinkHelper,
                          onPreview: () => _openLinkPreview(_youtubeCtrl.text),
                        ),
                        const SizedBox(height: 10),
                        _SocialField(
                          label: 'Facebook',
                          icon: FontAwesomeIcons.facebook,
                          controller: _facebookCtrl,
                          validator: _validateSocial,
                          helperText: t.pasteLinkHelper,
                          onPreview: () => _openLinkPreview(_facebookCtrl.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: t.language,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String?>(
                          initialValue: _languageCode,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(t.systemDefault),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'tr',
                              child: Text(t.turkish),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'en',
                              child: Text(t.english),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _languageCode = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Legal ve Gizlilik',
                    child: Column(
                      children: [
                        if (legalOverviewAsync.isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (legalOverviewAsync.hasError) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Başvuru durumu şu anda alınamadı. Yine de legal bağlantılarını açabilir veya daha sonra tekrar deneyebilirsiniz.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                        _buildLegalRequestOverview(legalOverview),
                        for (final item in LegalCatalog.settingsLinks)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_iconForLegalSlug(item.slug)),
                            title: Text(item.title),
                            subtitle: Text(item.description),
                            onTap: () => _openLegalUrl(item.url),
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled: !(legalOverview?.hasOpenPrivacyRequest ?? false),
                          leading: const Icon(Icons.download_outlined),
                          title: const Text('Verilerimi dışa aktar'),
                          subtitle: legalOverview?.privacyRequest != null
                              ? Text(_requestStatusText(legalOverview?.privacyRequest))
                              : const Text(
                                  'Hesabınıza bağlı verilerin kopyasını talep edin.',
                                ),
                          onTap: legalOverview?.hasOpenPrivacyRequest ?? false
                              ? null
                              : () => _showPrivacyRequestDialog(
                                  title: 'Veri Dışa Aktarma Talebi',
                                  requestType: 'data_export',
                                  helper:
                                      'Hesabınıza bağlı verilerin kopyasını istemek için kısa bir açıklama ekleyebilirsiniz.',
                                ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled: !(legalOverview?.hasOpenPrivacyRequest ?? false),
                          leading: const Icon(Icons.mark_email_read_outlined),
                          title: const Text('Gizlilik başvurusu'),
                          subtitle: legalOverview?.privacyRequest != null
                              ? Text(_requestStatusText(legalOverview?.privacyRequest))
                              : const Text(
                                  'Düzeltme, itiraz veya kısıtlama gibi taleplerinizi gönderin.',
                                ),
                          onTap: legalOverview?.hasOpenPrivacyRequest ?? false
                              ? null
                              : () => _showPrivacyRequestDialog(
                                  title: 'Gizlilik Başvurusu',
                                  requestType: 'privacy_application',
                                  helper:
                                      'Düzeltme, itiraz, kısıtlama veya benzeri gizlilik taleplerinizi yazabilirsiniz.',
                                ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled:
                              !(legalOverview?.hasOpenAccountDeletionRequest ??
                                  false),
                          leading: const Icon(
                            Icons.delete_forever_outlined,
                            color: AppColors.danger,
                          ),
                          title: const Text('Hesabımı sil'),
                          subtitle: legalOverview?.accountDeletionRequest != null
                              ? Text(
                                  _requestStatusText(
                                    legalOverview?.accountDeletionRequest,
                                  ),
                                )
                              : const Text(
                                  'Kalıcı silme sürecini başlatır; geri alınamaz olabilir.',
                                ),
                          onTap: legalOverview?.hasOpenAccountDeletionRequest ??
                                  false
                              ? null
                              : _showAccountDeletionDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hesap Güvenliği bölümü (7→9)
                  _SectionCard(
                    title: 'Hesap Güvenliği',
                    child: Column(
                      children: [
                        // Biyometrik giriş toggle
                        if (_biometricSupported)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.textStrong),
                            title: const Text('Biyometrik Giriş'),
                            subtitle: const Text('Face ID / Parmak izi ile hızlı giriş'),
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.devices_outlined, color: AppColors.textStrong),
                          title: const Text('Aktif Oturumlar'),
                          subtitle: const Text('Giriş yaptığınız cihazları görün ve oturumu uzaktan kapatın'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          onTap: () => _showAktifOturumlarBottomSheet(context),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.password_outlined, color: AppColors.textStrong),
                          title: const Text('Şifre Değiştir'),
                          subtitle: const Text('Hesap şifrenizi güncelleyin'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          onTap: () => _showSifreDegistirDialog(context),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.security_outlined, color: AppColors.textStrong),
                          title: const Text('İki Faktörlü Doğrulama'),
                          subtitle: const Text('Hesabınızı ekstra güvenlik katmanıyla koruyun'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          onTap: () => _showIkiFactorluBilgi(context),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_outlined, color: AppColors.textStrong),
                          title: const Text('Giriş Geçmişi'),
                          subtitle: const Text('Son giriş aktivitelerini inceleyin'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          onTap: () => _showGirisGecmisi(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: t.account,
                    child: Column(
                      children: [
                        if (kDebugMode || AppConfig.devToolsEnabled)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.developer_mode_outlined),
                            title: const Text('Developer Tools'),
                            onTap: () => context.push('/dev-tools'),
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                          ),
                          title: Text(t.logout),
                          onTap: _logout,
                        ),
                        if (_appVersion.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.info_outline, color: AppColors.muted),
                            title: Text(
                              'Versiyon $_appVersion',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Security helpers ────────────────────────────────────────────────────────

Future<void> _showAktifOturumlarBottomSheet(BuildContext context) async {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> sessions = [];

  try {
    // Supabase Auth admin API üzerinden aktif oturumları al
    final resp = await supabase.functions.invoke('get-active-sessions');
    sessions = List<Map<String, dynamic>>.from(resp.data as List? ?? []);
  } catch (_) {
    sessions = [];
  }

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktif Oturumlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
          const SizedBox(height: 4),
          const Text('Hesabınıza giriş yapılan cihaz ve konumlar', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          if (sessions.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Oturum bilgisi alınamadı', style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ] else
            ...sessions.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.smartphone_outlined, color: AppColors.textStrong),
              title: Text(s['user_agent'] as String? ?? 'Bilinmeyen cihaz', overflow: TextOverflow.ellipsis),
              subtitle: Text('Son giriş: ${s['last_sign_in_at'] as String? ?? '—'}'),
              trailing: TextButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Kapat', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Tüm Diğer Oturumları Kapat'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Diğer oturumlar kapatıldı')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showSifreDegistirDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Şifre Değiştir'),
      content: const Text('Kayıtlı e-posta adresinize şifre sıfırlama bağlantısı gönderilecektir.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final email = Supabase.instance.client.auth.currentUser?.email;
            if (email != null) {
              await Supabase.instance.client.auth.resetPasswordForEmail(email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Şifre sıfırlama e-postası $email adresine gönderildi')),
                );
              }
            }
          },
          child: const Text('Gönder'),
        ),
      ],
    ),
  );
}

void _showIkiFactorluBilgi(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('İki Faktörlü Doğrulama'),
      content: const Text(
        'Hesabınıza ek güvenlik katmanı eklemek için TOTP (Google Authenticator, Authy) uygulaması kullanabilirsiniz.\n\n'
        'Bu özellik yakında Supabase Auth MFA entegrasyonu ile aktif olacaktır.',
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
      ],
    ),
  );
}

void _showGirisGecmisi(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Giriş Geçmişi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GirisGecmisiSatir(
            ikonu: Icons.smartphone_outlined,
            metin: 'Bu cihaz',
            zaman: 'Şu an aktif',
            renk: AppColors.success,
          ),
          const SizedBox(height: 8),
          const Text(
            'Detaylı giriş geçmişi için web panelini kullanın.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
      ],
    ),
  );
}

class _GirisGecmisiSatir extends StatelessWidget {
  final IconData ikonu;
  final String metin;
  final String zaman;
  final Color renk;

  const _GirisGecmisiSatir({
    required this.ikonu,
    required this.metin,
    required this.zaman,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikonu, size: 20, color: AppColors.textStrong),
        const SizedBox(width: 10),
        Expanded(child: Text(metin, style: const TextStyle(fontWeight: FontWeight.w700))),
        Text(zaman, style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

IconData _iconForLegalSlug(String slug) {
  switch (slug) {
    case LegalPolicyType.terms:
      return Icons.gavel_outlined;
    case LegalPolicyType.privacy:
      return Icons.privacy_tip_outlined;
    case LegalPolicyType.community:
      return Icons.groups_outlined;
    case LegalPolicyType.deleteAccount:
      return Icons.manage_accounts_outlined;
    default:
      return Icons.open_in_new_rounded;
  }
}

String _formatLegalDate(DateTime value) {
  const months = <int, String>{
    1: 'Ocak',
    2: 'Şubat',
    3: 'Mart',
    4: 'Nisan',
    5: 'Mayıs',
    6: 'Haziran',
    7: 'Temmuz',
    8: 'Ağustos',
    9: 'Eylül',
    10: 'Ekim',
    11: 'Kasım',
    12: 'Aralık',
  };
  return '${value.day} ${months[value.month]} ${value.year}';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.validator,
    required this.helperText,
    required this.onPreview,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String helperText;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Icon(icon, color: AppColors.textStrong, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              suffixIcon: IconButton(
                tooltip: AppLocalizations.of(context).preview,
                onPressed: onPreview,
                icon: const Icon(Icons.open_in_new_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



