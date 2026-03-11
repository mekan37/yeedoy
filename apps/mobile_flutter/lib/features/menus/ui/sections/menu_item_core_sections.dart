part of '../menu_item_page.dart';

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
