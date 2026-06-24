import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/brand/brand_widgets.dart';
import '../../../../core/location/user_location_controller.dart';
import '../../../../core/media/app_image_cache_manager.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../auth/domain/auth_providers.dart';
import '../../../notifications/ui/components/notifications_bell.dart';
import '../../../taste_twin/domain/taste_twin_controllers.dart';
import 'location_picker_sheet.dart';

/// Shared branded top bar used across all main-shell pages.
///
/// Shows: hamburger → drawer | "Yeedoy" wordmark | location pill | spacer | bell | avatar
///
/// Wrap in `SafeArea(bottom: false)` at the call site when placed inside a
/// scroll list (e.g. `SliverToBoxAdapter` or first item of a `ListView`).
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final loc = ref.watch(userLocationProvider);
    final user = ref.watch(userProvider);

    String? displayName;
    String? avatarUrl;
    if (user != null) {
      final profile = ref.watch(publicProfileProvider(user.id)).asData?.value;
      final name = profile?.displayName.trim() ?? '';
      displayName = name.isNotEmpty ? name : user.email?.split('@').first;
      final url = profile?.avatarUrl ?? '';
      avatarUrl = url.isNotEmpty ? url : null;
    }

    final locLabel = (loc.district?.isNotEmpty == true)
        ? loc.district
        : (loc.city?.isNotEmpty == true ? loc.city : null);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: 2),
      child: Row(
        children: [
          // ── Hamburger ────────────────────────────────────────────────────
          IconButton(
            tooltip: 'Menü',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textStrong,
              size: 24,
            ),
          ),

          // ── Wordmark ─────────────────────────────────────────────────────
          const BrandWordmark(height: 24),

          // ── Location pill ─────────────────────────────────────────────────
          if (locLabel != null) ...[
            SizedBox(width: tokens.space8),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const LocationPickerSheet(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      locLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // ── Notification bell ─────────────────────────────────────────────
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () => context.go('/inbox'),
            icon: const NotificationsBell(),
          ),

          // ── Avatar circle ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: buildAvatarUrl(avatarUrl, size: 72),
                        cacheManager: AppImageCacheManager.instance,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          (displayName?.isNotEmpty == true)
                              ? displayName![0].toUpperCase()
                              : (user != null ? '?' : ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
