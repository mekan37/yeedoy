import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/content/content_moderation.dart';
import '../../../core/errors/app_error_codes.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/offline_submission_queue.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../auth/domain/auth_providers.dart';
import '../../favorites/domain/favorite_status_provider.dart';
import '../../favorites/domain/favorites_controller.dart';
import '../data/reviews_repository.dart';
import '../domain/review_catalog.dart';
import '../domain/reviews_provider.dart';
import '../../profile/domain/profile_stats_provider.dart';
import '../../profile/domain/weekly_missions_provider.dart';

/// Reusable review submission form. Used standalone by [ReviewCreatePage]
/// and embedded inline inside the business detail "Yorumlar" tab.
class ReviewCreateForm extends ConsumerStatefulWidget {
  const ReviewCreateForm({
    super.key,
    required this.businessId,
    this.onSubmitted,
  });

  final String businessId;

  /// Called after a review is successfully submitted (or queued offline).
  /// [ReviewCreatePage] uses this to pop back to the business page; inline
  /// usages can leave this null to simply reset the form in place.
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<ReviewCreateForm> createState() => _ReviewCreateFormState();
}

class _ReviewCreateFormState extends ConsumerState<ReviewCreateForm> {
  final contentCtrl = TextEditingController();
  int rating = 5;
  Map<ReviewRatingCriterion, int?> _criteriaRatings =
      ReviewCatalog.emptySelection();
  List<XFile> _selectedPhotos = const [];
  bool _addToFavorites = false;
  bool loading = false;

  static const _maxPhotos = 3;

