import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/content/content_moderation.dart';
import '../../../core/errors/app_error_codes.dart';
import '../../../core/media/app_network_image.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_hero_header.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../shared/ui/widgets/report_bottom_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../../profile/domain/profile_progress_provider.dart';
import '../data/food_catalog_repository.dart';
import '../domain/food_catalog_models.dart';
import '../domain/food_catalog_search_controller.dart';
import '../data/offline_verify_queue.dart';
import '../data/menu_repository.dart';
import '../data/wp_upload.dart';
import '../ui/menu_ocr_flow.dart';
import '../domain/menu_controllers.dart';
import '../domain/menu_models.dart';
import '../domain/menu_item_context_controller.dart';
import '../domain/menu_providers.dart';
import '../../price_alerts/ui/price_alert_sheet.dart';
import '../../../core/network/supabase_provider.dart';

class _MenuItemVariant {
  const _MenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.label,
    required this.priceCents,
    required this.currency,
    required this.isDefault,
    required this.sortOrder,
  });

  final String id;
  final String menuItemId;
  final String label;
  final int priceCents;
  final String currency;
  final bool isDefault;
  final int sortOrder;

  factory _MenuItemVariant.fromMap(Map<String, dynamic> map) {
    return _MenuItemVariant(
      id: (map['id'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      priceCents: ((map['price_cents'] as num?) ?? 0).toInt(),
      currency: (map['currency'] ?? 'TRY').toString(),
      isDefault: map['is_default'] == true,
      sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
    );
  }
}

final _menuItemVariantsProvider =
    FutureProvider.family<List<_MenuItemVariant>, String>((
      ref,
      menuItemId,
    ) async {
      final id = menuItemId.trim();
      if (id.isEmpty) return const <_MenuItemVariant>[];
      final client = ref.watch(supabaseProvider);
      final res = await client
          .from('menu_item_variants')
          .select(
            'id,menu_item_id,label,price_cents,currency,is_default,is_available,sort_order',
          )
          .eq('menu_item_id', id)
          .eq('is_available', true)
          .order('sort_order', ascending: true);
      final variants = (res as List)
          .whereType<Map>()
          .map((row) => _MenuItemVariant.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
      variants.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      return variants;
    });

class MenuItemPage extends ConsumerWidget {
  const MenuItemPage({
    super.key,
    required this.businessId,
    required this.menuId,
    required this.menuItemId,
  });

  final String businessId;
  final String menuId;
  final String menuItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    if (menuId.isEmpty) {
      final contextAsync = ref.watch(menuItemContextProvider(menuItemId));
      return AppScaffold(
        appBar: AppAppBar(title: Text(t.menuItem)),
        body: contextAsync.when(
          loading: () => const _MenuItemSkeleton(),
          error: (e, _) => _MenuItemError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref
                .read(menuItemContextProvider(menuItemId).notifier)
                .refresh(force: true),
          ),
          data: (ctx) {
            if (!ctx.ok || ctx.menuId.isEmpty || ctx.businessId.isEmpty) {
              return const _MenuItemNotFound();
            }
            return _MenuItemBody(
              businessId: ctx.businessId,
              menuId: ctx.menuId,
              menuItemId: menuItemId,
            );
          },
        ),
      );
    }
    return _MenuItemBody(
      businessId: businessId,
      menuId: menuId,
      menuItemId: menuItemId,
    );
  }
}

class _MenuItemBody extends ConsumerStatefulWidget {
  const _MenuItemBody({
    required this.businessId,
    required this.menuId,
    required this.menuItemId,
  });

  final String businessId;
  final String menuId;
  final String menuItemId;

  @override
  ConsumerState<_MenuItemBody> createState() => _MenuItemBodyState();
}

