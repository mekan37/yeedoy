part of '../menu_item_page.dart';

// 14 EU alerjen kodu → Türkçe etiket eşleştirme tablosu
// İkon: assets/allergens/allergen_{code}.svg
const _kAllergenLabel = {
  'gluten':         'Gluten',
  'crustaceans':    'Kabuklu Deniz Ürünleri',
  'egg':            'Yumurta',
  'fish':           'Balık',
  'peanuts':        'Yer Fıstığı',
  'soy':            'Soya',
  'milk':           'Süt',
  'treenuts':       'Sert Kabuklu Yemişler',
  'celery':         'Kereviz',
  'mustard':        'Hardal',
  'sesame':         'Susam',
  'sulfur_dioxide': 'Kükürt Dioksit',
  'lupin':          'Acı Bakla',
  'molluscs':       'Yumuşakçalar',
};

class _AllergenSection extends StatelessWidget {
  const _AllergenSection({required this.allergens});
  final List<String> allergens;

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alerjenler', style: context.sectionTitleStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in allergens) _AllergenChip(code: code),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Alerji durumunuz için personele bilgi veriniz.',
            style: context.captionStyle,
          ),
        ],
      ),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final label = _kAllergenLabel[code] ?? code;
    final assetPath = 'assets/allergens/allergen_$code.svg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({
    required this.historyAsync,
    this.selectedVariant,
    required this.onRetry,
  });

  final AsyncValue<List<MenuItemPriceHistoryEntry>> historyAsync;
  final _MenuItemVariant? selectedVariant;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return historyAsync.when(
      loading: () => const _PriceHistorySkeleton(),
      error: (e, _) => _PriceHistoryError(
        message: AppErrorMapper.message(e),
        onRetry: onRetry,
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final sorted = [...items]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final latest = items.take(3).toList();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.priceHistoryLast3,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              if (selectedVariant != null) ...[
                const SizedBox(height: 4),
                Text(
                  t.menuSelectedVariantLabel(
                    selectedVariant!.label,
                    _formatPrice(
                      context,
                      selectedVariant!.priceCents / 100,
                      currencyCode: selectedVariant!.currency,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (sorted.length >= 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: _PriceLineChart(entries: sorted),
                ),
              ],
              const SizedBox(height: 8),
              for (final item in latest) ...[
                _PriceHistoryRow(item: item),
                const SizedBox(height: 6),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  const _PriceLineChart({required this.entries});
  final List<MenuItemPriceHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PriceLinePainter(
        entries: entries,
        lineColor: AppColors.primary,
        dotColor: AppColors.primary,
        gridColor: AppColors.border.withValues(alpha: 0.5),
        labelColor: AppColors.muted,
      ),
    );
  }
}

class _PriceLinePainter extends CustomPainter {
  _PriceLinePainter({
    required this.entries,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<MenuItemPriceHistoryEntry> entries;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    const double paddingLeft = 44;
    const double paddingRight = 8;
    const double paddingTop = 8;
    const double paddingBottom = 20;

    final chartW = size.width - paddingLeft - paddingRight;
    final chartH = size.height - paddingTop - paddingBottom;

    final prices = entries.map((e) => e.priceCents).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = (maxPrice - minPrice).toDouble();
    // Avoid division by zero
    final effectiveRange = priceRange < 1 ? 100.0 : priceRange;

    final times = entries.map((e) => e.createdAt.millisecondsSinceEpoch).toList();
    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final timeRange = (maxTime - minTime).toDouble();
    final effectiveTimeRange = timeRange < 1 ? 1.0 : timeRange;

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + chartH * (1 - i / 2);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // Y-axis labels
    final labelStyle = TextStyle(color: labelColor, fontSize: 9);
    for (int i = 0; i <= 2; i++) {
      final price = minPrice + (effectiveRange * i / 2);
      final y = paddingTop + chartH * (1 - i / 2);
      final text = '${(price / 100).toStringAsFixed(0)}₺';
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < entries.length; i++) {
      final t =
          (entries[i].createdAt.millisecondsSinceEpoch - minTime) /
          effectiveTimeRange;
      final p =
          (entries[i].priceCents - minPrice) / effectiveRange;
      final x = paddingLeft + t * chartW;
      final y = paddingTop + chartH * (1 - (priceRange < 1 ? 0.5 : p));
      points.add(Offset(x, y));
    }

    // Filled area under line
    final fillPath = Path()..moveTo(points.first.dx, paddingTop + chartH);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath
      ..lineTo(points.last.dx, paddingTop + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = lineColor.withValues(alpha: 0.08),
    );

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = dotColor;
    final dotBgPaint = Paint()..color = AppColors.card;
    for (final pt in points) {
      canvas.drawCircle(pt, 4, dotBgPaint);
      canvas.drawCircle(pt, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceLinePainter old) =>
      old.entries != entries;
}

class _PriceHistoryRow extends StatelessWidget {
  const _PriceHistoryRow({required this.item});
  final MenuItemPriceHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = _formatPriceFromCents(context, item.priceCents) ?? '-';
    final previous = _formatPriceFromCents(context, item.oldPriceCents);
    final deltaText = _priceDeltaText(item.oldPriceCents, item.priceCents);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previous == null
                    ? t.menuPriceHistoryCurrent(current, item.source)
                    : t.menuPriceHistoryTransition(
                        previous,
                        current,
                        item.source,
                      ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.menuPriceHistoryMeta(
                  _relativeTime(context, item.createdAt),
                  _fmtDate(item.createdAt),
                  deltaText ?? '',
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _priceDeltaText(int? oldPriceCents, int newPriceCents) {
  if (oldPriceCents == null || oldPriceCents <= 0) return null;
  final diff = newPriceCents - oldPriceCents;
  final pct = (diff / oldPriceCents * 100).abs();
  final sign = diff >= 0 ? '+' : '-';
  return '$sign${pct.toStringAsFixed(1)}%';
}

String _fmtDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class _PriceHistorySkeleton extends StatelessWidget {
  const _PriceHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonLine(width: 160),
          SizedBox(height: 8),
          AppSkeletonLine(width: 200),
          SizedBox(height: 6),
          AppSkeletonLine(width: 180),
        ],
      ),
    );
  }
}

class _PriceHistoryError extends StatelessWidget {
  const _PriceHistoryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
        ],
      ),
    );
  }
}

class _PriceStatusCard extends ConsumerWidget {
  const _PriceStatusCard({
    required this.item,
    required this.statusAsync,
    required this.onRetry,
    required this.onVote,
    required this.onUpdate,
    this.city,
    this.businessId,
  });

  final MenuItem item;
  final AsyncValue<MenuItemPriceStatus> statusAsync;
  final VoidCallback onRetry;
  final Future<void> Function(int vote) onVote;
  final VoidCallback onUpdate;
  final String? city;
  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final benchmarkKey =
        (city != null && city!.isNotEmpty && item.name.isNotEmpty)
        ? '${item.name}|$city|${businessId ?? ''}'
        : null;
    final benchmarkAsync = benchmarkKey != null
        ? ref.watch(menuItemPriceBenchmarkProvider(benchmarkKey))
        : null;
    return AppCard(
      child: statusAsync.when(
        loading: () => const _PriceStatusSkeleton(),
        error: (e, _) => _PriceStatusError(
          message: AppErrorMapper.message(e),
          onRetry: onRetry,
        ),
        data: (status) {
          final priceCents = status.priceCents;
          final priceText =
              _formatPriceFromCents(context, priceCents) ??
              _formatPrice(context, item.price);
          final badge = _statusBadge(status.status, t);
          final benchmark = benchmarkAsync?.asData?.value;
          final isTr = t.localeName.startsWith('tr');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Text(
                    t.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(type: badge.type, label: badge.label),
                  const Spacer(),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
              // Bağlam chip'leri
              if (benchmark != null && priceCents != null && priceCents > 0) ...[
                const SizedBox(height: 8),
                _PriceBenchmarkChip(
                  itemPriceCents: priceCents,
                  benchmark: benchmark,
                  isTr: isTr,
                ),
              ],
              if (item.timeWindows.isNotEmpty) ...[
                const SizedBox(height: 6),
                _TimeWindowInsightChip(windows: item.timeWindows, isTr: isTr),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Veri güveni — gerçek confidenceScore'a bağlı
              _DataTrustBar(score: status.confidenceScore, isTr: isTr),
              const SizedBox(height: 8),
              // Kompakt meta: son güncelleme · doğrulayıcı · oylar
              _PriceMetaRow(status: status, isTr: isTr),
              const SizedBox(height: 12),
              // Oy butonları
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onVote(1),
                      style: status.myVote == 1
                          ? OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                            )
                          : null,
                      icon: Icon(
                        status.myVote == 1
                            ? Icons.thumb_up_alt
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                      ),
                      label: Text(t.seenCorrect),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onVote(-1),
                      style: status.myVote == -1
                          ? OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            )
                          : null,
                      icon: Icon(
                        status.myVote == -1
                            ? Icons.thumb_down_alt
                            : Icons.thumb_down_alt_outlined,
                        size: 16,
                      ),
                      label: Text(t.seenIncorrect),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onUpdate,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(
                    t.suggestNewPrice,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriceStatusSkeleton extends StatelessWidget {
  const _PriceStatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppSkeletonLine(width: 140),
        SizedBox(height: 8),
        AppSkeletonLine(width: 200),
        SizedBox(height: 12),
        AppSkeletonLine(width: 180),
      ],
    );
  }
}

class _PriceStatusError extends StatelessWidget {
  const _PriceStatusError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.danger)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
      ],
    );
  }
}

