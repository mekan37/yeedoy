import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/storage/admin_table_saved_views_prefs.dart';

class AdminTableStatusOption {
  const AdminTableStatusOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class AdminTableBulkAction {
  const AdminTableBulkAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
}

class AdminVirtualTableColumn {
  const AdminVirtualTableColumn({
    required this.label,
    required this.width,
    this.alignment = Alignment.centerLeft,
  });

  final Widget label;
  final double width;
  final Alignment alignment;
}

class AdminVirtualTableRow {
  const AdminVirtualTableRow({
    required this.key,
    required this.cells,
    this.selected = false,
    this.onTap,
  });

  final ValueKey<String> key;
  final List<Widget> cells;
  final bool selected;
  final VoidCallback? onTap;
}

class AdminTableFilterBar extends StatelessWidget {
  const AdminTableFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.statusValue,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.savedViews,
    required this.selectedSavedViewId,
    required this.onSavedViewSelected,
    required this.onSaveCurrentView,
    required this.onDeleteSavedView,
    this.trailing,
    this.extraFilters = const <Widget>[],
  });

  final TextEditingController searchController;
  final String searchHint;
  final String statusValue;
  final List<AdminTableStatusOption> statusOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final DateTimeRange? dateRange;
  final Future<void> Function() onPickDateRange;
  final VoidCallback onClearDateRange;
  final List<AdminSavedViewRecord> savedViews;
  final String? selectedSavedViewId;
  final ValueChanged<String?> onSavedViewSelected;
  final Future<void> Function() onSaveCurrentView;
  final Future<void> Function(String id) onDeleteSavedView;
  final Widget? trailing;
  final List<Widget> extraFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savedValue = savedViews.any((view) => view.id == selectedSavedViewId)
        ? selectedSavedViewId
        : null;
    final filterActions = <Widget>[
      SizedBox(
        width: 280,
        child: TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: l10n.search,
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      SizedBox(
        width: 220,
        child: DropdownButtonFormField<String>(
          initialValue: statusValue,
          decoration: InputDecoration(
            labelText: l10n.adminTableStatusLabel,
          ),
          items: [
            for (final option in statusOptions)
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label),
              ),
          ],
          onChanged: (value) => onStatusChanged(value ?? ''),
        ),
      ),
      OutlinedButton.icon(
        onPressed: onPickDateRange,
        icon: const Icon(Icons.date_range_outlined),
        label: Text(
          dateRange == null
              ? l10n.adminTablePickDateRangeAction
              : l10n.adminTableDateRangeValue(
                  _fmtDate(dateRange!.start),
                  _fmtDate(dateRange!.end),
                ),
        ),
      ),
      if (dateRange != null)
        TextButton(
          onPressed: onClearDateRange,
          child: Text(l10n.adminTableClearDateRangeAction),
        ),
      SizedBox(
        width: 220,
        child: DropdownButtonFormField<String?>(
          initialValue: savedValue,
          decoration: InputDecoration(
            labelText: l10n.adminTableSavedViewsLabel,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.adminTableNoSavedViews),
            ),
            for (final view in savedViews)
              DropdownMenuItem<String?>(
                value: view.id,
                child: Text(view.label),
              ),
          ],
          onChanged: onSavedViewSelected,
        ),
      ),
      OutlinedButton.icon(
        onPressed: onSaveCurrentView,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: Text(l10n.adminTableSaveViewAction),
      ),
    ];
    if (savedValue != null) {
      filterActions.add(
        OutlinedButton.icon(
          onPressed: () => onDeleteSavedView(savedValue),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.adminTableDeleteViewAction),
        ),
      );
    }
    if (trailing != null) {
      filterActions.add(trailing!);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: filterActions,
            ),
            if (extraFilters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: extraFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminTableBulkBar extends StatelessWidget {
  const AdminTableBulkBar({
    super.key,
    required this.selectedCount,
    required this.actions,
    required this.onClear,
    this.child,
  });

  final int selectedCount;
  final List<AdminTableBulkAction> actions;
  final VoidCallback onClear;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();
    final bulkChildren = <Widget>[
      Text(
        context.l10n.adminTableBulkSelectionCount(selectedCount),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      for (final action in actions)
        action.primary
            ? FilledButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon),
                label: Text(action.label),
              )
            : OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon),
                label: Text(action.label),
              ),
    ];
    if (child != null) {
      bulkChildren.add(child!);
    }
    bulkChildren.add(
      TextButton(
        onPressed: onClear,
        child: Text(context.l10n.clear),
      ),
    );
    return Card(
      color: AppColors.primarySoft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: bulkChildren,
        ),
      ),
    );
  }
}

