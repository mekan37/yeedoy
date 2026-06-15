import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/app_image_cache_manager.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../auth/domain/auth_providers.dart';
import '../../../taste_twin/domain/taste_twin_controllers.dart';

enum AppProfileVariant { regular, inverse }

class AppProfileAction extends ConsumerWidget {
  const AppProfileAction({super.key, this.variant = AppProfileVariant.regular});

  final AppProfileVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    final isInverse = variant == AppProfileVariant.inverse;
    if (user == null) {
      return TextButton(
        onPressed: () => context.go('/login'),
        style: isInverse
            ? TextButton.styleFrom(foregroundColor: AppColors.onPrimary)
            : null,
        child: Text(t.loginSignupAction),
      );
    }

    final profileAsync = ref.watch(publicProfileProvider(user.id));
    final profile = profileAsync.asData?.value;
    final displayName =
        (profile?.displayName ?? user.email?.split('@').first ?? t.profileGuestUser)
            .toString()
            .trim();
    final avatarUrl = (profile?.avatarUrl ?? '').toString();

    final bgColor = isInverse
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.cardAlt;
    final borderColor = isInverse
        ? Colors.white.withValues(alpha: 0.25)
        : AppColors.border;
    final textColor = isInverse ? AppColors.onPrimary : AppColors.textStrong;
    final iconColor = isInverse ? AppColors.onPrimary : AppColors.muted;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.go('/profile'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(
                      buildAvatarUrl(avatarUrl, size: 64),
                      cacheManager: AppImageCacheManager.instance,
                    )
                  : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    )
                  : null,
            ),
            if (!isInverse) ...[
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}