class _ValueScoreSheet extends StatelessWidget {
  const _ValueScoreSheet({required this.score});
  final MenuItemValueScore score;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScoreCategoryPill(label: t.communityScoreInfoOnlyCategory),
          const SizedBox(height: 12),
          Text(
            t.howCalculated,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            t.communityScoreValueInsightSummary,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: t.verificationRate,
            value: _pct(score.verifiedRatio),
          ),
          _BreakdownRow(
            label: t.recentPositiveVotes,
            value: _pct(score.recentPositiveRatio),
          ),
          _BreakdownRow(
            label: t.priceStability,
            value: _pct(score.priceStability),
          ),
          const SizedBox(height: 6),
          Text(
            t.priceChangeLast30Days(score.priceChanges30d),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            t.scoreForInfoOnly,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            t.communityScoreValueUsage,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ValueScoreCard extends StatelessWidget {
  const _ValueScoreCard({
    required this.valueScoreAsync,
    required this.onExplain,
  });

  final AsyncValue<MenuItemValueScore> valueScoreAsync;
  final void Function(MenuItemValueScore score) onExplain;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: valueScoreAsync.when(
        loading: () => const AppSkeletonLine(width: 160),
        error: (_, _) => const SizedBox.shrink(),
        data: (score) {
          final pct = (score.score * 100).clamp(0, 100).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.pricePerformance,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    '%$pct',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (score.score).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: AppColors.cardAlt,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.valueScoreFormulaHint,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onExplain(score),
                  child: Text(t.howCalculated),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItemPhotosSection extends ConsumerStatefulWidget {
  const _MenuItemPhotosSection({
    required this.menuItemId,
    required this.photosAsync,
    required this.onRetry,
    required this.onVote,
    required this.onUpload,
    required this.onReport,
  });

  final String menuItemId;
  final AsyncValue<List<MenuItemPhoto>> photosAsync;
  final VoidCallback onRetry;
  final Future<void> Function(String photoId, int vote) onVote;
  final Future<void> Function() onUpload;
  final void Function(MenuItemPhoto photo) onReport;

  @override
  ConsumerState<_MenuItemPhotosSection> createState() =>
      _MenuItemPhotosSectionState();
}

class _MenuItemPhotosSectionState
    extends ConsumerState<_MenuItemPhotosSection> {
  bool _uploading = false;
  String _precacheKey = '';

  @override
  void initState() {
    super.initState();
    _precacheVisiblePhotos(widget.photosAsync.asData?.value ?? const []);
  }

  @override
  void didUpdateWidget(covariant _MenuItemPhotosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheVisiblePhotos(widget.photosAsync.asData?.value ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.menuPhotos,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _uploading ? null : _handleUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(t.updateMenuEarnPoints(20)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.menuPhotosHint,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            widget.photosAsync.when(
              loading: () => const _PhotosSkeleton(),
              error: (e, _) => _PhotosError(
                message: AppErrorMapper.message(e),
                onRetry: widget.onRetry,
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return const _PhotosEmpty();
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _PhotoTile(
                      photo: photo,
                      onTap: () => _openPhotoViewer(context, photos, index),
                      onVote: widget.onVote,
                      onReport: () => widget.onReport(photo),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    setState(() => _uploading = true);
    try {
      await widget.onUpload();
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _precacheVisiblePhotos(List<MenuItemPhoto> photos) {
    if (photos.isEmpty) return;
    final urls = photos
        .take(5)
        .map(
          (p) => p.urlThumb.isEmpty
              ? (p.urlLarge.isEmpty ? p.url : p.urlLarge)
              : p.urlThumb,
        )
        .where((u) => u.trim().isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    final nextKey = urls.join('|');
    if (nextKey == _precacheKey) return;
    _precacheKey = nextKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImageUrls(
          context,
          urls,
          variant: AppImageVariant.thumb,
          take: 5,
        ),
      );
    });
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onVote,
    required this.onReport,
  });

  final MenuItemPhoto photo;
  final VoidCallback onTap;
  final Future<void> Function(String photoId, int vote) onVote;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppNetworkImage(
                url: photo.urlThumb.isEmpty
                    ? (photo.urlLarge.isEmpty ? photo.url : photo.urlLarge)
                    : photo.urlThumb,
                variant: AppImageVariant.thumb,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _PhotoVoteButton(
                      icon: Icons.thumb_up_alt_outlined,
                      active: photo.myVote == 1,
                      onPressed: () => onVote(photo.id, 1),
                    ),
                    const SizedBox(width: 6),
                    _PhotoVoteButton(
                      icon: Icons.thumb_down_alt_outlined,
                      active: photo.myVote == -1,
                      onPressed: () => onVote(photo.id, -1),
                    ),
                    const Spacer(),
                    Text(
                      '${photo.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: IconButton(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, color: Colors.white),
                  iconSize: 18,
                  tooltip: AppLocalizations.of(context).report,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoVoteButton extends StatelessWidget {
  const _PhotoVoteButton({
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Icon(
        icon,
        size: 18,
        color: active ? AppColors.primary : Colors.white,
      ),
    );
  }
}

class _PhotosSkeleton extends StatelessWidget {
  const _PhotosSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

class _PhotosEmpty extends StatelessWidget {
  const _PhotosEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).noPhotosYet,
      style: const TextStyle(color: AppColors.muted),
    );
  }
}

class _PhotosError extends StatelessWidget {
  const _PhotosError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.danger)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
      ],
    );
  }
}

class _PhotoViewerPage extends StatelessWidget {
  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  final List<MenuItemPhoto> photos;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return InteractiveViewer(
            child: Center(
              child: AppNetworkImage(
                url: photo.urlLarge.isEmpty ? photo.url : photo.urlLarge,
                variant: AppImageVariant.medium,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

void _openPhotoViewer(
  BuildContext context,
  List<MenuItemPhoto> photos,
  int initialIndex,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _PhotoViewerPage(photos: photos, initialIndex: initialIndex),
    ),
  );
}

void _openMenuPhotoReport(
  BuildContext context,
  String businessId,
  MenuItemPhoto photo,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportBottomSheet.menuPhoto(
      menuItemPhotoId: photo.id,
      businessId: businessId,
      redirectUrl: GoRouterState.of(context).uri.toString(),
      initialReason: 'copyright',
      initialDetails: 'menu_item_photo:${photo.id}',
    ),
  );
}

class _PhotoQuality {
  const _PhotoQuality({required this.isDark, required this.isBlurry});
  final bool isDark;
  final bool isBlurry;
}

Future<_PhotoQuality?> _checkMenuPhotoQuality(String url) async {
  try {
    final data = await NetworkAssetBundle(Uri.parse(url)).load(url);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 120,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return null;

    final pixels = bytes.buffer.asUint8List();
    final width = image.width;
    final height = image.height;
    final step = 4;
    var sum = 0.0;
    var sumSq = 0.0;
    var edgeSum = 0.0;
    var count = 0;
    for (var y = 0; y < height; y += step) {
      final row = y * width;
      for (var x = 0; x < width; x += step) {
        final idx = (row + x) * 4;
        final r = pixels[idx];
        final g = pixels[idx + 1];
        final b = pixels[idx + 2];
        final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        sum += lum;
        sumSq += lum * lum;
        count++;
        if (x + step < width) {
          final idx2 = (row + x + step) * 4;
          final r2 = pixels[idx2];
          final g2 = pixels[idx2 + 1];
          final b2 = pixels[idx2 + 2];
          final lum2 = 0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2;
          edgeSum += (lum - lum2).abs();
        }
      }
    }
    if (count == 0) return null;
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    final edgeAvg = edgeSum / count;
    final isDark = mean < 60;
    final isBlurry = edgeAvg < 8 && variance < 500;
    return _PhotoQuality(isDark: isDark, isBlurry: isBlurry);
  } catch (_) {
    return null;
  }
}

String _formatPrice(
  BuildContext context,
  double? price, {
  String currencyCode = 'TRY',
}) {
  if (price == null) {
    return AppLocalizations.of(context).localeName.startsWith('tr')
        ? 'Fiyata sorunuz'
        : 'Price on request';
  }
  return formatCurrency(context, price, currencyCode: currencyCode);
}

String _rawPrice(double price) {
  return price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
}

double? _parsePrice(String value) {
  final cleaned = value.replaceAll(',', '.');
  return double.tryParse(cleaned);
}

String? _formatPriceFromCents(BuildContext context, int? cents) {
  if (cents == null) return null;
  final value = cents / 100.0;
  return _formatPrice(context, value);
}

String _pct(double value) {
  final pct = (value * 100).clamp(0, 100).round();
  return '%$pct';
}

String _relativeTime(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inDays < 1) return t.today;
  if (diff.inDays == 1) return t.yesterday;
  if (diff.inDays < 30) return t.timeDaysAgo(diff.inDays);
  final months = (diff.inDays / 30).floor();
  return t.timeMonthsAgo(months);
}

_StatusBadgeConfig _statusBadge(String status, AppLocalizations t) {
  switch (status) {
    case 'verified':
      return _StatusBadgeConfig(
        t.statusVerifiedShort,
        StatusBadgeType.verified,
      );
    case 'unverified':
      return _StatusBadgeConfig(t.statusMixedShort, StatusBadgeType.pending);
    case 'stale':
      return _StatusBadgeConfig(
        t.statusOutdatedShort,
        StatusBadgeType.outdated,
      );
    default:
      return _StatusBadgeConfig(t.statusUnknownShort, StatusBadgeType.pending);
  }
}

class _StatusBadgeConfig {
  const _StatusBadgeConfig(this.label, this.type);
  final String label;
  final StatusBadgeType type;
}

class _TimeWindowInsightChip extends StatelessWidget {
  const _TimeWindowInsightChip({
    required this.windows,
    required this.isTr,
  });

  final List<MenuItemTimeWindow> windows;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    // Prefer the currently-active window; otherwise the next upcoming one.
    final active = windows.where((w) => w.isActiveNow()).firstOrNull;
    final now = DateTime.now().hour;
    final upcoming = active == null
        ? (windows.where((w) => w.startHour > now).toList()
            ..sort((a, b) => a.startHour.compareTo(b.startHour)))
        : <MenuItemTimeWindow>[];
    final window = active ?? (upcoming.isNotEmpty ? upcoming.first : null);
    if (window == null) return const SizedBox.shrink();

    final label = window.label(isTr);
    final timeRange =
        '${window.startHour.toString().padLeft(2, '0')}:00–'
        '${window.endHour.toString().padLeft(2, '0')}:00';

    final String chipText;
    if (window.discountPct != null && window.discountPct! > 0) {
      chipText = active != null
          ? (isTr
              ? 'Şu an: $label • %${window.discountPct} indirimli ($timeRange)'
              : 'Now: $label • ${window.discountPct}% off ($timeRange)')
          : (isTr
              ? '$label daha uygun ($timeRange) • %${window.discountPct} indirim'
              : '$label is cheaper ($timeRange) • ${window.discountPct}% off');
    } else if (window.priceCents != null) {
      final priceText =
          '${(window.priceCents! / 100).toStringAsFixed(window.priceCents! % 100 == 0 ? 0 : 2)}₺';
      chipText = active != null
          ? (isTr
              ? 'Şu an: $label $priceText ($timeRange)'
              : 'Now: $label $priceText ($timeRange)')
          : (isTr
              ? '$label fiyatı $priceText ($timeRange)'
              : '$label price $priceText ($timeRange)');
    } else {
      chipText = active != null
          ? (isTr ? 'Şu an: $label ($timeRange)' : 'Now: $label ($timeRange)')
          : (isTr ? '$label ($timeRange)' : '$label ($timeRange)');
    }

    final chipColor = active != null ? AppColors.success : AppColors.info;
    return AppChip(
      label: chipText,
      color: chipColor,
      filled: active != null,
      leading: Icon(Icons.schedule_rounded, size: 14, color: chipColor),
    );
  }
}

class _DataTrustBar extends StatelessWidget {
  const _DataTrustBar({required this.score, required this.isTr});
  final double score;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).clamp(0, 100).round();
    final Color barColor;
    if (score >= 0.7) {
      barColor = AppColors.success;
    } else if (score >= 0.4) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.danger;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 14, color: barColor),
            const SizedBox(width: 5),
            Text(
              isTr ? 'Veri güveni' : 'Data trust',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: () => showCommunityScoreExplainerSheet(
                context,
                kind: CommunityScoreKind.dataTrust,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 13,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              '%$pct',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.cardAlt,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _PriceMetaRow extends StatelessWidget {
  const _PriceMetaRow({required this.status, required this.isTr});
  final MenuItemPriceStatus status;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (status.lastVerifiedAt != null) {
      final diff = DateTime.now().difference(status.lastVerifiedAt!);
      final String timeStr;
      if (diff.inHours < 24) {
        timeStr = isTr ? 'Bugün' : 'Today';
      } else if (diff.inDays == 1) {
        timeStr = isTr ? 'Dün' : 'Yesterday';
      } else if (diff.inDays < 30) {
        timeStr = isTr ? '${diff.inDays} gün önce' : '${diff.inDays}d ago';
      } else {
        final m = (diff.inDays / 30).floor();
        timeStr = isTr ? '$m ay önce' : '${m}mo ago';
      }
      parts.add(isTr ? 'Son güncelleme: $timeStr' : 'Updated: $timeStr');
    }
    if (status.verifiedSources48h > 0) {
      parts.add(
        isTr
            ? '${status.verifiedSources48h} doğrulayıcı'
            : '${status.verifiedSources48h} verifier${status.verifiedSources48h > 1 ? 's' : ''}',
      );
    }
    final totalVotes = status.okVotes + status.badVotes;
    if (totalVotes > 0) {
      parts.add(
        isTr ? '$totalVotes oylama' : '$totalVotes vote${totalVotes > 1 ? 's' : ''}',
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: const TextStyle(color: AppColors.muted, fontSize: 12),
    );
  }
}

class _TransparentMenuSection extends StatelessWidget {
  const _TransparentMenuSection({
    required this.caloriesMin,
    required this.portionSize,
    required this.ingredients,
  });

  final int? caloriesMin;
  final String? portionSize;
  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    final hasCalories = caloriesMin != null;
    final hasIngredients = ingredients.isNotEmpty;
    if (!hasCalories && !hasIngredients) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Şeffaf Menü', style: context.sectionTitleStyle),
          if (hasCalories) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '$caloriesMin kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                if (portionSize != null && portionSize!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '/ $portionSize',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (hasIngredients) ...[
            const SizedBox(height: 12),
            const Text(
              'İçindekiler',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ingredients.join(', '),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textStrong,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Değerler tahmini olabilir. Alerji durumunuz için lütfen personele bilgi veriniz.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBenchmarkChip extends StatelessWidget {
  const _PriceBenchmarkChip({
    required this.itemPriceCents,
    required this.benchmark,
    required this.isTr,
  });

  final int itemPriceCents;
  final MenuItemPriceBenchmark benchmark;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final avgPrice = benchmark.avgPriceCents / 100;
    final thisPrice = itemPriceCents / 100;
    final diff = thisPrice - avgPrice;
    final pctDiff = avgPrice > 0 ? (diff / avgPrice * 100).abs().round() : 0;
    final cheaper = diff < 0;
    final same = pctDiff <= 3;
    final color = same
        ? AppColors.muted
        : (cheaper ? AppColors.success : AppColors.danger);
    final avgText =
        avgPrice.truncateToDouble() == avgPrice
        ? '${avgPrice.toInt()}₺'
        : '${avgPrice.toStringAsFixed(2)}₺';
    final String label;
    if (same) {
      label = isTr
          ? 'Şehir ort: $avgText (benzer fiyat)'
          : 'City avg: $avgText (similar)';
    } else if (cheaper) {
      label = isTr
          ? 'Şehir ort: $avgText • %$pctDiff daha ucuz'
          : 'City avg: $avgText • $pctDiff% cheaper';
    } else {
      label = isTr
          ? 'Şehir ort: $avgText • %$pctDiff daha pahalı'
          : 'City avg: $avgText • $pctDiff% pricier';
    }
    return AppChip(label: label, color: color, filled: false);
  }
}
