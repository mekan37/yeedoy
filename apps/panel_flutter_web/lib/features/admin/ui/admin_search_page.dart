import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/permission_denied_view.dart';
import '../data/admin_search_repository.dart';
import '../domain/admin_access_provider.dart';
import '../domain/admin_search_models.dart';

class AdminSearchPage extends ConsumerStatefulWidget {
  const AdminSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends ConsumerState<AdminSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _resultsFocusNode = FocusNode();

  Timer? _debounce;
  bool _loading = false;
  Object? _error;
  List<AdminSearchResult> _results = const [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = (widget.initialQuery ?? '').trim();
    if (_searchCtrl.text.length >= 2) {
      _runSearch();
    }
  }

  @override
  void didUpdateWidget(covariant AdminSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.initialQuery ?? '').trim();
    if (next != (oldWidget.initialQuery ?? '').trim() &&
        next != _searchCtrl.text.trim()) {
      _searchCtrl.text = next;
      if (next.length >= 2) {
        _runSearch();
      } else {
        setState(() {
          _results = const [];
          _selectedIndex = 0;
          _error = null;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _resultsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(adminAccessProvider);
    return accessAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: OwnerPanelFeedback.loading(cardCount: 4),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: OwnerPanelFeedback.error(
          title: context.l10n.adminSearchErrorTitle,
          description: error.toString(),
          onRetry: _runSearch,
        ),
      ),
      data: (allowed) {
        if (!allowed) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: PermissionDeniedView(
              title: context.l10n.forbiddenTitle,
              description: context.l10n.adminSearchForbiddenDescription,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.arrowDown):
                  _SearchMoveIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  _SearchMoveIntent(-1),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                _SearchMoveIntent: CallbackAction<_SearchMoveIntent>(
                  onInvoke: (intent) {
                    _moveSelection(intent.delta);
                    return null;
                  },
                ),
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _openSelected();
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                focusNode: _resultsFocusNode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.adminSearchTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.adminSearchDescription,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              onChanged: (_) => _scheduleSearch(),
                              onSubmitted: (_) {
                                _runSearch();
                                _resultsFocusNode.requestFocus();
                              },
                              decoration: InputDecoration(
                                hintText: context.l10n.adminSearchInputHint,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchCtrl.text.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _scheduleSearch();
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _runSearch,
                            icon: const Icon(Icons.search),
                            label: Text(context.l10n.adminSearchRunAction),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.adminSearchKeyboardHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildBody(context)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) {
      return OwnerPanelFeedback.empty(
        icon: Icons.manage_search_outlined,
        title: context.l10n.adminSearchStartTitle,
        description: context.l10n.adminSearchStartDescription,
      );
    }
    if (_loading && _results.isEmpty) {
      return const OwnerPanelFeedback.loading(cardCount: 5);
    }
    if (_error != null && _results.isEmpty) {
      return OwnerPanelFeedback.error(
        title: context.l10n.adminSearchErrorTitle,
        description: AppErrorMapper.message(_error),
        onRetry: _runSearch,
      );
    }
    if (_results.isEmpty) {
      return OwnerPanelFeedback.empty(
        icon: Icons.search_off_outlined,
        title: context.l10n.adminSearchEmptyTitle,
        description: context.l10n.adminSearchEmptyDescription(query),
      );
    }

    final groups = _groupResults(_results);
    var runningIndex = 0;
    return ListView(
      children: [
        for (final category in _orderedCategories)
          if ((groups[category] ?? const []).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _categoryLabel(context.l10n, category),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final item in groups[category]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SearchResultCard(
                  item: item,
                  selected: runningIndex++ == _selectedIndex,
                  categoryLabel: _categoryLabel(context.l10n, category),
                  onOpen: () => _openResult(item),
                  onOpenInNewTab: () => _openInNewTab(item),
                  onCopyId: () => _copyId(item.id),
                ),
              ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
    setState(() {});
  }

  Future<void> _runSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _results = const [];
        _selectedIndex = 0;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(adminSearchRepositoryProvider)
          .search(query: query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _selectedIndex = results.isEmpty ? 0 : _selectedIndex.clamp(0, results.length - 1);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _moveSelection(int delta) {
    if (_results.isEmpty) return;
    setState(() {
      final next = (_selectedIndex + delta).clamp(0, _results.length - 1);
      _selectedIndex = next;
    });
  }

  void _openSelected() {
    if (_results.isEmpty || _selectedIndex >= _results.length) return;
    _openResult(_results[_selectedIndex]);
  }

  void _openResult(AdminSearchResult item) {
    context.go(_routeForItem(item));
  }

  Future<void> _openInNewTab(AdminSearchResult item) async {
    final route = _routeForItem(item);
    final uri = Uri.base.resolve(route);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.adminSearchCopiedId)),
    );
  }
}

class _SearchMoveIntent extends Intent {
  const _SearchMoveIntent(this.delta);

  final int delta;
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.item,
    required this.selected,
    required this.categoryLabel,
    required this.onOpen,
    required this.onOpenInNewTab,
    required this.onCopyId,
  });

  final AdminSearchResult item;
  final bool selected;
  final String categoryLabel;
  final VoidCallback onOpen;
  final VoidCallback onOpenInNewTab;
  final VoidCallback onCopyId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.borderStrong : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                _SearchBadge(label: categoryLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.id,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenInNewTab,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(context.l10n.adminSearchOpenInNewTabAction),
                ),
                TextButton.icon(
                  onPressed: onCopyId,
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  label: Text(context.l10n.adminSearchCopyIdAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBadge extends StatelessWidget {
  const _SearchBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

const List<AdminSearchCategory> _orderedCategories = <AdminSearchCategory>[
  AdminSearchCategory.business,
  AdminSearchCategory.user,
  AdminSearchCategory.report,
  AdminSearchCategory.submission,
  AdminSearchCategory.claim,
  AdminSearchCategory.menuItem,
];

Map<AdminSearchCategory, List<AdminSearchResult>> _groupResults(
  List<AdminSearchResult> items,
) {
  final map = <AdminSearchCategory, List<AdminSearchResult>>{};
  for (final item in items) {
    map.putIfAbsent(item.category, () => <AdminSearchResult>[]).add(item);
  }
  return map;
}

String _categoryLabel(AppLocalizations l10n, AdminSearchCategory category) {
  return switch (category) {
    AdminSearchCategory.business => l10n.adminSearchCategoryBusinesses,
    AdminSearchCategory.user => l10n.adminSearchCategoryUsers,
    AdminSearchCategory.report => l10n.adminSearchCategoryReports,
    AdminSearchCategory.submission => l10n.adminSearchCategorySubmissions,
    AdminSearchCategory.claim => l10n.adminSearchCategoryClaims,
    AdminSearchCategory.menuItem => l10n.adminSearchCategoryMenuItems,
  };
}

String _routeForItem(AdminSearchResult item) {
  final encodedToken = Uri.encodeQueryComponent(item.routeQueryToken);
  return switch (item.category) {
    AdminSearchCategory.business =>
      '/admin/businesses?q=$encodedToken',
    AdminSearchCategory.user =>
      '/admin/users/${item.id}',
    AdminSearchCategory.report =>
      '/admin/queue?type=report&q=$encodedToken',
    AdminSearchCategory.submission =>
      '/admin/queue?type=business_submission&q=$encodedToken',
    AdminSearchCategory.claim =>
      '/admin/queue?type=claim&q=$encodedToken',
    AdminSearchCategory.menuItem =>
      '/admin/businesses?q=$encodedToken',
  };
}
