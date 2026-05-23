import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_istemcisi.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/icerik/icerik_denetimi.dart';
import '../../../core/hatalar/uygulama_hata_kodlari.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/depolama/cevrimdisi_gonderim_kuyrugu.dart';
import '../../../features/shared/ui/bilesenler/uygulama_iskele.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/yorumlar_deposu.dart';
import '../domain/yorum_katalogu.dart';
import '../domain/yorumlar_saglayicilari.dart';
import '../../profil/domain/profil_istatistikleri_saglayicisi.dart';
import '../../profil/domain/haftalik_gorevler_saglayicisi.dart';

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
  Map<ReviewRatingCriterion, int?> _criteriaRatings =
      ReviewCatalog.emptySelection();
  List<XFile> _selectedPhotos = const [];
  bool loading = false;

  static const _maxPhotos = 3;

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
          _StarRow(
            value: rating,
            onChanged: (v) => setState(() => rating = v),
          ),
          const SizedBox(height: 16),
          Text(
            t.localeName.startsWith('tr')
                ? 'Detaylı Değerlendirme (isteğe bağlı)'
                : 'Detailed rating (optional)',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final def in ReviewCatalog.definitions) ...[
            _CriteriaRow(
              label: def.label(t),
              value: _criteriaRatings[def.criterion],
              onChanged: (v) => setState(() {
                _criteriaRatings = Map.of(_criteriaRatings)
                  ..[def.criterion] = v;
              }),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          Text(
            t.localeName.startsWith('tr')
                ? 'Fotoğraf Ekle (isteğe bağlı, en fazla $_maxPhotos)'
                : 'Add photos (optional, max $_maxPhotos)',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _PhotoPickerRow(
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
                        final reviewId = await ref
                            .read(reviewsRepositoryProvider)
                            .createReview(
                              businessId: widget.businessId,
                              rating: rating,
                              title: titleCtrl.text.trim().isEmpty
                                  ? null
                                  : titleCtrl.text.trim(),
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
                        context.pop(); // business sayfasına dön
                      } on OfflineSubmissionQueuedException {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.weakConnectionQueueNotice)),
                        );
                        context.pop();
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

class _PhotoPickerRow extends StatelessWidget {
  const _PhotoPickerRow({
    required this.photos,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> photos;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photos.length; i++) ...[
            _PhotoThumb(file: photos[i], onRemove: () => onRemove(i)),
            const SizedBox(width: 8),
          ],
          if (photos.length < maxPhotos)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatefulWidget {
  const _PhotoThumb({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

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
      width: 80,
      height: 80,
      child: Stack(
        children: [
          FutureBuilder<Uint8List>(
            future: _bytesFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Container(
                  width: 80,
                  height: 80,
                  color: AppColors.card,
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  snap.data!,
                  width: 80,
                  height: 80,
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
  const _StarRow({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          tooltip: AppLocalizations.of(context).ratingLabel(i + 1),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? AppColors.star : AppColors.border,
          ),
          onPressed: () => onChanged(i + 1),
        );
      }),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  const _CriteriaRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        ...List.generate(5, (i) {
          final filled = value != null && i < value!;
          return GestureDetector(
            onTap: () {
              // Tap same star again → clear
              if (value == i + 1) {
                onChanged(null);
              } else {
                onChanged(i + 1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: 22,
                color: filled ? AppColors.star : AppColors.border,
              ),
            ),
          );
        }),
      ],
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





