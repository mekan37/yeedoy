import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../owner_menu_management/ui/owner_menu_trash_page.dart';
import '../data/admin_businesses_repository.dart';
import '../domain/admin_models.dart';

final _adminTrashSearchProvider =
    FutureProvider.autoDispose.family<List<AdminBusinessItem>, String>((
      ref,
      query,
    ) async {
      final normalized = query.trim();
      if (normalized.length < 2) return const [];
      return ref.read(adminBusinessesRepositoryProvider).listBusinesses(
            query: normalized,
            limit: 12,
          );
    });

final _adminTrashBusinessProvider =
    FutureProvider.autoDispose.family<AdminBusinessItem?, String>((
      ref,
      businessId,
    ) async {
      if (businessId.trim().isEmpty) return null;
      return ref.read(adminBusinessesRepositoryProvider).fetchBusinessById(
            businessId: businessId,
          );
    });

class AdminMenuRestorePage extends ConsumerStatefulWidget {
  const AdminMenuRestorePage({super.key, this.initialBusinessId});

  final String? initialBusinessId;

  @override
  ConsumerState<AdminMenuRestorePage> createState() =>
      _AdminMenuRestorePageState();
}

class _AdminMenuRestorePageState extends ConsumerState<AdminMenuRestorePage> {
  late final TextEditingController _searchCtrl;
  String _query = '';
  String? _selectedBusinessId;

  @override
  void initState() {
    super.initState();
    _selectedBusinessId = widget.initialBusinessId?.trim().isNotEmpty == true
        ? widget.initialBusinessId!.trim()
        : null;
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(_adminTrashSearchProvider(_query));
    final selectedBusinessAsync = ref.watch(
      _adminTrashBusinessProvider(_selectedBusinessId ?? ''),
    );
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminMenuRestoreTitle),
            description: l10n.adminMenuRestoreDescription,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    labelText: l10n.adminMenuRestoreBusinessSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedBusinessId != null)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedBusinessId = null),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.clear),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedBusinessId != null)
            selectedBusinessAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error.toString()),
              ),
              data: (business) {
                if (business == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(business.name),
                    subtitle: Text(_businessLocation(business)),
                    trailing: Text(
                      business.id,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            )
          else
            searchAsync.when(
              loading: () => _query.length < 2
                  ? const SizedBox.shrink()
                  : const LinearProgressIndicator(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error.toString()),
              ),
              data: (items) {
                if (_query.length < 2) {
                  return OwnerPanelFeedback.empty(
                    icon: Icons.manage_search_outlined,
                    title: l10n.adminMenuRestoreSearchEmptyTitle,
                    description: l10n.adminMenuRestoreSearchEmptyDescription,
                  );
                }
                if (items.isEmpty) {
                  return OwnerPanelFeedback.empty(
                    icon: Icons.store_mall_directory_outlined,
                    title: l10n.adminMenuRestoreNoBusinessTitle,
                    description: l10n.adminMenuRestoreNoBusinessDescription,
                  );
                }
                return Card(
                  child: Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          leading: const Icon(Icons.store_outlined),
                          title: Text(item.name),
                          subtitle: Text(_businessLocation(item)),
                          trailing: TextButton(
                            onPressed: () => setState(() {
                              _selectedBusinessId = item.id;
                            }),
                            child: Text(l10n.adminMenuRestoreSelectBusinessAction),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedBusinessId == null
                ? OwnerPanelFeedback.empty(
                    icon: Icons.delete_sweep_outlined,
                    title: l10n.adminMenuRestoreSelectBusinessTitle,
                    description: l10n.adminMenuRestoreSelectBusinessDescription,
                  )
                : OwnerMenuTrashPanel(
                    businessId: _selectedBusinessId!,
                    title: l10n.adminMenuRestorePanelTitle,
                    description: l10n.adminMenuRestorePanelDescription,
                  ),
          ),
        ],
      ),
    );
  }
}

String _businessLocation(AdminBusinessItem item) {
  final district = (item.district ?? '').trim();
  final city = (item.city ?? '').trim();
  if (district.isEmpty && city.isEmpty) return '-';
  return [district, city].where((value) => value.isNotEmpty).join(', ');
}
