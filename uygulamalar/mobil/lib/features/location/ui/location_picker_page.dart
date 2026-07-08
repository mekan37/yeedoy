import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/location/location_mapping.dart';
import '../../../core/location/user_location_controller.dart';
import '../../discovery/domain/city_districts_provider.dart';

// ── Static neighbourhood data ─────────────────────────────────────────────────

const _kNeighborhoods = <String, List<String>>{
  'Kadıköy': [
    'Caferağa', 'Moda', 'Fenerbahçe', 'Fikirtepe', 'Göztepe',
    'Kozyatağı', 'Bostancı', 'Caddebostan', 'Erenköy', 'Suadiye',
  ],
  'Beşiktaş': [
    'Levent', 'Etiler', 'Ortaköy', 'Bebek', 'Arnavutköy',
    'Kuruçeşme', 'Balmumcu', 'Gayrettepe', 'Türkali',
  ],
  'Beyoğlu': [
    'Cihangir', 'Galata', 'Karaköy', 'Taksim', 'Tarlabaşı',
    'Kasımpaşa', 'Tomtom', 'Piri Paşa',
  ],
  'Şişli': [
    'Harbiye', 'Nişantaşı', 'Fulya', 'Mecidiyeköy', 'Bomonti',
    'Pangaltı', 'Osmanbey', 'Esentepe',
  ],
  'Üsküdar': [
    'Mimar Sinan', 'Altunizade', 'Beylerbeyi', 'Çengelköy',
    'Kuzguncuk', 'Çamlıca', 'Acıbadem',
  ],
  'Çankaya': [
    'Kavaklıdere', 'Bahçelievler', 'Çukurambar', 'GOP', 'Ayrancı',
    'Gaziosmanpaşa', 'Birlik',
  ],
  'Konak': [
    'Alsancak', 'Hatay', 'Bornova', 'Güzelyalı', 'Bayraklı',
  ],
};

List<String> _neighborhoodsFor(String district) =>
    _kNeighborhoods[district] ?? [];

