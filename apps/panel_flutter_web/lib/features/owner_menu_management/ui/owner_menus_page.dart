import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/navigation/public_menu_url.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/web/web_utils.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../domain/models/owner_claim.dart';
import '../../owner_businesses/domain/owner_business_models.dart';
import '../../owner_businesses/domain/owner_business_providers.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../../owner_claims/my_claims_controller.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import 'owner_menu_editor_page.dart' deferred as owner_menu_editor_page;
import 'owner_menu_error_mapper.dart';
import 'widgets/menu_list_tile.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import '../../../data/repositories/business_amenities_repository.dart';
import '../../../data/repositories/business_meal_card_providers_repository.dart';
import '../../business/domain/business_amenities_provider.dart';
import '../../business/domain/business_amenity.dart';
import '../../business/domain/business_meal_card_providers_provider.dart';
import '../../business/domain/meal_card_provider_option.dart';
import '../../owner_onboarding/domain/owner_onboarding_providers.dart';
import '../../../shared/ui/components/deferred_page_loader.dart';
import '../../../shared/ui/components/panel_action_button.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';

class OwnerMenusPage extends ConsumerStatefulWidget {
  const OwnerMenusPage({super.key});

  @override
  ConsumerState<OwnerMenusPage> createState() => _OwnerMenusPageState();
}

