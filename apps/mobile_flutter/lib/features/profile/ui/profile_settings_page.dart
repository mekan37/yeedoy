import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/privacy/name_masking.dart';
import '../../embed/ui/embed_viewer_page.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

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
  final _instagramCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  NamePrivacyMode _privacyMode = NamePrivacyMode.full;
  String? _languageCode;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getMyProfile();
      if (!mounted) return;
      if (profile != null) {
        _firstNameCtrl.text = profile.firstName;
        _lastNameCtrl.text = profile.lastName;
        _privacyMode = profile.privacyMode;
        _languageCode = profile.languageCode;
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
      ).showSnackBar(SnackBar(content: Text(t.saveError(e.toString()))));
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
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
