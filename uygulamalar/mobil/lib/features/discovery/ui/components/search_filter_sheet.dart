import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/location/user_location_controller.dart';
import '../../domain/discovery_search_notifier.dart';
import '../../domain/discovery_search_state.dart';

/// Styled "Arama & Filtrele" bottom sheet.
/// Opens via showModalBottomSheet with isScrollControlled: true.
class SearchFilterSheet extends ConsumerStatefulWidget {
  const SearchFilterSheet({
    super.key,
    required this.initialState,
    required this.initialQuery,
  });

  final DiscoverySearchState initialState;
  final String initialQuery;

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  late final TextEditingController _queryCtrl;
  late String _category;
  String _cuisine = '';
  bool _cuisineExpanded = true;
  late RangeValues _priceRange;
  late int _ratingIdx; // 0=Tümü, 1=1+, 2=2+, 3=3+, 4=4+
  late int _openStatus; // 0=Tümü, 1=Açık Olanlar, 2=Şu An Açık, 3=Kapalılar
  bool _hasOffers = false;
  bool _hasPriceAlert = false;
  bool _favoritesOnly = false;

  List<(String, String)> _categories(BuildContext context) => [
    ('', context.l10n.searchFilterAllOption),
    ('Restoran', context.l10n.searchFilterCategoryRestaurant),
    ('Kafe', context.l10n.searchFilterCategoryCafe),
    ('Fast Food', context.l10n.searchFilterCategoryFastFood),
    ('Tatlı / Pastane', context.l10n.searchFilterCategoryBakery),
    ('Kahvaltı', context.l10n.searchFilterCategoryBreakfast),
    ('Balık / Et', context.l10n.searchFilterCategoryFishMeat),
    ('Mekan', context.l10n.searchFilterCategoryVenue),
  ];

  List<(String, String)> _cuisines(BuildContext context) => [
    ('Türk Mutfağı', context.l10n.searchFilterCuisineTurkish),
    ('İtalyan', context.l10n.searchFilterCuisineItalian),
    ('Uzakdoğu', context.l10n.searchFilterCuisineFarEast),
    ('Hamburger', context.l10n.searchFilterCuisineHamburger),
    ('Vejetar', context.l10n.searchFilterCuisineVegetarian),
    ('Çin', context.l10n.searchFilterCuisineChinese),
    ('Meksika', context.l10n.searchFilterCuisineMexican),
    ('Hint', context.l10n.searchFilterCuisineIndian),
    ('Japon', context.l10n.searchFilterCuisineJapanese),
  ];