// ── Page ──────────────────────────────────────────────────────────────────────

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key});

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  String? _city;
  String? _district;
  String? _neighborhood;
  bool _bgLocation = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(userLocationProvider);
    _city = loc.city;
    _district = loc.district;
    _neighborhood = loc.neighborhood;
  }

  Future<void> _save() async {
    if (_city == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen il ve ilçe seçin.')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(userLocationProvider.notifier).setManualLocation(
          city: _city!,
          district: _district!,
          neighborhood: _neighborhood,
        );
    if (mounted) {
      setState(() => _saving = false);
      context.canPop() ? context.pop() : context.go('/discover');
    }
  }

  Future<void> _useGps() async {
    setState(() => _saving = true);
    await ref.read(userLocationProvider.notifier).useAutoLocation();
    if (mounted) {
      final loc = ref.read(userLocationProvider);
      setState(() {
        _city = loc.city;
        _district = loc.district;
        _neighborhood = loc.neighborhood;
        _saving = false;
      });
    }
  }

  void _pickCity(List<String> cities) {
    _showPickerSheet(
      context: context,
      title: 'İl Seçin',
      items: cities,
      selected: _city,
      onSelected: (v) => setState(() {
        _city = v;
        _district = null;
        _neighborhood = null;
      }),
    );
  }

  void _pickDistrict(List<String> districts) {
    if (districts.isEmpty) return;
    _showPickerSheet(
      context: context,
      title: 'İlçe Seçin',
      items: districts,
      selected: _district,
      onSelected: (v) => setState(() {
        _district = v;
        _neighborhood = null;
      }),
    );
  }

  void _pickNeighborhood() {
    final hoods = _neighborhoodsFor(_district ?? '');
    if (hoods.isEmpty) return;
    _showPickerSheet(
      context: context,
      title: 'Mahalle Seçin',
      items: hoods,
      selected: _neighborhood,
      onSelected: (v) => setState(() => _neighborhood = v),
      allowClear: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(cityDistrictsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: citiesAsync.when(
                loading: () => _buildBody(context, cities: [], allRows: []),
                error: (e, st) => _buildBody(context, cities: [], allRows: []),
                data: (rows) {
                  final allRows = rows
                      .map((r) => (
                            canonicalCity((r['city'] ?? '').toString()),
                            canonicalDistrict((r['district'] ?? '').toString()),
                          ))
                      .where((t) => t.$1.isNotEmpty && t.$2.isNotEmpty)
                      .toList();

                  final cityMap = <String, String>{};
                  for (final t in allRows) {
                    cityMap.putIfAbsent(t.$1.toLowerCase(), () => t.$1);
                  }
                  final cities = cityMap.values.toList()..sort();

                  return _buildBody(context, cities: cities, allRows: allRows);
                },
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<String> cities,
    required List<(String, String)> allRows,
  }) {
    final districts = allRows
        .where((r) => r.$1 == _city)
        .map((r) => r.$2)
        .toSet()
        .toList()
      ..sort();

    final neighborhoods = _neighborhoodsFor(_district ?? '');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTopBar(context),
        _buildSubtitle(),
        const SizedBox(height: 4),
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildSectionLabel('İl Seçin'),
        const SizedBox(height: 8),
        _buildDropdown(
          icon: Icons.location_on_outlined,
          value: _city ?? 'Seçiniz',
          onTap: cities.isEmpty ? null : () => _pickCity(cities),
        ),
        const SizedBox(height: 6),
        _buildHint('Bulunduğunuz şehirdeki işletmeleri ve fiyatları göreceksiniz.'),
        const SizedBox(height: 24),
        _buildSectionLabel('İlçe Seçin'),
        const SizedBox(height: 8),
        _buildDropdown(
          icon: Icons.map_outlined,
          value: _district ?? 'Seçiniz',
          onTap: (_city == null || districts.isEmpty)
              ? null
              : () => _pickDistrict(districts),
          disabled: _city == null,
        ),
        const SizedBox(height: 6),
        _buildHint('Daha doğru sonuçlar için ilçenizi seçin.'),
        const SizedBox(height: 24),
        _buildSectionLabelOptional('Mahalle'),
        const SizedBox(height: 8),
        _buildDropdown(
          icon: Icons.home_outlined,
          value: _neighborhood ?? 'Seçiniz (isteğe bağlı)',
          onTap: (_district == null || neighborhoods.isEmpty)
              ? null
              : _pickNeighborhood,
          disabled: _district == null || neighborhoods.isEmpty,
          isOptional: true,
        ),
        const SizedBox(height: 6),
        _buildHint('Mahalle seçerek çok daha yerel sonuçlar alabilirsiniz.'),
        const SizedBox(height: 20),
        _buildSelectedCard(),
        const SizedBox(height: 20),
        _buildLocationSettings(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          // Back button — rounded rectangle
          Material(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/discover'),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Konum Seç',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
          ),
          // Bell button — rounded rectangle with red dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        'Size özel öneriler ve fiyat alarmları için konumunuzu seçin.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.muted,
          height: 1.4,
        ),
      ),
    );
  }

  // ── Info card ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neden konum seçmeliyim?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textStrong,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bulunduğunuz konuma göre işletmeleri, fiyatları ve fırsatları en doğru şekilde gösteriyoruz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section labels ───────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppColors.textStrong,
        ),
      ),
    );
  }

  Widget _buildSectionLabelOptional(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Mahalle',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textStrong,
              ),
            ),
            TextSpan(
              text: '  (isteğe bağlı)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dropdown row ─────────────────────────────────────────────────────────────

  Widget _buildDropdown({
    required IconData icon,
    required String value,
    required VoidCallback? onTap,
    bool disabled = false,
    bool isOptional = false,
  }) {
    final isPlaceholder =
        disabled || (isOptional && value == 'Seçiniz (isteğe bağlı)');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: disabled ? AppColors.muted : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.w700,
                    color: isPlaceholder ? AppColors.muted : AppColors.textStrong,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: disabled ? AppColors.muted : AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.muted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selected location card ────────────────────────────────────────────────────

  Widget _buildSelectedCard() {
    final hasLoc = _city != null && _district != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seçilen Konumunuz',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLoc ? '$_city / $_district' : 'Henüz konum seçilmedi',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: hasLoc ? AppColors.textStrong : AppColors.muted,
                        ),
                      ),
                      if (_neighborhood != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$_neighborhood Mahallesi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _useGps,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 14),
                        label: const Text('Konumumu Kullan'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Location settings ────────────────────────────────────────────────────────

  Widget _buildLocationSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konum Ayarları',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.muted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arka planda konum izni',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textStrong,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fiyat alarmları ve fırsat bildirimleri için konum erişimi sağlanır.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _bgLocation,
                  onChanged: (v) => setState(() => _bgLocation = v),
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ──────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kaydet'),
        ),
      ),
    );
  }
}

// ── Picker bottom sheet ───────────────────────────────────────────────────────

void _showPickerSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String? selected,
  required ValueChanged<String> onSelected,
  bool allowClear = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PickerSheet(
      title: title,
      items: items,
      selected: selected,
      onSelected: onSelected,
      allowClear: allowClear,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.allowClear,
  });

  final String title;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool allowClear;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((i) => i.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Ara...',
                          hintStyle:
                              TextStyle(color: AppColors.muted, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textStrong),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final isSelected = item == widget.selected;
                  return ListTile(
                    dense: true,
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textStrong,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 18)
                        : null,
                    onTap: () {
                      widget.onSelected(item);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
