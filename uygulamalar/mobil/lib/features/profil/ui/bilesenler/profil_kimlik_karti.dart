import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../../core/medya/uygulama_gorsel_onbellek_yonetici.dart';
import '../../../../core/gizlilik/isim_maskeleme.dart';
import '../../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../../gomulu/ui/gomulu_goruntuleyici_sayfasi.dart';
import '../../../tat_ikizi/data/tat_ikizi_deposu.dart';
import '../../../tat_ikizi/domain/tat_ikizi_kontrolculeri.dart';
import '../../data/profil_modeli.dart';
import '../../data/profil_deposu.dart';

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  return ref.read(profileRepositoryProvider).fetchMyProfile();
});

class ProfileIdentityCard extends ConsumerStatefulWidget {
  const ProfileIdentityCard({super.key, this.userEmail, this.compact = false});

  final String? userEmail;
  final bool compact;

  @override
  ConsumerState<ProfileIdentityCard> createState() => _ProfileIdentityCardState();
}

class _ProfileIdentityCardState extends ConsumerState<ProfileIdentityCard> {
  bool _uploadingAvatar = false;

  Future<void> _changeAvatar() async {
    if (_uploadingAvatar) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await ref.read(profileRepositoryProvider).pickAndUploadAvatar();
      if (url != null) {
        final uid = ref.read(userProvider)?.id;
        // Clear in-memory cache so publicProfileProvider returns fresh data.
        ref.read(tasteTwinRepositoryProvider).clearReadCache();
        if (uid != null) ref.invalidate(publicProfileProvider(uid));
        ref.invalidate(myProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMapper.message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(userProvider);
    final avatarUrl = user != null
        ? (ref.watch(publicProfileProvider(user.id)).value?.avatarUrl ?? '')
        : '';

    return profileAsync.when(
      loading: () => _card(
        child: const Row(
          children: [
            CircleAvatar(child: Icon(Icons.person_outline)),
            SizedBox(width: 10),
            Expanded(child: LinearProgressIndicator(minHeight: 6)),
          ],
        ),
      ),
      error: (_, s) => _buildContent(context, null, avatarUrl),
      data: (profile) => _buildContent(context, profile, avatarUrl),
    );
  }

  Widget _buildContent(BuildContext context, Profile? profile, String avatarUrl) {
    final t = AppLocalizations.of(context);
    final emailLabel = (widget.userEmail ?? t.profileGuestUser).split('@').first;
    final first = profile?.firstName ?? '';
    final last = profile?.lastName ?? '';
    final mode = profile?.privacyMode ?? NamePrivacyMode.full;
    final masked = formatDisplayName(
      firstName: first,
      lastName: last,
      mode: mode,
    );
    final display = (profile?.displayName ?? '').trim();
    final mainName = display.isNotEmpty
        ? display
        : (masked.isNotEmpty ? masked : emailLabel);
    final showMaskedSubline =
        display.isNotEmpty && masked.isNotEmpty && masked != display;
    final socialLinks = _sortedSocial(profile?.socialLinks ?? const {});

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _changeAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cardAlt,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(
                          avatarUrl,
                          cacheManager: AppImageCacheManager.instance,
                          maxWidth: 512,
                        )
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: _uploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(3),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: widget.compact ? 15 : 16,
                    color: AppColors.textStrong,
                  ),
                ),
                if (showMaskedSubline) ...[
                  const SizedBox(height: 2),
                  Text(
                    masked,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  t.profileIdentitySupportMessage,
                  style: TextStyle(color: AppColors.muted),
                ),
                if (socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final entry in socialLinks) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _openLink(context, entry.$2),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              entry.$1,
                              size: 16,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  List<(IconData, String)> _sortedSocial(Map<String, String> links) {
    final instagram = normalizeSocialUrl(links['instagram'] ?? '');
    final youtube = normalizeSocialUrl(links['youtube'] ?? '');
    final facebook = normalizeSocialUrl(links['facebook'] ?? '');
    final out = <(IconData, String)>[];
    if (instagram != null && instagram.isNotEmpty) {
      out.add((FontAwesomeIcons.instagram, instagram));
    }
    if (youtube != null && youtube.isNotEmpty) {
      out.add((FontAwesomeIcons.youtube, youtube));
    }
    if (facebook != null && facebook.isNotEmpty) {
      out.add((FontAwesomeIcons.facebook, facebook));
    }
    return out;
  }

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => EmbedViewerPage(url: url)));
      return;
    } catch (_) {}

    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}





