import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/security/app_role_providers.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../domain/models/owner_claim.dart';
import '../../owner_claims/my_claims_controller.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import 'owner_menu_editor_page.dart';
import 'owner_menu_error_mapper.dart';
import 'widgets/menu_list_tile.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import '../../../data/repositories/business_amenities_repository.dart';
import '../../business/domain/business_amenities_provider.dart';
import '../../business/domain/business_amenity.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../../../shared/ui/components/app_scaffold.dart';

class OwnerMenusPage extends ConsumerStatefulWidget {
  const OwnerMenusPage({super.key});

  @override
  ConsumerState<OwnerMenusPage> createState() => _OwnerMenusPageState();
}

class _OwnerMenusPageState extends ConsumerState<OwnerMenusPage> {
  String _selectedBusinessId = '';
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login?redirect=$redirect');
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final claimsAsync = ref.watch(myClaimsProvider);
    final queryBusinessId = GoRouterState.of(
      context,
    ).uri.queryParameters['businessId'];
    final onboardingBypass =
        GoRouterState.of(context).uri.queryParameters['onboarding'] == '1';
    final approved = claimsAsync.maybeWhen(
      data: (items) =>
          items.where((c) => c.claim.status == 'approved').toList(),
      orElse: () => const <OwnerClaimItem>[],
    );
    if (_selectedBusinessId.isEmpty && approved.isNotEmpty) {
      final preferred =
          queryBusinessId != null &&
              approved.any((c) => c.claim.businessId == queryBusinessId)
          ? queryBusinessId
          : approved.first.claim.businessId;
      _selectedBusinessId = preferred;
    }

