import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/content/content_moderation.dart';
import '../../../core/errors/app_error_codes.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/reviews_repository.dart';
import '../domain/reviews_provider.dart';
import '../../profile/domain/profile_stats_provider.dart';
import '../../profile/domain/weekly_missions_provider.dart';

class ReviewCreatePage extends ConsumerStatefulWidget {
  const ReviewCreatePage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<ReviewCreatePage> createState() => _ReviewCreatePageState();
}

class _ReviewCreatePageState extends ConsumerState<ReviewCreatePage> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  int rating = 5;
  bool loading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final user = ref.watch(userProvider);

    return AppScaffold(
      appBar: AppBar(title: Text(t.writeReview)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.reviewCreateRatingLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < rating;
              return IconButton(
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? AppColors.star : AppColors.border,
                ),
                onPressed: () => setState(() => rating = i + 1),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: t.reviewCreateOptionalTitleLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentCtrl,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(labelText: t.reviewFallbackTitle),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final content = contentCtrl.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.reviewCreateContentRequired),
                          ),
                        );
                        return;
                      }
                      final moderation = await ContentModeration.instance
                          .validateReview(
                            content: content,
                            title: titleCtrl.text.trim(),
                          );
                      if (!context.mounted) return;
                      if (moderation != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _reviewModerationMessage(context, moderation),
                            ),
                          ),
                        );
                        return;
                      }

                      if (user == null) {
                        context.go('/login');
                        return;
                      }

                      setState(() => loading = true);
                      try {
                        await ref
                            .read(reviewsRepositoryProvider)
                            .createReview(
                              businessId: widget.businessId,
                              rating: rating,
                              title: titleCtrl.text.trim().isEmpty
                                  ? null
                                  : titleCtrl.text.trim(),
                              content: content,
                            );

                        if (!context.mounted) return;
                        final clientId = await getAnalyticsClientId();
                        await ref
                            .read(analyticsRepositoryProvider)
                            .logEvent(
                              eventName: AppEvents.reviewSubmit,
                              businessId: widget.businessId,
                              source: 'review_create_page',
                              clientId: clientId,
                              meta: {'rating': rating},
                            );
                        if (!context.mounted) return;
                        ref.invalidate(reviewsProvider(widget.businessId));
                        ref.invalidate(myWeeklyMissionsProvider);
                        ref.invalidate(myProfileStatsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.reviewCreateSubmitted)),
                        );
                        context.pop(); // business sayfasına dön
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = AppErrorMapper.message(e);
                        String friendly = msg;
                        if (msg.contains('new_account_rate_limited')) {
                          friendly = t.reviewCreateErrorNewAccountRateLimited;
                        } else if (msg.contains('same_business_cooldown')) {
                          friendly = t.reviewCreateErrorSameBusinessCooldown;
                        } else if (msg.contains(
                          AppErrorCodes.containsLinkOrPhone,
                        )) {
                          friendly = t.reviewCreateErrorContainsLinkOrPhone;
                        } else if (msg.contains(
                          AppErrorCodes.containsProfanity,
                        )) {
                          friendly = t.reviewCreateErrorContainsProfanity;
                        } else if (msg.contains(AppErrorCodes.emojiSpam)) {
                          friendly = t.reviewCreateErrorEmojiSpam;
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(friendly)));
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: Text(loading ? t.submitting : t.submit),
            ),
          ),
        ],
      ),
    );
  }
}

String _reviewModerationMessage(
  BuildContext context,
  ContentModerationResult moderation,
) {
  final t = context.l10n;
  switch (moderation.code) {
    case AppErrorCodes.containsLinkOrPhone:
      return t.reviewCreateErrorContainsLinkOrPhone;
    case AppErrorCodes.containsProfanity:
      return t.reviewCreateErrorContainsProfanity;
    case AppErrorCodes.emojiSpam:
      return t.reviewCreateErrorEmojiSpam;
    default:
      return moderation.message;
  }
}