class _MenuItemBodyState extends ConsumerState<_MenuItemBody> {
  bool _shouldRefreshMenu = false;
  final Map<String, _CartEntry> _cart = {};
  bool _loggedMenuView = false;
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackMenuItemView();
    });
  }

  Future<void> _trackMenuItemView() async {
    if (_loggedMenuView) return;
    _loggedMenuView = true;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: 'menu_view',
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_item_page',
          clientId: clientId,
          meta: {'menu_item_id': widget.menuItemId},
        );
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.menuOpen,
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_item_page',
          clientId: clientId,
          meta: {'menu_item_id': widget.menuItemId},
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final itemsAsync = ref.watch(menuItemsProvider(widget.menuId));
    final photosAsync = ref.watch(menuItemPhotosProvider(widget.menuItemId));
    final priceStatusAsync = ref.watch(
      menuItemPriceStatusProvider(widget.menuItemId),
    );
    final valueScoreAsync = ref.watch(
      menuItemValueScoreProvider(widget.menuItemId),
    );
    final priceHistoryAsync = ref.watch(
      menuItemPriceHistoryProvider(widget.menuItemId),
    );
    final variantsAsync = ref.watch(
      _menuItemVariantsProvider(widget.menuItemId),
    );
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_shouldRefreshMenu);
      },
      child: AppScaffold(
        appBar: AppAppBar(title: Text(t.menuItem)),
        body: itemsAsync.when(
          loading: () => const _MenuItemSkeleton(),
          error: (e, _) => _MenuItemError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref.invalidate(menuItemsProvider(widget.menuId)),
          ),
          data: (items) {
            final item = items.firstWhere(
              (i) => i.id == widget.menuItemId,
              orElse: () => MenuItem(id: '', name: ''),
            );

            if (item.id.isEmpty) {
              return const _MenuItemNotFound();
            }
            final variants =
                variantsAsync.asData?.value ?? const <_MenuItemVariant>[];
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
            final displayPrice = selectedVariant == null
                ? item.price
                : selectedVariant.priceCents / 100;
            final displayCurrency = selectedVariant?.currency ?? 'TRY';

            return _maxWidth(
              context,
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppHeroHeader(
                    title: item.name,
                    subtitle: _formatPrice(
                      context,
                      displayPrice,
                      currencyCode: displayCurrency,
                    ),
                    icon: Icons.restaurant_menu,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item.description ?? '').trim().isNotEmpty) ...[
                          Text(
                            item.description!,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Wrap(
                          spacing: 6,
                          children: [
                            if (item.isVegan) _DietChip(label: t.vegan),
                            if (item.isGlutenFree)
                              _DietChip(label: t.glutenFree),
                            if (item.catalogItemId != null)
                              _DietChip(label: t.cataloged),
                          ],
                        ),
                        if (variants.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final variant in variants)
                                ChoiceChip(
                                  label: Text(variant.label),
                                  selected:
                                      (selectedVariant?.id ?? '') == variant.id,
                                  onSelected: (_) => setState(
                                    () => _selectedVariantId = variant.id,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PriceStatusCard(
                    item: item,
                    statusAsync: priceStatusAsync,
                    onRetry: () => _refreshPriceData(ref, widget.menuItemId),
                    onUpdate: () async {
                      if (!isLoggedIn) {
                        _redirectToLogin(context);
                        return;
                      }
                      final submission = await _openPriceSuggestionSheet(
                        context,
                        widget.menuItemId,
                        widget.businessId,
                        widget.menuId,
                      );
                      if (submission != null && submission.ok) {
                        await _refreshPriceData(ref, widget.menuItemId);
                        if (mounted) {
                          setState(() => _shouldRefreshMenu = true);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                submission.queued
                                    ? t.weakConnectionQueueNotice
                                    : submission.autoApproved
                                    ? t.menuItemAutoApprovedMessage
                                    : (submission.pendingCount > 1
                                          ? t.menuItemPendingCountMessage(
                                              submission.pendingCount,
                                            )
                                          : t.menuItemPendingSingleMessage),
                              ),
                            ),
                          );
                          if (submission.onsiteVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t.menuItemOnsiteVerifiedPrioritizedMessage,
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    onVote: (vote) async {
                      if (!isLoggedIn) {
                        _redirectToLogin(context);
                        return;
                      }
                      try {
                        await ref
                            .read(
                              menuItemPriceStatusProvider(
                                widget.menuItemId,
                              ).notifier,
                            )
                            .votePrice(vote: vote);
                        if (context.mounted) {
                          _openPriceThanksSheet(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _ValueScoreCard(
                    valueScoreAsync: valueScoreAsync,
                    onExplain: (score) => _openValueScoreSheet(context, score),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.priceAlert,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.priceAlertSubtitle,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (!isLoggedIn) {
                                _redirectToLogin(context);
                                return;
                              }
                              await showPriceAlertSheet(
                                context: context,
                                initialQuery: item.name,
                              );
                            },
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            label: Text(t.setPriceAlert),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _addToCart(context, item),
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: Text(t.addToBill),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PriceHistorySection(
                    historyAsync: priceHistoryAsync,
                    selectedVariant: selectedVariant,
                    onRetry: () => _refreshPriceData(ref, widget.menuItemId),
                  ),
                  const SizedBox(height: 16),
                  _MenuItemPhotosSection(
                    menuItemId: widget.menuItemId,
                    photosAsync: photosAsync,
                    onRetry: () => ref.invalidate(
                      menuItemPhotosProvider(widget.menuItemId),
                    ),
                    onReport: (photo) =>
                        _openMenuPhotoReport(context, widget.businessId, photo),
                    onVote: (photoId, vote) async {
                      if (!isLoggedIn) {
                        _redirectToLogin(context);
                        return;
                      }
                      try {
                        await ref
                            .read(
                              menuItemPhotosProvider(
                                widget.menuItemId,
                              ).notifier,
                            )
                            .votePhoto(photoId: photoId, vote: vote);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(t.voteSaved)));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      }
                    },
                    onUpload: () async {
                      if (!isLoggedIn) {
                        _redirectToLogin(context);
                        return;
                      }
                      try {
                        final res = await ref
                            .read(
                              menuItemPhotosProvider(
                                widget.menuItemId,
                              ).notifier,
                            )
                            .uploadAndAddPhoto();
                        if (res == null) return;
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(t.photoAdded)));
                        }
                        final quality = await _checkMenuPhotoQuality(
                          res.urlThumb.isEmpty ? res.urlLarge : res.urlThumb,
                        );
                        if (quality != null &&
                            (quality.isDark || quality.isBlurry) &&
                            context.mounted) {
                          final warnings = [
                            if (quality.isDark) t.menuPhotoWarningDark,
                            if (quality.isBlurry) t.menuPhotoWarningBlurry,
                          ].join(' / ');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.photoQualityWarning(warnings)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _openSuggestionSheet(context, widget.businessId, item),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t.suggestEdit),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (!isLoggedIn) {
                        _redirectToLogin(context);
                        return;
                      }
                      final client = ref.read(supabaseProvider);
                      final repo = ref.read(menuRepositoryProvider);
                      await startReceiptOcrFlow(
                        context: context,
                        client: client,
                        repo: repo,
                        businessId: widget.businessId,
                        menuItems: items,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(t.verifyPriceWithReceipt),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, MenuItem item) async {
    setState(() {
      final current = _cart[item.id];
      if (current == null) {
        _cart[item.id] = _CartEntry(item: item, qty: 1);
      } else {
        _cart[item.id] = current.copyWith(qty: current.qty + 1);
      }
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CartSheet(
        businessId: widget.businessId,
        entries: _cart,
        onUpdate: (updated) {
          setState(() {
            _cart
              ..clear()
              ..addAll(updated);
          });
        },
      ),
    );
  }
}

class _CartEntry {
  const _CartEntry({required this.item, required this.qty});
  final MenuItem item;
  final int qty;

  _CartEntry copyWith({MenuItem? item, int? qty}) {
    return _CartEntry(item: item ?? this.item, qty: qty ?? this.qty);
  }
}

class _BillEstimate {
  const _BillEstimate({
    required this.ok,
    required this.hasRules,
    required this.subtotalCents,
    required this.coverCents,
    required this.serviceFeeCents,
    required this.serviceFeePct,
    required this.tipCents,
    required this.tipPct,
    required this.totalCents,
    required this.vatIncluded,
  });

  final bool ok;
  final bool hasRules;
  final int subtotalCents;
  final int coverCents;
  final int serviceFeeCents;
  final int serviceFeePct;
  final int tipCents;
  final int tipPct;
  final int totalCents;
  final bool vatIncluded;

  factory _BillEstimate.fromMap(Map<String, dynamic> map) {
    return _BillEstimate(
      ok: map['ok'] == true,
      hasRules: map['has_rules'] == true,
      subtotalCents: _asInt(map['subtotal_cents']),
      coverCents: _asInt(map['cover_cents']),
      serviceFeeCents: _asInt(map['service_fee_cents']),
      serviceFeePct: _asInt(map['service_fee_pct']),
      tipCents: _asInt(map['tip_cents']),
      tipPct: _asInt(map['tip_pct']),
      totalCents: _asInt(map['total_cents']),
      vatIncluded: map['vat_included'] != false,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet({
    required this.businessId,
    required this.entries,
    required this.onUpdate,
  });

  final String businessId;
  final Map<String, _CartEntry> entries;
  final ValueChanged<Map<String, _CartEntry>> onUpdate;

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  late Map<String, _CartEntry> _entries;
  final _tipCtrl = TextEditingController();
  _BillEstimate? _estimate;
  bool _loading = false;
  bool _includeService = true;
  bool _includeCover = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _entries = Map<String, _CartEntry>.from(widget.entries);
    _refreshEstimate();
  }

  @override
  void dispose() {
    _tipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final items = _entries.values.toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.cart,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              AppEmptyState(
                icon: Icons.shopping_cart_outlined,
                title: t.cartEmpty,
                description: t.addItemToCalculate,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = items[index];
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _changeQty(entry.item.id, -1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '${entry.qty}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          IconButton(
                            onPressed: () => _changeQty(entry.item.id, 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            if (items.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tipCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t.tipPercentage),
                      onChanged: (_) => _refreshEstimate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _includeService,
                          onChanged: (v) => setState(() => _includeService = v),
                          title: Text(t.serviceIncluded),
                          dense: true,
                        ),
                        SwitchListTile(
                          value: _includeCover,
                          onChanged: (v) => setState(() => _includeCover = v),
                          title: Text(t.coverIncluded),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildEstimate(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstimate() {
    final t = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Text(
        AppErrorMapper.message(_error),
        style: const TextStyle(color: AppColors.danger),
      );
    }
    if (_estimate == null) {
      return const SizedBox.shrink();
    }

    final est = _estimate!;
    final cover = _includeCover ? est.coverCents : 0;
    final service = _includeService ? est.serviceFeeCents : 0;
    final tip = est.tipCents;
    final total = est.subtotalCents + cover + service + tip;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breakdownRow(t.subtotal, est.subtotalCents),
          if (est.hasRules) ...[
            _breakdownRow(t.cover, cover),
            _breakdownRow(t.serviceWithPercent(est.serviceFeePct), service),
            _breakdownRow(t.tipWithPercent(est.tipPct), tip),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              t.serviceCoverMayVary,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            _breakdownRow(t.tipWithPercent(est.tipPct), tip),
          ],
          const Divider(height: 16),
          _breakdownRow(t.estimatedTotal, total, emphasize: true),
          const SizedBox(height: 4),
          Text(
            est.vatIncluded ? t.vatIncluded : t.vatExcluded,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int cents, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            _formatPriceFromCents(context, cents) ?? '--,--',
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _changeQty(String id, int delta) {
    final current = _entries[id];
    if (current == null) return;
    final nextQty = current.qty + delta;
    if (nextQty <= 0) {
      _entries.remove(id);
    } else {
      _entries[id] = current.copyWith(qty: nextQty);
    }
    widget.onUpdate(_entries);
    setState(() {});
    _refreshEstimate();
  }

  Future<void> _refreshEstimate() async {
    final items = _entries.values
        .map((e) => {'menu_item_id': e.item.id, 'qty': e.qty})
        .toList();
    if (items.isEmpty) {
      setState(() {
        _estimate = null;
        _error = null;
      });
      return;
    }
    final tipPct = int.tryParse(_tipCtrl.text.trim());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(menuRepositoryProvider)
          .getBillEstimate(
            businessId: widget.businessId,
            items: items,
            tipPct: tipPct,
          );
      if (!mounted) return;
      setState(() {
        _estimate = _BillEstimate.fromMap(res);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }
}

class _DietChip extends StatelessWidget {
  const _DietChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppChip(label: label, color: AppColors.primary, filled: true);
  }
}

class _MenuItemSkeleton extends StatelessWidget {
  const _MenuItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          AppSkeletonCard(),
          SizedBox(height: 14),
          AppSkeletonLine(width: 160),
          SizedBox(height: 8),
          AppSkeletonLine(width: 120),
          SizedBox(height: 16),
          AppSkeletonCard(),
        ],
      ),
    );
  }
}

class _MenuItemError extends StatelessWidget {
  const _MenuItemError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        children: [
          AppEmptyState(
            icon: Icons.warning_amber_outlined,
            title: t.errorOccurred,
            description: message,
            ctaLabel: t.retry,
            onCta: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MenuItemNotFound extends StatelessWidget {
  const _MenuItemNotFound();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        children: [
          AppEmptyState(
            icon: Icons.search_off,
            title: t.menuNotAddedYet,
            description: t.menuItemNotFoundDescription,
            ctaLabel: t.back,
            onCta: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

Widget _maxWidth(BuildContext context, Widget child) {
  final width = MediaQuery.of(context).size.width;
  final maxWidth = width >= 1040 ? 1040.0 : (width >= 720 ? 720.0 : width);
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

void _redirectToLogin(BuildContext context) {
  showQuickLoginSheet(context);
}

Future<void> _openSuggestionSheet(
  BuildContext context,
  String businessId,
  MenuItem item,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SuggestionSheet(businessId: businessId, item: item),
  );
}

Future<PriceSuggestionSubmissionResult?> _openPriceSuggestionSheet(
  BuildContext context,
  String menuItemId,
  String businessId,
  String menuId,
) async {
  return showModalBottomSheet<PriceSuggestionSubmissionResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PriceSuggestionSheet(
      menuItemId: menuItemId,
      businessId: businessId,
      menuId: menuId,
    ),
  );
}

Future<void> _openValueScoreSheet(
  BuildContext context,
  MenuItemValueScore score,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ValueScoreSheet(score: score),
  );
}

Future<void> _openPriceThanksSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer(
          builder: (context, ref, _) {
            final t = AppLocalizations.of(context);
            final progressAsync = ref.watch(myProfileProgressProvider);
            return progressAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => _ThanksContent(
                levelLabel: t.menuContributionLevelLabel,
                levelValue: t.menuLevel(1),
                progress: 0.2,
                scoreText: t.menuScoreUpdated,
              ),
              data: (progress) {
                final level = progress?.level ?? 1;
                final totalXp = progress?.totalXp ?? 0;
                final xpInLevel = progress?.xpInLevel ?? 0;
                final nextLevelXp = progress?.nextLevelXp ?? 100;
                return _ThanksContent(
                  levelLabel: t.menuContributionLevelLabel,
                  levelValue: t.menuLevel(level),
                  progress: (xpInLevel / nextLevelXp).clamp(0.0, 1.0),
                  scoreText: t.menuXpValue(totalXp),
                );
              },
            );
          },
        ),
      );
    },
  );
}

Future<void> _refreshPriceData(WidgetRef ref, String menuItemId) async {
  await Future.wait([
    ref
        .read(menuItemPriceHistoryProvider(menuItemId).notifier)
        .refresh(force: true),
    ref
        .read(menuItemPriceStatusProvider(menuItemId).notifier)
        .refresh(force: true),
    ref
        .read(menuItemValueScoreProvider(menuItemId).notifier)
        .refresh(force: true),
  ]);
}

class _ThanksContent extends StatelessWidget {
  const _ThanksContent({
    required this.levelLabel,
    required this.levelValue,
    required this.progress,
    required this.scoreText,
  });

  final String levelLabel;
  final String levelValue;
  final double progress;
  final String scoreText;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.thankYou,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(t.trustScoreInfoNote, style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.7, end: 1),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                t.plusPoints(20),
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.verifyContributionRaisedScore,
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Text(
          '$levelLabel â€¢ $levelValue',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.cardAlt,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(scoreText, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SuggestionSheet extends ConsumerStatefulWidget {
  const _SuggestionSheet({required this.businessId, required this.item});
  final String businessId;
  final MenuItem item;

  @override
  ConsumerState<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _PriceSuggestionSheet extends ConsumerStatefulWidget {
  const _PriceSuggestionSheet({
    required this.menuItemId,
    required this.businessId,
    required this.menuId,
  });
  final String menuItemId;
  final String businessId;
  final String menuId;

  @override
  ConsumerState<_PriceSuggestionSheet> createState() =>
      _PriceSuggestionSheetState();
}

class _PriceSuggestionSheetState extends ConsumerState<_PriceSuggestionSheet> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  bool _uploading = false;
  Object? _error;
  bool _vatIncluded = true;
  String? _evidenceUrl;

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.priceVerification,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              t.priceVerificationSteps,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(
                _priceSuggestionErrorText(context, _error),
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.newPriceTry),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: t.note),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: (_submitting || _uploading) ? null : _pickEvidence,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(
                _evidenceUrl == null ? t.addEvidencePhoto : t.evidenceAdded,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(t.vatIncluded),
                const Spacer(),
                Switch(
                  value: _vatIncluded,
                  onChanged: (value) => setState(() => _vatIncluded = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.submit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final parsed = _parsePrice(_priceController.text.trim());
    final noteText = _noteController.text.trim();
    final moderation = await ContentModeration.instance.validateNote(noteText);
    if (moderation != null) {
      setState(() => _error = moderation.code);
      return;
    }
    if (parsed == null) {
      setState(() => _error = 'invalid_price');
      return;
    }
    final cents = (parsed * 100).round();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final clientId = await getAnalyticsClientId();
      final result = await ref
          .read(menuRepositoryProvider)
          .submitMenuItemPriceSuggestion(
            menuItemId: widget.menuItemId,
            suggestedPriceCents: cents,
            currency: 'TRY',
            clientId: clientId,
            capturedAt: DateTime.now(),
            note: noteText,
            evidenceUrl: _evidenceUrl,
            businessId: widget.businessId,
            menuId: widget.menuId,
          );
      if (!result.ok) {
        setState(() {
          _submitting = false;
          _error = result.error ?? 'unknown';
        });
        return;
      }
      if (!mounted) return;
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: 'price_suggestion_submitted',
            businessId: widget.businessId,
            source: 'menu_item_price_suggestion',
            clientId: clientId,
            meta: {'menu_item_id': widget.menuItemId},
          );
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.verifyPriceSubmit,
            businessId: widget.businessId,
            source: 'menu_item_price_suggestion',
            clientId: clientId,
            meta: {'menu_item_id': widget.menuItemId},
          );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on OfflineQueuedException {
      if (!mounted) return;
      Navigator.pop(
        context,
        const PriceSuggestionSubmissionResult(ok: true, queued: true),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = AppErrorMapper.message(e);
      if (msg.contains('rate_limited_24h')) {
        setState(() {
          _submitting = false;
          _error = 'rate_limited_24h';
        });
        return;
      }
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  Future<void> _pickEvidence() async {
    setState(() => _uploading = true);
    try {
      final upload = await pickAndUploadWpImage(
        client: ref.read(supabaseProvider),
        title: 'price_proof_${widget.menuItemId}',
        businessId: widget.businessId,
        menuItemId: widget.menuItemId,
        critical: true,
      );
      if (upload == null) return;
      if (!mounted) return;
      setState(() => _evidenceUrl = upload.urlLarge);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _SuggestionSheetState extends ConsumerState<_SuggestionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late bool _isVegan;
  late bool _isGlutenFree;
  int? _selectedCatalogItemId;
  bool _suppressListener = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.read(foodCatalogSearchProvider.notifier).clear();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
      text: widget.item.price == null ? '' : _rawPrice(widget.item.price!),
    );
    _isVegan = widget.item.isVegan;
    _isGlutenFree = widget.item.isGlutenFree;
    _selectedCatalogItemId = widget.item.catalogItemId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.suggestEdit,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  onChanged: (value) {
                    if (_suppressListener) {
                      _suppressListener = false;
                      return;
                    }
                    if (_selectedCatalogItemId != null) {
                      setState(() => _selectedCatalogItemId = null);
                    }
                    ref
                        .read(foodCatalogSearchProvider.notifier)
                        .setQuery(value);
                  },
                  decoration: InputDecoration(labelText: t.menuItemName),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return t.menuItemNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _CatalogAutocomplete(onSelect: _selectCatalogItem),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.priceTry),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    if (_parsePrice(text) == null) {
                      return t.enterValidPrice;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isVegan,
                  onChanged: (value) => setState(() => _isVegan = value),
                  title: Text(t.vegan),
                ),
                SwitchListTile(
                  value: _isGlutenFree,
                  onChanged: (value) => setState(() => _isGlutenFree = value),
                  title: Text(t.glutenFree),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.sendSuggestion),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final priceValue = priceText.isEmpty ? null : _parsePrice(priceText);
    final basePrice = widget.item.price;

    final nameChanged = name != widget.item.name;
    final veganChanged = _isVegan != widget.item.isVegan;
    final glutenChanged = _isGlutenFree != widget.item.isGlutenFree;
    final priceChanged = priceValue != basePrice;

    if (!nameChanged && !veganChanged && !glutenChanged && !priceChanged) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.noChanges)));
      return;
    }

    final action =
        (priceChanged && !nameChanged && !veganChanged && !glutenChanged)
        ? 'price_update'
        : 'update';

    if (action == 'price_update' && priceValue == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.priceCannotBeEmpty)));
      return;
    }

    final payload = <String, dynamic>{
      if (action == 'update') 'name': name,
      if (action == 'update') 'is_vegan': _isVegan,
      if (action == 'update') 'is_gluten_free': _isGlutenFree,
      ...?(priceValue == null ? null : {'price': priceValue}),
      ...?(_selectedCatalogItemId == null
          ? null
          : {'catalog_item_id': _selectedCatalogItemId}),
    };

    setState(() => _submitting = true);
    try {
      await ref
          .read(menuRepositoryProvider)
          .submitSuggestion(
            businessId: widget.businessId,
            menuItemId: widget.item.id,
            action: action,
            payload: payload,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.suggestionSentPendingApproval)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _selectCatalogItem(FoodCatalogHit item) async {
    setState(() {
      _selectedCatalogItemId = item.id;
    });
    _suppressListener = true;
    _nameController.text = item.name;
    ref.read(foodCatalogSearchProvider.notifier).clear();
    try {
      await ref.read(foodCatalogRepositoryProvider).bump(item.id);
    } catch (_) {}
  }
}

class _CatalogAutocomplete extends StatelessWidget {
  const _CatalogAutocomplete({required this.onSelect});

  final ValueChanged<FoodCatalogHit> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(foodCatalogSearchProvider);
        final queryLen = state.query.trim().length;

        if (state.isLoading) {
          return const _CatalogSkeleton();
        }
        if (state.error != null) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  AppErrorMapper.message(state.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.read(foodCatalogSearchProvider.notifier).retry(),
                child: Text(t.retry),
              ),
            ],
          );
        }
        if (state.results.isEmpty) {
          if (queryLen < 2) return const SizedBox.shrink();
          return Text(
            t.noSuggestionFound,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.suggestedFoods,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(height: 6),
            for (final hit in state.results) ...[
              _CatalogRow(
                name: hit.name,
                category: hit.categoryName,
                onTap: () => onSelect(hit),
              ),
              const SizedBox(height: 6),
            ],
          ],
        );
      },
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.name,
    required this.category,
    required this.onTap,
  });

  final String name;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (category.isNotEmpty)
              Text(
                category,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeletonLine(width: 180),
        SizedBox(height: 6),
        AppSkeletonLine(width: 160),
        SizedBox(height: 6),
        AppSkeletonLine(width: 140),
      ],
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
        final latest = items.take(3).toList();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.priceHistoryLast3,
                style: TextStyle(
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

class _PriceStatusCard extends StatelessWidget {
  const _PriceStatusCard({
    required this.item,
    required this.statusAsync,
    required this.onRetry,
    required this.onVote,
    required this.onUpdate,
  });

  final MenuItem item;
  final AsyncValue<MenuItemPriceStatus> statusAsync;
  final VoidCallback onRetry;
  final Future<void> Function(int vote) onVote;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: statusAsync.when(
        loading: () => const _PriceStatusSkeleton(),
        error: (e, _) => _PriceStatusError(
          message: AppErrorMapper.message(e),
          onRetry: onRetry,
        ),
        data: (status) {
          final priceText =
              _formatPriceFromCents(context, status.priceCents) ??
              _formatPrice(context, item.price);
          final badge = _statusBadge(status.status, t);
          final isRecent =
              status.lastVerifiedAt != null &&
              DateTime.now().difference(status.lastVerifiedAt!).inHours <= 48;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.price,
                    style: TextStyle(
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
                      fontSize: 16,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.last30DaysVotes(status.okVotes, status.badVotes),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (status.lastVerifiedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  t.lastVerificationDate(_fmtDate(status.lastVerifiedAt!)),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
              if (isRecent) ...[
                const SizedBox(height: 6),
                AppChip(
                  label: t.priceVerifiedInLast48h,
                  color: AppColors.success,
                  filled: true,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                t.uniqueVerifiersIn48h(status.verifiedSources48h),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (status.safeToTrust) ...[
                const SizedBox(height: 6),
                AppChip(
                  label: t.strongConsensusPriceSafe,
                  color: AppColors.info,
                  filled: true,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                t.priceConfidenceScore(
                  (status.confidenceScore * 100).clamp(0, 100).round(),
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onVote(1),
                      icon: Icon(
                        Icons.thumb_up_alt_outlined,
                        color: status.myVote == 1 ? AppColors.success : null,
                      ),
                      label: Text(t.seenCorrect),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onVote(-1),
                      icon: Icon(
                        Icons.thumb_down_alt_outlined,
                        color: status.myVote == -1 ? AppColors.danger : null,
                      ),
                      label: Text(t.seenIncorrect),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onUpdate,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(t.suggestNewPrice),
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
          Text(
            t.howCalculated,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
  if (price == null) return context.l10n.unknown;
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

String _priceSuggestionErrorText(BuildContext context, Object? error) {
  final t = AppLocalizations.of(context);
  if (error == null) return '';
  if (error == 'invalid_price') return t.priceInvalid;
  if (error == AppErrorCodes.containsLinkOrPhone) {
    return t.noteNoLinkPhone;
  }
  if (error == AppErrorCodes.containsProfanity) {
    return t.noteContainsProfanity;
  }
  if (error == AppErrorCodes.emojiSpam) {
    return t.noteTooManyEmoji;
  }
  if (error == 'rate_limited_24h') {
    return t.rateLimited24h;
  }
  if (error == AppErrorCodes.priceSuggestionDailyRateLimited) {
    return t.dailyPriceSuggestionLimitReached;
  }
  if (error == 'bad_evidence_url') {
    return t.invalidEvidenceLink;
  }
  if (error == 'bad_currency') {
    return t.invalidCurrency;
  }
  return AppErrorMapper.message(error);
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