    if (_selectedBusinessId.isNotEmpty) {
      final canManageAsync = ref.watch(
        canManageBusinessProvider(_selectedBusinessId),
      );
      final canManage = canManageAsync.when<bool?>(
        loading: () => null,
        error: (_, _) => false,
        data: (value) => value,
      );
      if (canManage == null) {
        return const AppScaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (!canManage) {
        return const AppScaffold(
          body: Center(child: Text('Bu işletme için yetkiniz yok.')),
        );
      }
    }

    final menusAsync = _selectedBusinessId.isEmpty
        ? const AsyncData(<OwnerMenu>[])
        : ref.watch(ownerMenusProvider(_selectedBusinessId));

    if (!onboardingBypass && _selectedBusinessId.isNotEmpty) {
      final progressAsync = ref.watch(
        ownerOnboardingProgressProvider(_selectedBusinessId),
      );
      progressAsync.whenData((progress) {
        if (_redirecting || progress.stepCompleted >= 5) return;
        _redirecting = true;
        final redirect = Uri.encodeComponent(
          GoRouterState.of(context).uri.toString(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(
            '/owner/onboarding?businessId=$_selectedBusinessId&redirect=$redirect',
          );
        });
      });
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Menü yönetimi'),
        actions: [
          IconButton(
            onPressed: _selectedBusinessId.isEmpty
                ? null
                : () => ref
                      .read(ownerMenusProvider(_selectedBusinessId).notifier)
                      .refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedBusinessId.isEmpty) return;
          await ref
              .read(ownerMenusProvider(_selectedBusinessId).notifier)
              .refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            claimsAsync.when(
              loading: () => const _OwnerMenusSkeleton(),
              error: (e, _) => _ErrorBox(
                message: AppErrorMapper.message(e),
                onRetry: () => ref.read(myClaimsProvider.notifier).refresh(),
              ),
              data: (items) {
                final approvedItems = items
                    .where((c) => c.claim.status == 'approved')
                    .toList();
                if (approvedItems.isEmpty) {
                  return const _EmptyBox(message: 'Onaylı işletme bulunamadı.');
                }
                return _BusinessSelector(
                  items: approvedItems,
                  selectedId: _selectedBusinessId,
                  onChanged: (id) {
                    setState(() {
                      _selectedBusinessId = id;
                      _redirecting = false;
                    });
                    ref.read(ownerMenusProvider(id).notifier).refresh();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            if (_selectedBusinessId.isNotEmpty) ...[
              _OwnerProfileScoreCard(
                key: ValueKey('profile_score_'),
                businessId: _selectedBusinessId,
              ),
              const SizedBox(height: 12),
              _OwnerAmenitiesSection(
                key: ValueKey(_selectedBusinessId),
                businessId: _selectedBusinessId,
              ),
              const SizedBox(height: 12),
            ],
            menusAsync.when(
              loading: () => const _OwnerMenusSkeleton(),
              error: (e, _) => _ErrorBox(
                message: AppErrorMapper.message(e),
                onRetry: () => ref
                    .read(ownerMenusProvider(_selectedBusinessId).notifier)
                    .refresh(),
              ),
              data: (menus) {
                if (menus.isEmpty) {
                  return const _EmptyBox(message: 'Henüz menü yok.');
                }
                return Column(
                  children: [
                    _QuickQrCard(onOpenWizard: () => _openQrWizard(menus)),
                    const SizedBox(height: 10),
                    for (final menu in menus) ...[
                      MenuListTile(
                        menu: menu,
                        onEdit: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OwnerMenuEditorPage(menu: menu),
                                ),
                              );
                          if (updated == true && mounted) {
                            ref
                                .read(
                                  ownerMenusProvider(
                                    _selectedBusinessId,
                                  ).notifier,
                                )
                                .refresh();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Menü güncellendi')),
                            );
                          }
                        },
                        onArchive: () => _archiveMenu(menu),
                        onPublish: menu.status == 'published'
                            ? null
                            : () => _publishMenu(menu),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedBusinessId.isEmpty ? null : _openCreateMenuSheet,
        icon: const Icon(Icons.add),
        label: const Text('Yeni menü oluştur'),
      ),
    );
  }

  Future<void> _openCreateMenuSheet() async {
    final titleCtrl = TextEditingController();
    final kindCtrl = TextEditingController();
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yeni menü',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Başlık'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kindCtrl,
                decoration: const InputDecoration(labelText: 'Tür (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Oluştur'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (res != true) return;
    try {
      final controller = ref.read(
        ownerMenusProvider(_selectedBusinessId).notifier,
      );
      await controller.createMenu(
        title: titleCtrl.text.trim(),
        kind: kindCtrl.text.trim(),
      );
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menü oluşturuldu')));
      }
    } catch (e) {
      _showError(e);
    } finally {
      titleCtrl.dispose();
      kindCtrl.dispose();
    }
  }

  Future<void> _archiveMenu(OwnerMenu menu) async {
    final ok = await _confirm(context, 'Menüyü arşivlemek istiyor musun?');
    if (!ok) return;
    try {
      await ref
          .read(ownerMenusProvider(_selectedBusinessId).notifier)
          .archiveMenu(menuId: menu.id);
      invalidateMenu(ref, businessId: _selectedBusinessId, menuId: menu.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menü arşivlendi')));
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openQrWizard(List<OwnerMenu> menus) async {
    final published = menus.where((m) => m.status == 'published').toList();
    final candidates = published.isNotEmpty ? published : menus;
    final selected = await showModalBottomSheet<OwnerMenu>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var selectedId = candidates.first.id;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR menü Oluştur / Yazdir',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Menü seç, tek adımda QR panelini aç.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    items: [
                      for (final menu in candidates)
                        DropdownMenuItem(
                          value: menu.id,
                          child: Text(
                            menu.status == 'published'
                                ? '${menu.title} (Yayında)'
                                : menu.title,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final picked = candidates.firstWhere(
                          (m) => m.id == selectedId,
                          orElse: () => candidates.first,
                        );
                        Navigator.of(ctx).pop(picked);
                      },
                      icon: const Icon(Icons.qr_code_2_outlined),
                      label: const Text('QR panelini aç'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            OwnerMenuEditorPage(menu: selected, openShareOnStart: true),
      ),
    );
    if (updated == true && mounted) {
      ref.read(ownerMenusProvider(_selectedBusinessId).notifier).refresh();
    }
  }

  Future<void> _publishMenu(OwnerMenu menu) async {
    final ok = await _confirm(context, 'Menüyü yayınlamak istiyor musun?');
    if (!ok) return;
    try {
      await ref
          .read(ownerMenusProvider(_selectedBusinessId).notifier)
          .publishMenu(menuId: menu.id);
      invalidateMenu(ref, businessId: _selectedBusinessId, menuId: menu.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menü yayınlandı')));
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    final msg = ownerMenuErrorMessage(
      error,
      fallback: AppErrorMapper.message(error),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _QuickQrCard extends StatelessWidget {
  const _QuickQrCard({required this.onOpenWizard});

  final VoidCallback onOpenWizard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_2_outlined,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR menü',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Oluştur, indir ve yazdir.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onOpenWizard,
              child: const Text('Başlat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAmenitiesSection extends ConsumerStatefulWidget {
  const _OwnerAmenitiesSection({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<_OwnerAmenitiesSection> createState() =>
      _OwnerAmenitiesSectionState();
}

class _OwnerAmenitiesSectionState
    extends ConsumerState<_OwnerAmenitiesSection> {
  final Set<String> _selectedKeys = {};
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<BusinessAmenity>>>(
      businessAmenitiesProvider(widget.businessId),
      (prev, next) {
        next.whenData((items) {
          if (!mounted) return;
          setState(() {
            _selectedKeys
              ..clear()
              ..addAll(items.map((e) => e.key));
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAmenitiesAsync = ref.watch(allAmenitiesProvider);
    ref.watch(businessAmenitiesProvider(widget.businessId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Özellikler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (_error != null)
              Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
            const SizedBox(height: 6),
            allAmenitiesAsync.when(
              loading: () => const _OwnerAmenitiesSkeleton(),
              error: (e, _) => Text(
                AppErrorMapper.message(e),
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    for (final a in items)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: _selectedKeys.contains(a.key),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedKeys.add(a.key);
                            } else {
                              _selectedKeys.remove(a.key);
                            }
                          });
                        },
                        title: Text(
                          a.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(businessAmenitiesRepositoryProvider)
          .updateBusinessAmenities(
            businessId: widget.businessId,
            amenityKeys: _selectedKeys.toList(),
          );
      ref.invalidate(businessAmenitiesProvider(widget.businessId));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Özellikler güncellendi')));
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OwnerAmenitiesSkeleton extends StatelessWidget {
  const _OwnerAmenitiesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _OwnerProfileScoreCard extends ConsumerWidget {
  const _OwnerProfileScoreCard({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(ownerBusinessProfileScoreProvider(businessId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: scoreAsync.when(
          loading: () => const _OwnerProfileScoreSkeleton(),
          error: (e, _) => Text(
            AppErrorMapper.message(e),
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (score) {
            final pct = (score.score).clamp(0, 100);
            final progress = pct / 100.0;
            final isComplete = pct >= 100;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Tamamlama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  '%$pct tamamlandı',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: isComplete
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sponsor talepleri yakinda.'),
                          ),
                        )
                      : null,
                  child: const Text('Sponsorlu görünürlük al'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OwnerProfileScoreSkeleton extends StatelessWidget {
  const _OwnerProfileScoreSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 12, width: 160, color: AppColors.card),
        const SizedBox(height: 10),
        Container(height: 8, width: double.infinity, color: AppColors.card),
        const SizedBox(height: 8),
        Container(height: 12, width: 120, color: AppColors.card),
        const SizedBox(height: 10),
        Container(height: 36, width: 200, color: AppColors.card),
      ],
    );
  }
}

class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  final List<OwnerClaimItem> items;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('İşletme:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedId.isEmpty ? null : selectedId,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item.claim.businessId,
                  child: Text(item.businessName),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _OwnerMenusSkeleton extends StatelessWidget {
  const _OwnerMenusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 6),
            Container(height: 10, width: 160, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Emin misin?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Onayla'),
        ),
      ],
    ),
  );
  return res ?? false;
}
