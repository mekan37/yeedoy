import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../data/admin_analytics_repository.dart';
import '../domain/admin_growth_models.dart';

class AdminGrowthPage extends ConsumerStatefulWidget {
  const AdminGrowthPage({super.key});

  @override
  ConsumerState<AdminGrowthPage> createState() => _AdminGrowthPageState();
}

class _AdminGrowthPageState extends ConsumerState<AdminGrowthPage> {
  int _days = 30;
  final _businessCtrl = TextEditingController();

  @override
  void dispose() {
    _businessCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = ref.watch(adminAnalyticsRepositoryProvider);
    final businessId = _businessCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.adminGrowthTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                tooltip: t.yenile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<int>(
                value: _days,
                items: [
                  DropdownMenuItem(value: 7, child: Text(t.adminGrowthLastDays(7))),
                  DropdownMenuItem(value: 30, child: Text(t.adminGrowthLastDays(30))),
                  DropdownMenuItem(value: 90, child: Text(t.adminGrowthLastDays(90))),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _days = v);
                },
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _businessCtrl,
                  decoration: InputDecoration(
                    labelText: t.adminGrowthBusinessIdOptional,
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              FilledButton(
                onPressed: () => setState(() {}),
                child: Text(t.apply),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AdminGrowthDay>>(
              future: repo.getGrowth(
                days: _days,
                businessId: businessId.isEmpty ? null : businessId,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      AppErrorMapper.message(snap.error),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  );
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Center(child: Text(t.adminGrowthNoData));
                }

                final totals = _sum(items);
                final today = items.isNotEmpty ? items.last : null;
                final todayTotal = today == null
                    ? 0
                    : today.menuLinkOpened +
                          today.qrScanned +
                          today.menuShared +
                          today.appInstallFromMenu;

                return ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: t.adminGrowthTodayBusinessTraffic,
                            value: '$todayTotal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.adminGrowthMenuLinkOpened,
                            value: '${totals.menuLinkOpened}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.adminGrowthQrScanned,
                            value: '${totals.qrScanned}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.adminGrowthMenuShared,
                            value: '${totals.menuShared}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: t.adminGrowthAppInstall,
                            value: '${totals.appInstallFromMenu}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.adminGrowthDailyTrafficTotal,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: _MiniLineChart(
                                values: items
                                    .map(
                                      (e) =>
                                          e.menuLinkOpened +
                                          e.qrScanned +
                                          e.menuShared +
                                          e.appInstallFromMenu,
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(t.adminGrowthDayColumn)),
                            DataColumn(label: Text(t.adminGrowthMenuLinkOpened)),
                            DataColumn(label: Text(t.adminGrowthQrScanned)),
                            DataColumn(label: Text(t.adminGrowthMenuShared)),
                            DataColumn(label: Text(t.adminGrowthAppInstall)),
                          ],
                          rows: [
                            for (final item in items)
                              DataRow(
                                cells: [
                                  DataCell(Text(_fmtDate(item.day))),
                                  DataCell(Text('${item.menuLinkOpened}')),
                                  DataCell(Text('${item.qrScanned}')),
                                  DataCell(Text('${item.menuShared}')),
                                  DataCell(Text('${item.appInstallFromMenu}')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AdminGrowthSummary _sum(List<AdminGrowthDay> items) {
    var menuLinkOpened = 0;
    var qrScanned = 0;
    var menuShared = 0;
    var appInstallFromMenu = 0;
    for (final item in items) {
      menuLinkOpened += item.menuLinkOpened;
      qrScanned += item.qrScanned;
      menuShared += item.menuShared;
      appInstallFromMenu += item.appInstallFromMenu;
    }
    return AdminGrowthSummary(
      menuLinkOpened: menuLinkOpened,
      qrScanned: qrScanned,
      menuShared: menuShared,
      appInstallFromMenu: appInstallFromMenu,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return CustomPaint(painter: _LinePainter(values), size: Size.infinite);
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxValue = max(1, values.reduce(max));
    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final v = values[i] / maxValue;
      final x = stepX * i;
      final y = size.height - (v * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

