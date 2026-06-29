import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../shared/ui/components/app_scaffold.dart';
import '../../shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/diet_profile.dart';
import '../domain/diet_profile_controller.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class DietProfilePage extends ConsumerStatefulWidget {
  const DietProfilePage({super.key});

  @override
  ConsumerState<DietProfilePage> createState() => _DietProfilePageState();
}

class _DietProfilePageState extends ConsumerState<DietProfilePage> {
  DietProfile? _local;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProvider());
  }

  void _syncFromProvider() {
    ref.read(dietProfileProvider).whenData((p) {
      if (mounted) {
        setState(() {
          _local = p ??
              DietProfile(
                vegan: false,
                vegetarian: false,
                glutenFree: false,
                lactoseFree: false,
                halal: false,
              );
        });
      }
    });
  }

  void _toggle(_BoolField field) {
    final p = _local;
    if (p == null) return;
    setState(() {
      _local = switch (field) {
        _BoolField.vegan => p.copyWith(vegan: !p.vegan),
        _BoolField.vegetarian => p.copyWith(vegetarian: !p.vegetarian),
        _BoolField.glutenFree => p.copyWith(glutenFree: !p.glutenFree),
        _BoolField.lactoseFree => p.copyWith(lactoseFree: !p.lactoseFree),
        _BoolField.halal => p.copyWith(halal: !p.halal),
      };
    });
  }

  Future<void> _save() async {
    final profile = _local;
    if (profile == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(dietProfileProvider.notifier).save(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diyet profilin kaydedildi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Kaydedilirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(dietProfileProvider);
    final tokens = AppTokens.of(context);

    ref.listen(dietProfileProvider, (_, next) {
      next.whenData((p) {
        if (_local == null && p != null && mounted) {
          setState(() => _local = p);
        }
      });
    });

    return AppScaffold(
      appBar: AppAppBar(
        title: const Text('Diyet Profilim'),
        showProfileAction: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorBody(onRetry: _syncFromProvider),
        data: (_) {
          final local = _local;
          if (local == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Body(
            profile: local,
            saving: _saving,
            error: _error,
            tokens: tokens,
            onToggle: _toggle,
            onSave: _save,
          );
        },
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.profile,
    required this.saving,
    required this.error,
    required this.tokens,
    required this.onToggle,
    required this.onSave,
  });

  final DietProfile profile;
  final bool saving;
  final String? error;
  final AppTokens tokens;
  final void Function(_BoolField) onToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space16,
        vertical: tokens.space16,
      ),
      children: [
        _InfoHeader(tokens: tokens),
        SizedBox(height: tokens.space20),
        _Section(
          title: 'Beslenme Tercihleri',
          icon: Icons.eco_outlined,
          iconColor: const Color(0xFF15803D),
          iconBg: const Color(0xFFDCFCE7),
          description:
              'Yemek keşfinde sana uygun seçenekler gösterilsin diye '
              'beslenme tarzını seç.',
          tokens: tokens,
          chips: [
            _Chip(
              label: 'Vegan',
              icon: Icons.spa_outlined,
              selected: profile.vegan,
              onTap: () => onToggle(_BoolField.vegan),
            ),
            _Chip(
              label: 'Vejetaryen',
              icon: Icons.local_florist_outlined,
              selected: profile.vegetarian,
              onTap: () => onToggle(_BoolField.vegetarian),
            ),
            _Chip(
              label: 'Helal',
              icon: Icons.verified_outlined,
              selected: profile.halal,
              onTap: () => onToggle(_BoolField.halal),
            ),
          ],
        ),
        SizedBox(height: tokens.space16),
        _Section(
          title: 'Alerjiler ve Hassasiyetler',
          icon: Icons.warning_amber_outlined,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          description:
              'Menülerde içerik uyarıları görmek için hassasiyetlerini belirt.',
          tokens: tokens,
          chips: [
            _Chip(
              label: 'Glutensiz',
              icon: Icons.grain_outlined,
              selected: profile.glutenFree,
              onTap: () => onToggle(_BoolField.glutenFree),
            ),
            _Chip(
              label: 'Laktozsuz',
              icon: Icons.no_drinks_outlined,
              selected: profile.lactoseFree,
              onTap: () => onToggle(_BoolField.lactoseFree),
            ),
          ],
        ),
        if (error != null) ...[
          SizedBox(height: tokens.space16),
          _ErrorBanner(message: error!),
        ],
        SizedBox(height: tokens.space24),
        _SaveBtn(saving: saving, onSave: onSave, tokens: tokens),
        SizedBox(height: tokens.space16),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({required this.tokens});
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diyet Profilin', style: context.sectionTitleStyle),
                SizedBox(height: tokens.space4),
                Text(
                  'Tercihlerini kaydet, sana özel menü ve işletme '
                  'önerileri görelim.',
                  style: context.captionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.description,
    required this.tokens,
    required this.chips,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String description;
  final AppTokens tokens;
  final List<_Chip> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(tokens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space16,
              tokens.space16,
              tokens.space16,
              tokens.space16,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: tokens.space12),
                Text(title, style: context.sectionTitleStyle),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: EdgeInsets.all(tokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: context.captionStyle),
                SizedBox(height: tokens.space12),
                Wrap(
                  spacing: tokens.space8,
                  runSpacing: tokens.space8,
                  children: chips,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minHeight: 44),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderStrong,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.onPrimary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    selected ? AppColors.onPrimary : AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({
    required this.saving,
    required this.onSave,
    required this.tokens,
  });

  final bool saving;
  final VoidCallback onSave;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Kaydet'),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.25),
        ),
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
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          const Text(
            'Diyet profili yüklenemedi.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

// ── Internal enum ─────────────────────────────────────────────────────────────

enum _BoolField { vegan, vegetarian, glutenFree, lactoseFree, halal }