  @override
  void initState() {
    super.initState();
    final st = widget.initialState;
    _queryCtrl = TextEditingController(text: widget.initialQuery);
    _category = st.category;
    _priceRange = RangeValues(
      0,
      st.maxBudgetCents != null
          ? (st.maxBudgetCents! / 100).clamp(0, 1000).toDouble()
          : 1000,
    );
    _ratingIdx = st.minRating.round().clamp(0, 4);
    _openStatus = st.openNow ? 1 : 0;
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _queryCtrl.clear();
      _category = '';
      _cuisine = '';
      _priceRange = const RangeValues(0, 1000);
      _ratingIdx = 0;
      _openStatus = 0;
      _hasOffers = false;
      _hasPriceAlert = false;
      _favoritesOnly = false;
    });
  }

  Future<void> _apply() async {
    final notifier = ref.read(discoverySearchProvider.notifier);
    final query = _queryCtrl.text.trim();
    final effectiveCategory = _cuisine.isNotEmpty ? _cuisine : _category;
    final maxBudget = _priceRange.end >= 1000
        ? null
        : (_priceRange.end * 100).round();

    await notifier.setFilters(
      category: effectiveCategory,
      minRating: _ratingIdx.toDouble(),
      openNow: _openStatus == 1 || _openStatus == 2,
      maxBudgetCents: maxBudget,
    );
    if (query != widget.initialQuery) {
      notifier.setQuery(query, withDebounce: false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(discoverySearchProvider);
    final loc = ref.watch(userLocationProvider);
    final locationLabel = [
      loc.city,
      loc.district,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    final itemCount = st.items.length;

    final sheetHeight = MediaQuery.sizeOf(context).height * 0.93;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textStrong,
                ),
                Expanded(
                  child: Text(
                    context.l10n.searchFilterPageTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    context.l10n.searchFilterClearButton,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _queryCtrl,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchFilterSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Konum ─────────────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.location_on_outlined,
                    title: context.l10n.searchFilterLocationSectionTitle,
                    trailing: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/location-picker');
                      },
                      child: Text(
                        context.l10n.searchFilterChangeButton,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationLabel.isNotEmpty
                                  ? locationLabel
                                  : context.l10n.searchFilterLocationNotSelected,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Kategoriler ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.apps_rounded,
                    title: context.l10n.searchFilterCategoriesSectionTitle,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final (value, label) in _categories(context)) ...[
                          _FilterChip(
                            label: label,
                            selected: _category == value && _cuisine.isEmpty,
                            onTap: () => setState(() {
                              _category = value;
                              _cuisine = '';
                            }),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Mutfak Türü ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.ramen_dining_outlined,
                    title: context.l10n.searchFilterCuisineSectionTitle,
                    trailing: GestureDetector(
                      onTap: () =>
                          setState(() => _cuisineExpanded = !_cuisineExpanded),
                      child: Icon(
                        _cuisineExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  if (_cuisineExpanded) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (value, label) in _cuisines(context))
                            _FilterChip(
                              label: label,
                              selected: _cuisine == value,
                              onTap: () => setState(() {
                                _cuisine = _cuisine == value ? '' : value;
                                if (_cuisine.isNotEmpty) _category = '';
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Fiyat Aralığı ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.sell_outlined,
                    title: context.l10n.searchFilterPriceRangeSectionTitle,
                    trailing: GestureDetector(
                      onTap: _showPriceInput,
                      child: Text(
                        context.l10n.searchFilterEnterRangeButton,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${_priceRange.start.round()}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _priceRange.end >= 1000
                              ? '₺1000+'
                              : '₺${_priceRange.end.round()}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Puan ─────────────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.star_outline_rounded,
                    title: context.l10n.searchFilterRatingSectionTitle,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: context.l10n.searchFilterAllOption,
                          selected: _ratingIdx == 0,
                          onTap: () => setState(() => _ratingIdx = 0),
                        ),
                        const SizedBox(width: 8),
                        for (final r in [4, 3, 2, 1]) ...[
                          _FilterChip(
                            label: '$r+',
                            trailing: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBC04),
                              size: 15,
                            ),
                            selected: _ratingIdx == r,
                            onTap: () => setState(() => _ratingIdx = r),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Açık / Kapalı ─────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.schedule_outlined,
                    title: context.l10n.searchFilterOpenClosedSectionTitle,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: context.l10n.searchFilterAllOption,
                          selected: _openStatus == 0,
                          onTap: () => setState(() => _openStatus = 0),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: context.l10n.searchFilterOpenOnly,
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34A853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          selected: _openStatus == 1,
                          onTap: () => setState(() => _openStatus = 1),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: context.l10n.searchFilterOpenNow,
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1AAD5B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          selected: _openStatus == 2,
                          onTap: () => setState(() => _openStatus = 2),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: context.l10n.searchFilterClosedOnly,
                          leading: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.muted.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          selected: _openStatus == 3,
                          onTap: () => setState(() => _openStatus = 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 20),
                  // ── Diğer Filtreler ───────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.tune_rounded,
                    title: context.l10n.searchFilterOtherFiltersSectionTitle,
                  ),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    icon: Icons.local_offer_outlined,
                    title: context.l10n.searchFilterOffersTitle,
                    subtitle: context.l10n.searchFilterOffersSubtitle,
                    value: _hasOffers,
                    onChanged: (v) => setState(() => _hasOffers = v),
                  ),
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    title: context.l10n.searchFilterPriceAlertTitle,
                    subtitle: context.l10n.searchFilterPriceAlertSubtitle,
                    value: _hasPriceAlert,
                    onChanged: (v) => setState(() => _hasPriceAlert = v),
                  ),
                  _ToggleRow(
                    icon: Icons.favorite_outline,
                    title: context.l10n.searchFilterFavoritesTitle,
                    subtitle: context.l10n.searchFilterFavoritesSubtitle,
                    value: _favoritesOnly,
                    onChanged: (v) => setState(() => _favoritesOnly = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // ── Bottom button ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.searchFilterShowResultsButton(itemCount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceInput() {
    final minCtrl = TextEditingController(
      text: _priceRange.start.round().toString(),
    );
    final maxCtrl = TextEditingController(
      text: _priceRange.end >= 1000 ? '' : _priceRange.end.round().toString(),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.searchFilterPriceDialogTitle),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ctx.l10n.searchFilterMinPriceLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('—'),
            ),
            Expanded(
              child: TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ctx.l10n.searchFilterMaxPriceLabel,
                  hintText: ctx.l10n.searchFilterMaxPriceHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.searchFilterCancelButton),
          ),
          FilledButton(
            onPressed: () {
              final min = double.tryParse(minCtrl.text) ?? 0;
              final max = double.tryParse(maxCtrl.text) ?? 1000;
              setState(() {
                _priceRange = RangeValues(
                  min.clamp(0, 999),
                  max.clamp(min, 1000),
                );
              });
              Navigator.pop(ctx);
            },
            child: Text(ctx.l10n.searchFilterApplyButton),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bg,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textStrong,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            if (selected) ...[
              const SizedBox(width: 5),
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ─────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