class _OwnerMenusPageState extends ConsumerState<OwnerMenusPage> {
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/isletme-giris?redirect=$redirect');
      });
      return const Center(child: CircularProgressIndicator());
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
    final ownerBusinesses = ref.watch(ownerBusinessesProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <OwnerBusiness>[],
    );
    final selectedBusinessIdState =
        ref.watch(selectedOwnerBusinessIdProvider) ?? '';
    var selectedBusinessId = selectedBusinessIdState;
    if (approved.isNotEmpty &&
        (selectedBusinessId.isEmpty ||
            !approved.any((c) => c.claim.businessId == selectedBusinessId))) {
      final preferred =
          queryBusinessId != null &&
              approved.any((c) => c.claim.businessId == queryBusinessId)
          ? queryBusinessId
          : approved.first.claim.businessId;
      selectedBusinessId = preferred;
      if (selectedBusinessIdState != preferred) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedOwnerBusinessIdProvider.notifier).state = preferred;
        });
      }
    }

    if (selectedBusinessId.isNotEmpty) {
      final canManageAsync = ref.watch(
        canManageBusinessProvider(selectedBusinessId),
      );
      final canManage = canManageAsync.when<bool?>(
        loading: () => null,
        error: (_, _) => false,
        data: (value) => value,
      );
      if (canManage == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!canManage) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: OwnerPanelFeedback.error(
            title: l10n.ownerNoBusinessPermissionTitle,
            description: l10n.ownerNoBusinessPermissionDescription,
            onRetry: () => context.go('/owner/businesses'),
            retryLabel: l10n.ownerGoBusinessesAction,
          ),
        );
      }
    }

    final selectedBusiness = _findOwnerBusiness(
      ownerBusinesses,
      selectedBusinessId,
    );

    final menusAsync = selectedBusinessId.isEmpty
        ? const AsyncData(<OwnerMenu>[])
        : ref.watch(ownerMenusProvider(selectedBusinessId));

    if (!onboardingBypass && selectedBusinessId.isNotEmpty) {
      final progressAsync = ref.watch(
        ownerOnboardingProgressProvider(selectedBusinessId),
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
            '/owner/onboarding?businessId=$selectedBusinessId&redirect=$redirect',
          );
        });
      });
    }

    return Stack(
      children: [
        RefreshIndicator(
        onRefresh: () async {
          if (selectedBusinessId.isEmpty) return;
          await ref.read(ownerMenusProvider(selectedBusinessId).notifier).refresh();
        },
        child: CustomScrollView(
          cacheExtent: 1200,
          slivers: [
            SliverToBoxAdapter(
              child: PanelPageHeader(
                eyebrow: 'Owner',
                title: Text(l10n.ownerMenuManagementTitle),
                description: 'Menülerinizi yönetin, yayınlayın ve QR kodlarınızı paylaşın.',
                compactActions: [
                  PanelActionButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: l10n.ownerShellTrashLabel,
                    variant: PanelActionButtonVariant.ghost,
                    onPressed: selectedBusinessId.isEmpty
                        ? null
                        : () => context.go('/owner/trash?businessId=$selectedBusinessId'),
                  ),
                  PanelActionButton(
                    icon: Icons.refresh,
                    tooltip: 'Yenile',
                    variant: PanelActionButtonVariant.ghost,
                    onPressed: selectedBusinessId.isEmpty
                        ? null
                        : () => ref
                              .read(ownerMenusProvider(selectedBusinessId).notifier)
                              .refresh(),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  claimsAsync.when(
                    loading: () => const OwnerPanelFeedback.loading(),
                    error: (e, _) => _ErrorBox(
                      message: AppErrorMapper.message(e),
                      onRetry: () => ref.read(myClaimsProvider.notifier).refresh(),
                    ),
                    data: (items) {
                      final approvedItems = items
                          .where((c) => c.claim.status == 'approved')
                          .toList();
                      if (approvedItems.isEmpty) {
                        return _EmptyBox(
                          message: l10n.ownerApprovedBusinessNotFound,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedBusinessId.isNotEmpty) ...[
                    _DigitalMenuStudioCard(
                      onOpenQrStudio: () => _openQrStudio(selectedBusinessId),
                      onOpenPublicMenu: () => _openPublicMenu(
                        selectedBusinessId,
                        publicSlug: selectedBusiness?.publicSlug,
                        slug: selectedBusiness?.slug,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OwnerProfileScoreCard(
                      key: const ValueKey('profile_score_'),
                      businessId: selectedBusinessId,
                    ),
                    const SizedBox(height: 12),
                    _OwnerAmenitiesSection(
                      key: ValueKey(selectedBusinessId),
                      businessId: selectedBusinessId,
                    ),
                    const SizedBox(height: 12),
                    _OwnerMealCardProvidersSection(
                      key: ValueKey('meal_cards_$selectedBusinessId'),
                      businessId: selectedBusinessId,
                    ),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
            ),
            ...menusAsync.when(
              loading: () => [
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: OwnerPanelFeedback.loading(),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorBox(
                      message: AppErrorMapper.message(e),
                      onRetry: () => ref
                          .read(ownerMenusProvider(selectedBusinessId).notifier)
                          .refresh(),
                    ),
                  ),
                ),
              ],
              data: (menus) {
                if (menus.isEmpty) {
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyBox(message: l10n.ownerMenuNotFound),
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _QuickQrCard(
                            onOpenQrStudio: () => _openQrStudio(selectedBusinessId),
                            onOpenPublicMenu: () => _openPublicMenu(
                              selectedBusinessId,
                              publicSlug: selectedBusiness?.publicSlug,
                              slug: selectedBusiness?.slug,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final menu = menus[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == menus.length - 1 ? 0 : 8,
                          ),
                          child: MenuListTile(
                            menu: menu,
                            onEdit: () async {
                              final updated = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => DeferredPageLoader(
                                        loadLibrary:
                                            owner_menu_editor_page.loadLibrary,
                                        fullscreen: true,
                                        builder: (_) =>
                                            owner_menu_editor_page.OwnerMenuEditorPage(
                                              menu: menu,
                                            ),
                                      ),
                                    ),
                                  );
                              if (updated == true && mounted) {
                                ref
                                    .read(
                                      ownerMenusProvider(
                                        selectedBusinessId,
                                      ).notifier,
                                    )
                                    .refresh();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.ownerMenuUpdated),
                                  ),
                                );
                              }
                            },
                            onArchive: () => _archiveMenu(menu),
                            onPublish: menu.status == 'published'
                                ? null
                                : () => _publishMenu(menu),
                          ),
                        );
                      }, childCount: menus.length),
                    ),
                  ),
                ];
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: selectedBusinessId.isEmpty ? null : _openCreateMenuSheet,
            icon: const Icon(Icons.add),
            label: Text(l10n.ownerCreateMenuAction),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateMenuSheet() async {
    final l10n = context.l10n;
    final businessId = _currentBusinessId();
    if (businessId.isEmpty) return;
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
              Text(
                l10n.ownerCreateMenuTitle,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: l10n.title),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kindCtrl,
                decoration: InputDecoration(
                  labelText: l10n.ownerMenuTypeOptional,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.ownerCreateAction),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (res != true) return;
    try {
      final controller = ref.read(ownerMenusProvider(businessId).notifier);
      await controller.createMenu(
        title: titleCtrl.text.trim(),
        kind: kindCtrl.text.trim(),
      );
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(l10n.ownerMenuCreated)),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      titleCtrl.dispose();
      kindCtrl.dispose();
    }
  }

  Future<void> _archiveMenu(OwnerMenu menu) async {
    final businessId = _currentBusinessId();
    if (businessId.isEmpty) return;
    final ok = await _confirm(context, context.l10n.ownerArchiveMenuConfirm);
    if (!ok) return;
    try {
      await ref.read(ownerMenusProvider(businessId).notifier).archiveMenu(
            menuId: menu.id,
          );
      invalidateMenu(ref, businessId: businessId, menuId: menu.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerMenuArchived)),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openPublicMenu(
    String businessId, {
    String? publicSlug,
    String? slug,
  }) async {
    final uri = Uri.parse(
      buildPublicMenuUrl(
        businessId: businessId,
        businessPublicSlug: publicSlug,
        businessSlug: slug,
      ),
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerPublicMenuOpenedInNewTab)),
      );
    }
  }

  Future<void> _openQrStudio(String businessId) async {
    final session = ref.read(supabaseProvider).auth.currentSession;
    if (session == null) {
      final uri = Uri.parse(buildQrLoginUrl(businessId: businessId));
      await _openExternalLink(
        uri,
        context.l10n.ownerDigitalMenuOpenedInNewTab,
      );
      return;
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      final uri = Uri.parse(buildQrMenuUrl(businessId: businessId));
      await _openExternalLink(
        uri,
        context.l10n.ownerDigitalMenuOpenedInNewTab,
      );
      return;
    }

    submitPostRedirect(buildPanelSessionHandoffUrl(), {
      'access_token': session.accessToken,
      'refresh_token': refreshToken,
      'business_id': businessId,
      'lang': 'tr',
      'theme': 'bold',
    }, target: '_blank');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerDigitalMenuOpenedInNewTab)),
      );
    }
  }

  Future<void> _publishMenu(OwnerMenu menu) async {
    final businessId = _currentBusinessId();
    if (businessId.isEmpty) return;
    final ok = await _confirm(context, context.l10n.ownerPublishMenuConfirm);
    if (!ok) return;
    try {
      await ref.read(ownerMenusProvider(businessId).notifier).publishMenu(
            menuId: menu.id,
          );
      invalidateMenu(ref, businessId: businessId, menuId: menu.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerMenuPublished)),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    final msg = ownerMenuErrorMessage(
      context.l10n,
      error,
      fallback: AppErrorMapper.message(error),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _currentBusinessId() {
    return ref.read(selectedOwnerBusinessIdProvider) ?? '';
  }

  Future<void> _openExternalLink(Uri uri, String successMessage) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }
}

