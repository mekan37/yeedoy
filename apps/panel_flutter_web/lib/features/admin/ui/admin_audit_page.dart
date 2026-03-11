import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/admin_audit_controller.dart';
import '../domain/admin_audit_models.dart';
import 'web_download.dart';
import 'widgets/audit_table.dart';

class AdminAuditPage extends ConsumerStatefulWidget {
  const AdminAuditPage({
    super.key,
    this.ownerMode = false,
    this.businessId,
  });

  final bool ownerMode;
  final String? businessId;

  @override
  ConsumerState<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends ConsumerState<AdminAuditPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _actionFilter = '';
  String _targetTypeFilter = '';
  bool _myActionsOnly = false;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  _OwnerActivityPreset _ownerPreset = _OwnerActivityPreset.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    Future.microtask(_loadInitial);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdminAuditPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId ||
        oldWidget.ownerMode != widget.ownerMode) {
      Future.microtask(_loadInitial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuditControllerProvider);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AuditTable(
        ownerMode: widget.ownerMode,
        title: widget.ownerMode ? l10n.ownerActivityTitle : l10n.adminAuditTitle,
        description: widget.ownerMode
            ? l10n.ownerActivityDescription
            : l10n.adminAuditDescription,
        items: state.items,
        isLoading: state.isLoading,
        isLoadingMore: state.isLoadingMore,
        errorText: state.error == null ? null : AppErrorMapper.message(state.error),
        scrollController: _scrollController,
        searchController: _searchController,
        actionFilter: _actionFilter,
        targetTypeFilter: _targetTypeFilter,
        myActionsOnly: _myActionsOnly,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        quickFilterValue: widget.ownerMode ? _ownerPreset.name : null,
        onQuickFilterChanged: widget.ownerMode
            ? (value) => _applyOwnerPreset(
                _ownerPresetFromName(value),
                user?.id,
              )
            : null,
        onActionChanged: (value) => setState(() {
          _ownerPreset = _OwnerActivityPreset.all;
          _actionFilter = value ?? '';
        }),
        onTargetTypeChanged: (value) => setState(() {
          _ownerPreset = _OwnerActivityPreset.all;
          _targetTypeFilter = value ?? '';
        }),
        onMyActionsChanged: (value) => setState(() => _myActionsOnly = value),
        onApplyFilters: () => _applyFilters(user?.id),
        onResetFilters: _resetFilters,
        onRefresh: () => ref.read(adminAuditControllerProvider.notifier).refresh(),
        onPickDateRange: _pickDateRange,
        onClearDateRange: () {
          setState(() {
            _ownerPreset = _OwnerActivityPreset.all;
            _dateFrom = null;
            _dateTo = null;
          });
          _applyFilters(user?.id);
        },
        onExportCsv: widget.ownerMode ? null : () => _exportCsv(context, state.items),
      ),
    );
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(adminAuditControllerProvider.notifier).loadMore();
    }
  }

  void _loadInitial() {
    final userId = ref.read(userProvider)?.id;
    ref.read(adminAuditControllerProvider.notifier).setFilters(
      actionFilter: _actionFilter,
      targetTypeFilter: _targetTypeFilter,
      actorFilter: _myActionsOnly ? (userId ?? '') : '',
      targetId: '',
      businessId: (widget.businessId ?? '').trim(),
      from: _dateFrom,
      to: _dateTo == null
          ? null
          : DateTime(
              _dateTo!.year,
              _dateTo!.month,
              _dateTo!.day,
              23,
              59,
              59,
            ),
      query: _searchController.text.trim(),
    );
    ref.read(adminAuditControllerProvider.notifier).loadInitial();
  }

  void _applyFilters(String? currentUserId) {
    ref.read(adminAuditControllerProvider.notifier).setFilters(
      actionFilter: _actionFilter,
      targetTypeFilter: _targetTypeFilter,
      actorFilter: _myActionsOnly ? (currentUserId ?? '') : '',
      targetId: '',
      businessId: (widget.businessId ?? '').trim(),
      from: _dateFrom,
      to: _dateTo == null
          ? null
          : DateTime(
              _dateTo!.year,
              _dateTo!.month,
              _dateTo!.day,
              23,
              59,
              59,
            ),
      query: _searchController.text.trim(),
    );
    ref.read(adminAuditControllerProvider.notifier).loadInitial();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _ownerPreset = _OwnerActivityPreset.all;
      _actionFilter = '';
      _targetTypeFilter = '';
      _myActionsOnly = false;
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(adminAuditControllerProvider.notifier).setFilters(
      actionFilter: '',
      targetTypeFilter: '',
      actorFilter: '',
      targetId: '',
      businessId: (widget.businessId ?? '').trim(),
      from: null,
      to: null,
      query: '',
    );
    ref.read(adminAuditControllerProvider.notifier).loadInitial();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateFrom == null || _dateTo == null
          ? null
          : DateTimeRange(start: _dateFrom!, end: _dateTo!),
    );
    if (!mounted || range == null) return;
    setState(() {
      _ownerPreset = _OwnerActivityPreset.all;
      _dateFrom = range.start;
      _dateTo = range.end;
    });
  }

  void _applyOwnerPreset(_OwnerActivityPreset preset, String? currentUserId) {
    final now = DateTime.now();
    setState(() {
      _ownerPreset = preset;
      switch (preset) {
        case _OwnerActivityPreset.all:
          _actionFilter = '';
          _targetTypeFilter = '';
          _dateFrom = null;
          _dateTo = null;
          break;
        case _OwnerActivityPreset.today:
          _actionFilter = '';
          _targetTypeFilter = '';
          _dateFrom = DateTime(now.year, now.month, now.day);
          _dateTo = now;
          break;
        case _OwnerActivityPreset.last7Days:
          _actionFilter = '';
          _targetTypeFilter = '';
          _dateFrom = DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 6),
          );
          _dateTo = now;
          break;
        case _OwnerActivityPreset.teamChanges:
          _actionFilter = '';
          _targetTypeFilter = 'team_member';
          _dateFrom = null;
          _dateTo = null;
          break;
      }
    });
    _applyFilters(currentUserId);
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<AdminAuditLogItem> items,
  ) async {
    final rows = <String>[
      'created_at,action,target_type,target_id,actor_id,actor_role',
      for (final item in items)
        [
          _csvValue(item.createdAt.toIso8601String()),
          _csvValue(item.action),
          _csvValue(item.targetType),
          _csvValue(item.targetId),
          _csvValue(item.actorId),
          _csvValue(item.actorRole),
        ].join(','),
    ];
    downloadCsv('audit_${_stamp()}.csv', rows.join('\n'));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.adminAuditExportReady)));
  }
}

enum _OwnerActivityPreset { all, today, last7Days, teamChanges }

_OwnerActivityPreset _ownerPresetFromName(String value) {
  return _OwnerActivityPreset.values.firstWhere(
    (preset) => preset.name == value,
    orElse: () => _OwnerActivityPreset.all,
  );
}

String _csvValue(String input) {
  final escaped = input.replaceAll('"', '""');
  return '"$escaped"';
}

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}
