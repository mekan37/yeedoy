part of '../business_page.dart';

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
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(tokens.radius16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context).chartPlaceholderSoon,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
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

    final filteredItems = _selectedSectionId == null
        ? allItems
        : allItems
              .where((item) => (item.sectionId ?? '') == _selectedSectionId)
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
        _MenuFilterChips(
          sections: sections,
          selectedSectionId: _selectedSectionId,
          onChanged: (value) => setState(() => _selectedSectionId = value),
        ),
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
              label: menus[i].title,
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
          _MenuFilterChip(
            label: t.tabAllItems,
            active: selectedSectionId == null,
            onTap: () => onChanged(null),
          ),
          for (final section in sections) ...[
            const SizedBox(width: 8),
            _MenuFilterChip(
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

class _MenuFilterChip extends StatelessWidget {
  const _MenuFilterChip({
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
    return Row(
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
              StatusBadge(
                type: item.priceStatus == 'verified'
                    ? StatusBadgeType.verified
                    : StatusBadgeType.pending,
                label: item.priceStatus == 'verified'
                    ? AppLocalizations.of(context).verified
                    : AppLocalizations.of(context).pending,
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
  }
}