OwnerBusiness? _findOwnerBusiness(
  List<OwnerBusiness> businesses,
  String businessId,
) {
  for (final business in businesses) {
    if (business.businessId == businessId) return business;
  }
  return null;
}

class _DigitalMenuStudioCard extends StatelessWidget {
  const _DigitalMenuStudioCard({
    required this.onOpenQrStudio,
    required this.onOpenPublicMenu,
  });

  final VoidCallback onOpenQrStudio;
  final VoidCallback onOpenPublicMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  color: AppColors.primary,
                ),
              ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.ownerDigitalMenuStudioTitle,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        context.l10n.ownerDigitalMenuStudioSubtitle,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tooltip(
                  message: context.l10n.ownerDigitalMenuQrOpenStudioTooltip,
                  child: OutlinedButton.icon(
                    onPressed: onOpenQrStudio,
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: Text(
                      context.l10n.ownerDigitalMenuQrOpenStudioAction,
                    ),
                  ),
                ),
                Tooltip(
                  message: context.l10n.ownerDigitalMenuOpenPublicMenuTooltip,
                  child: FilledButton.icon(
                    onPressed: onOpenPublicMenu,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      context.l10n.ownerDigitalMenuOpenPublicMenuAction,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _QuickQrCard extends StatelessWidget {
  const _QuickQrCard({
    required this.onOpenQrStudio,
    required this.onOpenPublicMenu,
  });

  final VoidCallback onOpenQrStudio;
  final VoidCallback onOpenPublicMenu;

  @override
  Widget build(BuildContext context) {
    return _DigitalMenuStudioCard(
      onOpenQrStudio: onOpenQrStudio,
      onOpenPublicMenu: onOpenPublicMenu,
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
  ProviderSubscription<AsyncValue<List<BusinessAmenity>>>? _amenitiesSub;

  @override
  void initState() {
    super.initState();
    _amenitiesSub = ref.listenManual<AsyncValue<List<BusinessAmenity>>>(
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
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _amenitiesSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAmenitiesAsync = ref.watch(allAmenitiesProvider);
    ref.watch(businessAmenitiesProvider(widget.businessId));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ownerAmenitiesTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                        child: Text(
                          _saving ? context.l10n.saving : context.l10n.save,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerAmenitiesUpdated)),
      );
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OwnerMealCardProvidersSection extends ConsumerStatefulWidget {
  const _OwnerMealCardProvidersSection({
    super.key,
    required this.businessId,
  });

  final String businessId;

  @override
  ConsumerState<_OwnerMealCardProvidersSection> createState() =>
      _OwnerMealCardProvidersSectionState();
}

class _OwnerMealCardProvidersSectionState
    extends ConsumerState<_OwnerMealCardProvidersSection> {
  final Set<String> _selectedKeys = {};
  Object? _error;
  bool _saving = false;
  ProviderSubscription<AsyncValue<List<MealCardProviderOption>>>?
  _mealCardsSub;

  @override
  void initState() {
    super.initState();
    _mealCardsSub = ref.listenManual<AsyncValue<List<MealCardProviderOption>>>(
      businessMealCardProvidersProvider(widget.businessId),
      (prev, next) {
        next.whenData((items) {
          if (!mounted) return;
          setState(() {
            _selectedKeys
              ..clear()
              ..addAll(items.map((item) => item.key));
          });
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _mealCardsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMealCardsAsync = ref.watch(allMealCardProvidersProvider);
    ref.watch(businessMealCardProvidersProvider(widget.businessId));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geçerli Yemek Kartları',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
            const SizedBox(height: 6),
            const Text(
              'Kullanıcıların işletmenizde kullanabileceği yemek kartlarını seçin.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                AppErrorMapper.message(_error),
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 6),
            allMealCardsAsync.when(
              loading: () => const _OwnerAmenitiesSkeleton(),
              error: (error, _) => Text(
                AppErrorMapper.message(error),
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    for (final item in items)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: _selectedKeys.contains(item.key),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedKeys.add(item.key);
                            } else {
                              _selectedKeys.remove(item.key);
                            }
                          });
                        },
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? context.l10n.saving : context.l10n.save,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
          .read(businessMealCardProvidersRepositoryProvider)
          .updateBusinessProviders(
            businessId: widget.businessId,
            providerKeys: _selectedKeys.toList(growable: false),
          );
      ref.invalidate(businessMealCardProvidersProvider(widget.businessId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yemek kartları güncellendi.')),
      );
    } catch (error) {
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, color: AppColors.border),
          const SizedBox(height: 6),
          Container(height: 10, width: 160, color: AppColors.border),
        ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
                Text(
                  context.l10n.ownerProfileCompletionTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  context.l10n.ownerProfileCompletionPercent(pct),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: isComplete
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.ownerSponsoredRequestsSoon,
                            ),
                          ),
                        )
                      : null,
                  child: Text(context.l10n.ownerSponsoredVisibilityAction),
                ),
              ],
            );
          },
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OwnerPanelFeedback.empty(
        icon: Icons.inbox_outlined,
        title: context.l10n.ownerMenuManagementTitle,
        description: message,
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
      child: OwnerPanelFeedback.error(
        title: context.l10n.ownerMenuManagementTitle,
        description: message,
        onRetry: onRetry,
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.ownerAreYouSure),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.ownerConfirm),
        ),
      ],
    ),
  );
  return res ?? false;
}
