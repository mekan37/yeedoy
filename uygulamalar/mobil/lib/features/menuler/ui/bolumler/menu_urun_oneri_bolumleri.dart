part of '../menu_urun_sayfasi.dart';

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
              style: context.sectionTitleStyle,
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
      final upload = await ref
          .read(mediaUploadRepositoryProvider)
          .pickAndUploadImage(
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
                  style: context.sectionTitleStyle,
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