class AdminTableCard extends StatelessWidget {
  const AdminTableCard({
    super.key,
    required this.columns,
    required this.rows,
    required this.emptyLabel,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String emptyLabel;
  final int? sortColumnIndex;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              emptyLabel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        child: Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (_) => true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              headingRowHeight: 52,
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: columns,
              rows: rows,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminTablePaginationBar extends StatelessWidget {
  const AdminTablePaginationBar({
    super.key,
    required this.page,
    required this.rowsPerPage,
    required this.totalCount,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  final int page;
  final int rowsPerPage;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pageCount = totalCount == 0 ? 1 : ((totalCount - 1) ~/ rowsPerPage) + 1;
    final safePage = page.clamp(0, pageCount - 1);
    final start = totalCount == 0 ? 0 : (safePage * rowsPerPage) + 1;
    final end = totalCount == 0
        ? 0
        : ((safePage + 1) * rowsPerPage).clamp(0, totalCount);
    return Row(
      children: [
        Text(
          l10n.adminTablePageRange(start, end, totalCount),
          style: const TextStyle(color: AppColors.muted),
        ),
        const Spacer(),
        Text(l10n.adminTableRowsPerPageLabel),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: rowsPerPage,
          items: const [10, 20, 50]
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onRowsPerPageChanged(value);
          },
        ),
        IconButton(
          onPressed: safePage <= 0 ? null : () => onPageChanged(safePage - 1),
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.adminTablePrevPageAction,
        ),
        Text('${safePage + 1} / $pageCount'),
        IconButton(
          onPressed: safePage >= pageCount - 1
              ? null
              : () => onPageChanged(safePage + 1),
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.adminTableNextPageAction,
        ),
      ],
    );
  }
}

class AdminVirtualTableCard extends StatelessWidget {
  const AdminVirtualTableCard({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    required this.emptyLabel,
    this.headerHeight = 52,
    this.rowHeight = 72,
  });

  final List<AdminVirtualTableColumn> columns;
  final int rowCount;
  final IndexedWidgetBuilder rowBuilder;
  final String emptyLabel;
  final double headerHeight;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    if (rowCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              emptyLabel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
    }

    final tableWidth = columns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (_) => true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        color: AppColors.cardAlt,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            for (final column in columns)
                              Align(
                                alignment: column.alignment,
                                child: SizedBox(
                                  width: column.width,
                                  child: DefaultTextStyle(
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textStrong,
                                    ),
                                    child: column.label,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rowCount,
                          itemExtent: rowHeight,
                          cacheExtent: rowHeight * 12,
                          itemBuilder: (context, index) => rowBuilder(context, index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AdminVirtualTableRowView extends StatelessWidget {
  const AdminVirtualTableRowView({
    super.key,
    required this.columns,
    required this.row,
  });

  final List<AdminVirtualTableColumn> columns;
  final AdminVirtualTableRow row;

  @override
  Widget build(BuildContext context) {
    final background = row.selected ? AppColors.primarySoft : Colors.transparent;
    return InkWell(
      key: row.key,
      onTap: row.onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              Align(
                alignment: columns[i].alignment,
                child: SizedBox(
                  width: columns[i].width,
                  child: row.cells[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String?> promptAdminTableSavedViewLabel(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.adminTableSaveViewAction),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: ctx.l10n.adminTableViewNameLabel,
          hintText: ctx.l10n.adminTableViewNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(ctx.l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  final label = (result ?? '').trim();
  if (label.isEmpty) return null;
  return label;
}

String _fmtDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
