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
          child: points.isEmpty || points.every((v) => v == 0)
              ? SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).noPriceDataYet,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              : _PriceBarChart(points: points),
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
                  businessId: widget.businessId,
                  menuId: selectedMenuId,
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

class _BusinessMenuItemRow extends ConsumerStatefulWidget {
  const _BusinessMenuItemRow({
    required this.item,
    required this.variants,
    required this.imageAsset,
    required this.fallbackDescription,
    required this.businessId,
    required this.menuId,
  });

  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final String imageAsset;
  final String fallbackDescription;
  final String businessId;
  final String menuId;

  @override
  ConsumerState<_BusinessMenuItemRow> createState() =>
      _BusinessMenuItemRowState();
}

class _BusinessMenuItemRowState extends ConsumerState<_BusinessMenuItemRow> {
  String? _selectedVariantId;
  bool _voting = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
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
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(
                    type: item.priceStatus == 'verified'
                        ? StatusBadgeType.verified
                        : StatusBadgeType.pending,
                    label: item.priceStatus == 'verified'
                        ? t.verified
                        : t.pending,
                  ),
                  if (item.priceStatus == 'verified' &&
                      (item.total30d ?? 0) > 0)
                    Text(
                      t.localeName.startsWith('tr')
                          ? '${item.total30d} kullanıcı onayladı'
                          : '${item.total30d} users confirmed',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _voting ? null : () => _onPriceActionTap(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: _voting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.price_change_outlined, size: 18),
                  label: Text(
                    item.priceStatus == 'verified'
                        ? t.verifyPrice
                        : t.suggestNewPrice,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onPriceActionTap(BuildContext context) async {
    final isLoggedIn = ref.read(userProvider.select((user) => user != null));
    if (!isLoggedIn) {
      await showQuickLoginSheet(
        context,
        redirectPath: '/b/${widget.businessId}',
      );
      return;
    }
    final item = widget.item;
    if (item.priceStatus == 'verified') {
      setState(() => _voting = true);
      try {
        await ref
            .read(menuRepositoryProvider)
            .voteMenuItemPrice(
              menuItemId: item.id,
              vote: 1,
              businessId: widget.businessId,
              menuId: widget.menuId,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).thankYou)),
        );
      } catch (e) {
        if (!context.mounted) return;
        if (e is! OfflineQueuedException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppErrorMapper.message(e))),
          );
        }
      } finally {
        if (mounted) setState(() => _voting = false);
      }
      return;
    }
    if (widget.menuId.isEmpty) return;
    await showModalBottomSheet<PriceSuggestionSubmissionResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PriceSuggestionSheet(
        menuItemId: item.id,
        businessId: widget.businessId,
        menuId: widget.menuId,
      ),
    );
  }
}

/// Simple vertical-bar chart for price-history points.
/// Uses only core Flutter widgets — no external chart package.
class _PriceBarChart extends StatelessWidget {
  const _PriceBarChart({required this.points});

  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final values = points.isNotEmpty ? points : <int>[0];
    final maxValue = values.fold(0, (m, v) => v > m ? v : m);
    const barHeight = 80.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: barHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: maxValue <= 0
                            ? 6
                            : (6 + (values[i] / maxValue) * (barHeight - 6))
                                .clamp(6, barHeight),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${values[i]}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
