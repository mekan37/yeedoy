import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/privacy/name_masking.dart';
import '../../../embed/ui/embed_viewer_page.dart';
import '../../data/profile_model.dart';
import '../../data/profile_repository.dart';

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  return ref.read(profileRepositoryProvider).getMyProfile();
});

class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({super.key, this.userEmail, this.compact = false});

  final String? userEmail;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
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
      error: (_, _) => _buildContent(context, null),
      data: (profile) => _buildContent(context, profile),
    );
  }

  Widget _buildContent(BuildContext context, Profile? profile) {
    final emailLabel = (userEmail ?? 'Misafir').split('@').first;
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
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 15 : 16,
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
                const Text(
                  'Katkılarınla yerel menüleri güçlendiriyorsun.',
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
