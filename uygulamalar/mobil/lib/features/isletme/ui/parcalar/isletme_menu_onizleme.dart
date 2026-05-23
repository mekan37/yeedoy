part of '../isletme_sayfasi.dart';

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({required this.points});

  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final change = _priceDeltaPercent(points);
    final isUp = change >= 0;
    final trendColor = isUp ? AppColors.danger : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).priceHistory,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
                fontSize: 32,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.space8,
                vertical: tokens.space4,
              ),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${isUp ? '+' : ''}$change% ${AppLocalizations.of(context).threeMonthsShort}',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Container(
            height: 170,
            padding: EdgeInsets.all(tokens.space16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(tokens.radius16),
              border: Border.all(color: AppColors.border),
            ),
            child: _PriceHistoryChart(points: points),
          ),
        ),
      ],
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  const _PriceHistoryChart({required this.points});

  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final values = points.length >= 3 ? points.take(3).toList() : [0, 0, 0];

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PriceHistoryChartPainter(values),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < values.length; i++) ...[
              Expanded(
                child: Text(
                  '${values[i]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (i != values.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _PriceHistoryChartPainter extends CustomPainter {
  const _PriceHistoryChartPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final chartValues = values.isEmpty ? const [0, 0, 0] : values;
    final maxValue = chartValues.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue <= 0 ? 1 : maxValue;
    final stepX = chartValues.length <= 1
        ? size.width
        : size.width / (chartValues.length - 1);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      for (var i = 0; i < chartValues.length; i++)
        Offset(
          i * stepX,
          size.height - ((chartValues[i] / effectiveMax) * size.height),
        ),
    ];

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.22),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    final dotBorderPaint = Paint()..color = AppColors.card;
    for (final point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceHistoryChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _BusinessMenuPreviewSection extends ConsumerStatefulWidget {
  const _BusinessMenuPreviewSection({
    required this.businessId,
    required this.fallbackCategory,
  });

  final String businessId;
  final String fallbackCategory;

  @override
  ConsumerState<_BusinessMenuPreviewSection> createState() =>
      _BusinessMenuPreviewSectionState();
}

class _BusinessMenuPreviewSectionState
    extends ConsumerState<_BusinessMenuPreviewSection> {
  String? _selectedMenuId;
  String? _selectedSectionId;
  final Set<String> _excludeAllergens = {};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final menusAsync = ref.watch(businessMenusProvider(widget.businessId));
    if (menusAsync.isLoading) {
      return const AppSkeletonCard();
    }
    if (menusAsync.hasError) {
      return AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.menuDataUnavailable,
        description: AppErrorMapper.message(menusAsync.error!),
      );
    }
    final menus = menusAsync.value ?? const <BusinessMenu>[];
    if (menus.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }

    final validMenuIds = menus
        .map((e) => e.id)
        .where((e) => e.isNotEmpty)
        .toSet();
    if (_selectedMenuId == null || !validMenuIds.contains(_selectedMenuId)) {
      _selectedMenuId = _selectDefaultMenuId(menus);
    }
    final selectedMenuId = _selectedMenuId;
    if (selectedMenuId == null || selectedMenuId.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }

    final sectionsAsync = ref.watch(menuSectionsProvider(selectedMenuId));
    final itemsAsync = ref.watch(menuItemsProvider(selectedMenuId));

    if (sectionsAsync.isLoading || itemsAsync.isLoading) {
      return const AppSkeletonCard();
    }
    final error = sectionsAsync.error ?? itemsAsync.error;
    if (error != null) {
      return AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.menuDataUnavailable,
        description: AppErrorMapper.message(error),
      );
    }

    final sections = sectionsAsync.value ?? const <MenuSection>[];
    final allItems = itemsAsync.value ?? const <MenuItem>[];
    if (allItems.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }
    final variantKey =
        allItems
            .map((item) => item.id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final variantsByItem = ref.watch(
      _menuItemVariantsProvider(variantKey.join(',')).select((async) {
        return async.asData?.value ?? const <String, List<_MenuItemVariant>>{};
      }),
    );

    final validSectionIds = sections.map((e) => e.id).toSet();
    final selectedId = _selectedSectionId;
    if (selectedId != null && !validSectionIds.contains(selectedId)) {
      _selectedSectionId = null;
    }

    final filteredItems = allItems
        .where((item) {
          if (_selectedSectionId != null &&
              (item.sectionId ?? '') != _selectedSectionId) {
            return false;
          }
          if (_excludeAllergens.isNotEmpty &&
              item.allergens.any(_excludeAllergens.contains)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (menus.length > 1) ...[
          _MenuSelectorChips(
            menus: menus,
            selectedMenuId: selectedMenuId,
            onChanged: (value) => setState(() {
              _selectedMenuId = value;
              _selectedSectionId = null;
            }),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _MenuFilterChips(
                sections: sections,
                selectedSectionId: _selectedSectionId,
                onChanged: (value) =>
                    setState(() => _selectedSectionId = value),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showAllergenFilter(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _excludeAllergens.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _excludeAllergens.isNotEmpty
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 14,
                      color: _excludeAllergens.isNotEmpty
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    if (_excludeAllergens.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${_excludeAllergens.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_excludeAllergens.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final code in _excludeAllergens)
                GestureDetector(
                  onTap: () => setState(() => _excludeAllergens.remove(code)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _allergenTrName(code),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.close_rounded,
                          size: 10,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.menu,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < filteredItems.length; i++) ...[
                _BusinessMenuItemRow(
                  item: filteredItems[i],
                  variants: variantsByItem[filteredItems[i].id] ?? const [],
                  imageAsset: _menuImageForIndex(i),
                  fallbackDescription:
                      '${widget.fallbackCategory} ${t.featuredCuisineSuffix}',
                ),
                if (i != filteredItems.length - 1) const Divider(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static const _allergenMap = {
    'gluten': 'Gluten',
    'crustaceans': 'Kabuklu Deniz',
    'egg': 'Yumurta',
    'fish': 'Balık',
    'peanuts': 'Yer Fıstığı',
    'soy': 'Soya',
    'milk': 'Süt',
    'treenuts': 'Sert Kabuklu',
    'celery': 'Kereviz',
    'mustard': 'Hardal',
    'sesame': 'Susam',
    'sulfur_dioxide': 'SO₂',
    'lupin': 'Acı Bakla',
    'molluscs': 'Yumuşakçalar',
  };

  String _allergenTrName(String code) => _allergenMap[code] ?? code;

  Future<void> _showAllergenFilter(BuildContext context) async {
    // Work on a local copy so changes are atomic on confirm
    final copy = Set<String>.from(_excludeAllergens);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBottomState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alerjen Filtresi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seçili alerjenleri içeren ürünler gizlenir.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in _allergenMap.entries)
                      CheckboxListTile(
                        dense: true,
                        title: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: copy.contains(entry.key),
                        onChanged: (checked) => setBottomState(() {
                          if (checked == true) {
                            copy.add(entry.key);
                          } else {
                            copy.remove(entry.key);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setBottomState(() => copy.clear());
                      },
                      child: const Text('Temizle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _excludeAllergens
                            ..clear()
                            ..addAll(copy);
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectDefaultMenuId(List<BusinessMenu> menus) {
    if (menus.isEmpty) return null;
    final now = DateTime.now();
    for (final menu in menus) {
      if (menu.id.isEmpty) continue;
      final status = menu.status.toLowerCase();
      if (status == 'archived' || status == 'passive') continue;
      final from = DateTime.tryParse(menu.activeFrom ?? '');
      final to = DateTime.tryParse(menu.activeTo ?? '');
      final windowOk =
          (from == null || !from.isAfter(now)) &&
          (to == null || !to.isBefore(now));
      if (windowOk) return menu.id;
    }
    return menus.first.id;
  }
}

class _MenuSelectorChips extends StatelessWidget {
  const _MenuSelectorChips({
    required this.menus,
    required this.selectedMenuId,
    required this.onChanged,
  });

  final List<BusinessMenu> menus;
  final String selectedMenuId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < menus.length; i++) ...[
            if (i != 0) const SizedBox(width: 8),
            _MenuFilterChip(
              menu: menus[i],
              active: selectedMenuId == menus[i].id,
              onTap: () => onChanged(menus[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuFilterChips extends StatelessWidget {
  const _MenuFilterChips({
    required this.sections,
    required this.selectedSectionId,
    required this.onChanged,
  });

  final List<MenuSection> sections;
  final String? selectedSectionId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SectionFilterChip(
            label: t.tabAllItems,
            active: selectedSectionId == null,
            onTap: () => onChanged(null),
          ),
          for (final section in sections) ...[
            const SizedBox(width: 8),
            _SectionFilterChip(
              label: section.title,
              active: selectedSectionId == section.id,
              onTap: () => onChanged(section.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionFilterChip extends StatelessWidget {
  const _SectionFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radius24),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space16,
          vertical: tokens.space8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(tokens.radius24),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.onPrimary : AppColors.textStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MenuFilterChip extends StatelessWidget {
  const _MenuFilterChip({
    required this.menu,
    required this.active,
    required this.onTap,
  });

  final BusinessMenu menu;
  final bool active;
  final VoidCallback onTap;

  /// Returns "11:00-15:00" style label from ISO datetime strings, or null.
  String? _timeWindow() {
    final from = DateTime.tryParse(menu.activeFrom ?? '');
    final to = DateTime.tryParse(menu.activeTo ?? '');
    if (from == null && to == null) return null;
    String hm(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (from != null && to != null) return '${hm(from)}-${hm(to)}';
    if (from != null) return '${hm(from)}~';
    return '~${hm(to!)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final timeLabel = _timeWindow();
    final kindLabel = menu.kind;
    final subtitle = [kindLabel, timeLabel].nonNulls.join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radius24),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space16,
          vertical: tokens.space8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(tokens.radius24),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menu.title,
              style: TextStyle(
                color: active ? AppColors.onPrimary : AppColors.textStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: active
                      ? AppColors.onPrimary.withValues(alpha: 0.75)
                      : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BusinessMenuItemRow extends StatefulWidget {
  const _BusinessMenuItemRow({
    required this.item,
    required this.variants,
    required this.imageAsset,
    required this.fallbackDescription,
  });

  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final String imageAsset;
  final String fallbackDescription;

  @override
  State<_BusinessMenuItemRow> createState() => _BusinessMenuItemRowState();
}

class _BusinessMenuItemRowState extends State<_BusinessMenuItemRow> {
  String? _selectedVariantId;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final item = widget.item;
    final variants = widget.variants;
    if (_selectedVariantId != null &&
        !variants.any((v) => v.id == _selectedVariantId)) {
      _selectedVariantId = null;
    }
    final selectedVariant = (_selectedVariantId == null)
        ? (variants.isEmpty
              ? null
              : variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => variants.first,
                ))
        : variants.firstWhere(
            (v) => v.id == _selectedVariantId,
            orElse: () => variants.first,
          );

    final rawImageUrl = (item.imageUrl ?? '').trim();
    final remoteImageUrl = _resolveRemoteImageUrl(rawImageUrl);
    final dataImageBytes = _decodeDataImageBytes(rawImageUrl);
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius16),
          child: dataImageBytes != null
              ? Image.memory(
                  dataImageBytes,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                )
              : (remoteImageUrl != null
                    ? Image.network(
                        remoteImageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        semanticLabel: item.name,
                        errorBuilder: (_, _, _) => Container(
                          width: 76,
                          height: 76,
                          color: AppColors.card,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : (rawImageUrl.isNotEmpty
                          ? Container(
                              width: 76,
                              height: 76,
                              color: AppColors.card,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.muted,
                              ),
                            )
                          : Image.asset(
                              widget.imageAsset,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ))),
        ),
        SizedBox(width: tokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.price == null
                        ? (selectedVariant == null
                              ? AppLocalizations.of(context).unknown
                              : formatCurrency(
                                  context,
                                  selectedVariant.priceCents / 100,
                                  currencyCode: selectedVariant.currency,
                                ))
                        : formatCurrency(
                            context,
                            selectedVariant == null
                                ? item.price!
                                : (selectedVariant.priceCents / 100),
                            currencyCode: selectedVariant?.currency ?? 'TRY',
                          ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (item.description ?? '').trim().isEmpty
                    ? widget.fallbackDescription
                    : item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  StatusBadge(
                    type: item.priceStatus == 'verified'
                        ? StatusBadgeType.verified
                        : StatusBadgeType.pending,
                    label: item.priceStatus == 'verified'
                        ? AppLocalizations.of(context).verified
                        : AppLocalizations.of(context).pending,
                  ),
                  if (!item.isAvailable) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Tükendi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (variants.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final variant in variants)
                      ChoiceChip(
                        label: Text(variant.label),
                        selected: (selectedVariant?.id ?? '') == variant.id,
                        onSelected: (_) =>
                            setState(() => _selectedVariantId = variant.id),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return item.isAvailable
        ? rowContent
        : Opacity(opacity: 0.55, child: rowContent);
  }
}
