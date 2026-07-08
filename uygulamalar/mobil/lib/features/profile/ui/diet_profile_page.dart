import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../domain/diet_profile.dart';
import '../domain/diet_profile_controller.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _DietType {
  balanced,
  vegetarian,
  vegan,
  glutenFree,
  ketogenic,
  mediterranean,
}

enum _Goal { loseWeight, gainWeight, maintain, healthyEating }

// ── Allergens ─────────────────────────────────────────────────────────────────

const _kAllAllergens = [
  'Süt ve süt ürünleri',
  'Fındık',
  'Yumurta',
  'Deniz ürünleri',
  'Glüten',
  'Soya',
  'Susam',
  'Buğday',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class DietProfilePage extends ConsumerStatefulWidget {
  const DietProfilePage({super.key});

  @override
  ConsumerState<DietProfilePage> createState() => _DietProfilePageState();
}

class _DietProfilePageState extends ConsumerState<DietProfilePage> {
  _DietType _dietType = _DietType.balanced;
  _Goal? _goal;
  final Set<String> _allergens = {};
  bool _saving = false;
  bool _saved = false;
  String? _error;

  // Tracks whether we've already applied server data to local state.
  // Prevents overwriting user edits on subsequent rebuilds.
  bool _initialized = false;

  void _initFromProfile(DietProfile? profile) {
    if (_initialized) return;
    _initialized = true;
    if (profile == null) return; // no saved profile → keep UI defaults
    setState(() {
      if (profile.vegan) {
        _dietType = _DietType.vegan;
      } else if (profile.vegetarian) {
        _dietType = _DietType.vegetarian;
      } else if (profile.glutenFree) {
        _dietType = _DietType.glutenFree;
      } else {
        _dietType = _DietType.balanced;
      }
      if (profile.lactoseFree) _allergens.add('Süt ve süt ürünleri');
      if (profile.halal) _allergens.add('Helal');
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      final profile = DietProfile(
        vegan: _dietType == _DietType.vegan,
        vegetarian: _dietType == _DietType.vegetarian,
        glutenFree: _dietType == _DietType.glutenFree,
        lactoseFree: _allergens.contains('Süt ve süt ürünleri'),
        halal: _allergens.contains('Helal'),
      );
      await ref.read(dietProfileProvider.notifier).save(profile);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Kaydedilirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAllergenPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AllergenPickerSheet(
        selected: Set.from(_allergens),
        onConfirm: (updated) => setState(() {
          _allergens
            ..clear()
            ..addAll(updated);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(dietProfileProvider);

    // As soon as provider data arrives (or is already cached), init local state.
    // addPostFrameCallback avoids calling setState during build.
    if (!_initialized) {
      profileAsync.whenData((p) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _initFromProfile(p);
        });
      });
    }

    // Show full-screen loader while waiting for first data load.
    if (!_initialized && profileAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Show error state if provider failed and we have no local data yet.
    if (!_initialized && profileAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Expanded(
                child: Center(
                  child: Text(
                    'Profil yüklenemedi. Lütfen tekrar deneyin.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Diyet tercihin',
                    'Sana en uygun beslenme şeklini seç veya birden fazlasını işaretle.',
                  ),
                  const SizedBox(height: 12),
                  _buildDietGrid(),
                  const SizedBox(height: 8),
                  _buildOtherDietRow(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Hedefin',
                    'Sana daha doğru öneriler sunabilmemiz için hedefini belirt.',
                  ),
                  const SizedBox(height: 12),
                  _buildGoalRow(),
                  const SizedBox(height: 24),
                  _buildAllergenSection(),
                  if (_saved) ...[
                    const SizedBox(height: 20),
                    _buildSavedBanner(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(_error!),
                  ],
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
          ),
          const Expanded(
            child: Text(
              'Diyet Profili',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
          ),
          _IconBtn(
            icon: Icons.help_outline_rounded,
            onTap: () => _showHelpSheet(context),
          ),
        ],
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Diyet Profili Nedir?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Diyet profilin, yemek önerilerini ve menü filtrelerini kişiselleştirmek için kullanılır. '
              'Tercihlerini kaydederek sana en uygun işletmeleri ve yemekleri önerebiliriz.',
              style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sana özel lezzetler',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Diyet tercihlerine göre sana uygun mekanları ve yemekleri önerelim.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    _HeroFeature(icon: Icons.eco_outlined, label: 'Kişiselleştirilmiş\nöneriler'),
                    SizedBox(width: 12),
                    _HeroFeature(icon: Icons.favorite_outline_rounded, label: 'Daha sağlıklı\nseçimler'),
                    SizedBox(width: 12),
                    _HeroFeature(icon: Icons.star_outline_rounded, label: 'Zamanını\ntasarruf et'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _FoodIllustration(),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Diet type grid ────────────────────────────────────────────────────────────

  Widget _buildDietGrid() {
    final options = [
      _DietOption(
        type: _DietType.balanced,
        label: 'Dengeli Beslenme',
        desc: 'Tüm besin gruplarını dengeli tüketiyorum.',
        icon: Icons.restaurant_outlined,
        iconColor: AppColors.primary,
        iconBg: AppColors.primarySoft,
      ),
      _DietOption(
        type: _DietType.vegetarian,
        label: 'Vejetaryen',
        desc: 'Et ve et ürünleri tüketmiyorum.',
        icon: Icons.eco_outlined,
        iconColor: const Color(0xFF15803D),
        iconBg: const Color(0xFFDCFCE7),
      ),
      _DietOption(
        type: _DietType.vegan,
        label: 'Vegan',
        desc: 'Hiçbir hayvansal ürün tüketmiyorum.',
        icon: Icons.spa_outlined,
        iconColor: const Color(0xFF0F766E),
        iconBg: const Color(0xFFCCFBF1),
      ),
      _DietOption(
        type: _DietType.glutenFree,
        label: 'Glutensiz',
        desc: 'Glüten içeren besinleri tüketmiyorum.',
        icon: Icons.grain_outlined,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFEF3C7),
      ),
      _DietOption(
        type: _DietType.ketogenic,
        label: 'Ketojenik',
        desc: 'Düşük karbonhidrat, yüksek yağ.',
        icon: Icons.local_fire_department_outlined,
        iconColor: const Color(0xFF15803D),
        iconBg: const Color(0xFFDCFCE7),
      ),
      _DietOption(
        type: _DietType.mediterranean,
        label: 'Akdeniz Diyeti',
        desc: 'Zeytinyağı, sebze ve balık odaklı besleniyorum.',
        icon: Icons.waves_outlined,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFEDE9FE),
      ),
    ];

    final List<Widget> rows = [];
    for (int i = 0; i < options.length; i += 2) {
      final left = options[i];
      final right = i + 1 < options.length ? options[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _DietCard(option: left, selected: _dietType == left.type, onTap: () => setState(() => _dietType = left.type))),
            const SizedBox(width: 8),
            Expanded(
              child: right != null
                  ? _DietCard(option: right, selected: _dietType == right.type, onTap: () => setState(() => _dietType = right.type))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < options.length) rows.add(const SizedBox(height: 8));
    }

    return Column(children: rows);
  }

  Widget _buildOtherDietRow() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Diğer diyet tercihlerim var',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Goal row ──────────────────────────────────────────────────────────────────

  Widget _buildGoalRow() {
    final goals = [
      _GoalOption(goal: _Goal.loseWeight, label: 'Kilo vermek', icon: Icons.trending_down_rounded),
      _GoalOption(goal: _Goal.gainWeight, label: 'Kilo almak', icon: Icons.trending_up_rounded),
      _GoalOption(goal: _Goal.maintain, label: 'Kilo korumak', icon: Icons.remove_rounded),
      _GoalOption(goal: _Goal.healthyEating, label: 'Daha sağlıklı beslenmek', icon: Icons.favorite_outline_rounded),
    ];

    return Row(
      children: goals.map((g) {
        final selected = _goal == g.goal;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _goal = g.goal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(left: goals.indexOf(g) == 0 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    g.icon,
                    size: 22,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    g.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.textStrong,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Allergen section ──────────────────────────────────────────────────────────

  Widget _buildAllergenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Alerjiler ve hassasiyetler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _showAllergenPicker,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ekle'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Alerjinin veya hassasiyetin olan besinleri seç.',
          style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_allergens.isEmpty)
          GestureDetector(
            onTap: _showAllergenPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Text(
                  'Alerji veya hassasiyet ekle',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergens.map((a) => _AllergenChip(
              label: a,
              onRemove: () => setState(() => _allergens.remove(a)),
            )).toList(),
          ),
      ],
    );
  }

  // ── Saved banner ──────────────────────────────────────────────────────────────

  Widget _buildSavedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profilin kaydedildi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF15803D),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tercihlerine göre sana özel öneriler sunacağız.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Düzenle'),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.assignment_outlined, size: 20),
          label: const Text('Profili Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7F1D1D),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F5F7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppColors.textStrong),
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _FoodIllustration extends StatelessWidget {
  const _FoodIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.eco_rounded, size: 38, color: AppColors.primary),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Diet option data ──────────────────────────────────────────────────────────

class _DietOption {
  const _DietOption({
    required this.type,
    required this.label,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final _DietType type;
  final String label;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
}

class _DietCard extends StatelessWidget {
  const _DietCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _DietOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: option.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.desc,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: selected ? AppColors.primary : const Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal option data ──────────────────────────────────────────────────────────

class _GoalOption {
  const _GoalOption({
    required this.goal,
    required this.label,
    required this.icon,
  });

  final _Goal goal;
  final String label;
  final IconData icon;
}

// ── Allergen chip ─────────────────────────────────────────────────────────────

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ── Allergen picker sheet ─────────────────────────────────────────────────────

class _AllergenPickerSheet extends StatefulWidget {
  const _AllergenPickerSheet({
    required this.selected,
    required this.onConfirm,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onConfirm;

  @override
  State<_AllergenPickerSheet> createState() => _AllergenPickerSheetState();
}

class _AllergenPickerSheetState extends State<_AllergenPickerSheet> {
  late final Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Alerji veya hassasiyet seç',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Birden fazla seçebilirsin.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const Divider(height: 1),
          for (final allergen in _kAllAllergens)
            ListTile(
              title: Text(
                allergen,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _local.contains(allergen)
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: _local.contains(allergen)
                      ? AppColors.primary
                      : AppColors.textStrong,
                ),
              ),
              trailing: _local.contains(allergen)
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 18)
                  : null,
              onTap: () => setState(() {
                if (_local.contains(allergen)) {
                  _local.remove(allergen);
                } else {
                  _local.add(allergen);
                }
              }),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(Set.from(_local));
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Uygula'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