  @override
  void dispose() {
    contentCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    contentCtrl.clear();
    rating = 5;
    _criteriaRatings = ReviewCatalog.emptySelection();
    _selectedPhotos = const [];
    _addToFavorites = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final tokens = AppTokens.of(context);
    final user = ref.watch(userProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.reviewCreateRatingLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        AppCard(
          child: Column(
            children: [
              _StarRow(
                value: rating,
                size: 40,
                onChanged: (v) => setState(() => rating = v),
              ),
              SizedBox(height: tokens.space8),
              Row(
                children: [
                  Text(
                    t.reviewCreateRatingHintLow,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    t.reviewCreateRatingHintHigh,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.space20),

        Text(
          t.reviewCreateContentLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        AppCard(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space12,
            vertical: tokens.space4,
          ),
          child: TextField(
            controller: contentCtrl,
            minLines: 4,
            maxLines: 8,
            maxLength: 500,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: t.reviewCreateContentPlaceholder,
            ),
          ),
        ),
        SizedBox(height: tokens.space20),

        Text(
          t.reviewCreatePhotosLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        _PhotoPickerGrid(
          photos: _selectedPhotos,
          maxPhotos: _maxPhotos,
          onAdd: () async {
            final picker = ImagePicker();
            final remaining = _maxPhotos - _selectedPhotos.length;
            if (remaining <= 0) return;
            final picked = await picker.pickMultiImage(limit: remaining);
            if (picked.isNotEmpty) {
              setState(() {
                _selectedPhotos = [
                  ..._selectedPhotos,
                  ...picked.take(remaining),
                ];
              });
            }
          },
          onRemove: (index) => setState(() {
            final list = List<XFile>.from(_selectedPhotos);
            list.removeAt(index);
            _selectedPhotos = list;
          }),
        ),
        SizedBox(height: tokens.space20),

        Text(
          t.reviewCreateExperienceLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        _CriteriaGrid(
          ratings: _criteriaRatings,
          onChanged: (criterion, value) => setState(() {
            _criteriaRatings = Map.of(_criteriaRatings)..[criterion] = value;
          }),
        ),
        SizedBox(height: tokens.space16),

        _FavoriteOptInRow(
          businessId: widget.businessId,
          value: _addToFavorites,
          onChanged: (v) => setState(() => _addToFavorites = v),
        ),
        SizedBox(height: tokens.space20),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radius20),
              ),
            ),
            onPressed: loading
                ? null
                : () async {
                    final content = contentCtrl.text.trim();
                    if (content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.reviewCreateContentRequired)),
                      );
                      return;
                    }
                    final moderation = await ContentModeration.instance
                        .validateReview(content: content, title: null);
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
                      final reviewId = await ref
                          .read(reviewsRepositoryProvider)
                          .createReview(
                            businessId: widget.businessId,
                            rating: rating,
                            title: null,
                            content: content,
                            criteriaRatings: _criteriaRatings,
                          );

                      // Upload photos if any (best-effort, non-fatal)
                      if (reviewId != null && _selectedPhotos.isNotEmpty) {
                        final userId = ref.read(userProvider)?.id ?? '';
                        try {
                          await ref
                              .read(reviewsRepositoryProvider)
                              .uploadReviewPhotos(
                                reviewId: reviewId,
                                businessId: widget.businessId,
                                userId: userId,
                                files: _selectedPhotos,
                              );
                        } catch (_) {
                          // Photo upload failure is non-fatal
                        }
                      }

                      if (_addToFavorites) {
                        final alreadyFavorited = ref.read(
                          isFavoritedProvider(widget.businessId),
                        );
                        if (!alreadyFavorited) {
                          try {
                            await ref
                                .read(favoritesControllerProvider.notifier)
                                .toggleFavorite(widget.businessId);
                          } catch (_) {
                            // Favorite toggle failure is non-fatal
                          }
                        }
                      }

                      if (!context.mounted) return;
                      final clientId = await getAnalyticsClientId();
                      final criteriaCount = ReviewCatalog.selectedCount(
                        _criteriaRatings,
                      );
                      await ref
                          .read(analyticsRepositoryProvider)
                          .logEvent(
                            eventName: AppEvents.reviewSubmit,
                            businessId: widget.businessId,
                            source: 'review_create_page',
                            clientId: clientId,
                            meta: {
                              'rating': rating,
                              'criteria_count': criteriaCount,
                              'photo_count': _selectedPhotos.length,
                            },
                          );
                      if (!context.mounted) return;
                      ref.invalidate(reviewsProvider(widget.businessId));
                      ref.invalidate(myWeeklyMissionsProvider);
                      ref.invalidate(myProfileStatsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.reviewCreateSubmitted)),
                      );
                      setState(_resetForm);
                      widget.onSubmitted?.call();
                    } on OfflineSubmissionQueuedException {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.weakConnectionQueueNotice)),
                      );
                      setState(_resetForm);
                      widget.onSubmitted?.call();
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
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(
                    t.reviewCreateSubmitCta,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteOptInRow extends ConsumerWidget {
  const _FavoriteOptInRow({
    required this.businessId,
    required this.value,
    required this.onChanged,
  });

  final String businessId;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final alreadyFavorited = ref.watch(isFavoritedProvider(businessId));
    if (alreadyFavorited) return const SizedBox.shrink();
    return AppCard(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(
            child: Text(
              t.reviewCreateAddToFavorites,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Icon(Icons.favorite_border, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _PhotoPickerGrid extends StatelessWidget {
  const _PhotoPickerGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  static const double _tileSize = 84;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final tokens = AppTokens.of(context);
    return Wrap(
      spacing: tokens.space8,
      runSpacing: tokens.space8,
      children: [
        if (photos.length < maxPhotos)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: _tileSize,
              height: _tileSize,
              padding: EdgeInsets.all(tokens.space4),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(tokens.radius16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: tokens.space4),
                  Text(
                    t.reviewCreateAddPhoto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                  Text(
                    t.reviewCreateAddPhotoHint(maxPhotos),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        for (var i = 0; i < photos.length; i++)
          _PhotoThumb(
            file: photos[i],
            size: _tileSize,
            onRemove: () => onRemove(i),
          ),
      ],
    );
  }
}

class _PhotoThumb extends StatefulWidget {
  const _PhotoThumb({
    required this.file,
    required this.onRemove,
    this.size = 80,
  });
  final XFile file;
  final VoidCallback onRemove;
  final double size;

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          FutureBuilder<Uint8List>(
            future: _bytesFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  snap.data!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.value,
    required this.onChanged,
    this.size = 28,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          tooltip: AppLocalizations.of(context).ratingLabel(i + 1),
          constraints: BoxConstraints(minWidth: size + 8, minHeight: size + 8),
          padding: EdgeInsets.zero,
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: filled
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.28),
          ),
          onPressed: () => onChanged(i + 1),
        );
      }),
    );
  }
}

class _CriteriaGrid extends StatelessWidget {
  const _CriteriaGrid({required this.ratings, required this.onChanged});

  final Map<ReviewRatingCriterion, int?> ratings;
  final void Function(ReviewRatingCriterion criterion, int? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final definitions = ReviewCatalog.definitions;
    final rows = <Widget>[];
    for (var i = 0; i < definitions.length; i += 2) {
      final left = definitions[i];
      final right = i + 1 < definitions.length ? definitions[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + 2 < definitions.length ? tokens.space8 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CriteriaCard(
                  definition: left,
                  value: ratings[left.criterion],
                  onChanged: (v) => onChanged(left.criterion, v),
                ),
              ),
              if (right != null) ...[
                SizedBox(width: tokens.space8),
                Expanded(
                  child: _CriteriaCard(
                    definition: right,
                    value: ratings[right.criterion],
                    onChanged: (v) => onChanged(right.criterion, v),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  final ReviewCriterion definition;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space12,
        vertical: tokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _criterionIcon(definition.criterion),
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: tokens.space8),
              Expanded(
                child: Text(
                  definition.label(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space8),
          Row(
            children: List.generate(5, (i) {
              final filled = value != null && i < value!;
              return GestureDetector(
                onTap: () => onChanged(value == i + 1 ? null : i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 20,
                    color: filled ? AppColors.star : AppColors.border,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

IconData _criterionIcon(ReviewRatingCriterion criterion) {
  switch (criterion) {
    case ReviewRatingCriterion.taste:
      return Icons.restaurant_outlined;
    case ReviewRatingCriterion.serviceSpeed:
      return Icons.room_service_outlined;
    case ReviewRatingCriterion.pricePerformance:
      return Icons.payments_outlined;
    case ReviewRatingCriterion.cleanliness:
      return Icons.cleaning_services_outlined;
    case ReviewRatingCriterion.atmosphere:
      return Icons.deck_outlined;
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
