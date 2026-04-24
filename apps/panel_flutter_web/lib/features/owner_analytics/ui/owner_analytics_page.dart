import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac.dart';
import '../../../shared/ui/components/app_card.dart';
import '../../../shared/ui/components/app_filter_chip.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../owner_businesses/domain/owner_business_models.dart';
import '../../owner_businesses/domain/owner_business_providers.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../data/owner_analytics_repository.dart';
import '../domain/owner_analytics_models.dart';

final _ownerAnalyticsSnapshotProvider =
    FutureProvider.autoDispose.family<OwnerAnalyticsSnapshot, (String, int, bool)>((
      ref,
      args,
    ) {
      return ref.read(ownerAnalyticsRepositoryProvider).fetchAnalytics(
            businessId: args.$1,
            days: args.$2,
            compareBranches: args.$3,
          );
    });

final _ownerAnalyticsHourlyProvider =
    FutureProvider.autoDispose.family<OwnerAnalyticsHourlySnapshot, String>((
      ref,
      businessId,
    ) {
      return ref.read(ownerAnalyticsRepositoryProvider).fetchAnalyticsHourly(
            businessId: businessId,
          );
    });

class OwnerAnalyticsPage extends ConsumerStatefulWidget {
  const OwnerAnalyticsPage({super.key, this.businessId});

  final String? businessId;

  @override
  ConsumerState<OwnerAnalyticsPage> createState() => _OwnerAnalyticsPageState();
}

class _OwnerAnalyticsPageState extends ConsumerState<OwnerAnalyticsPage> {
  int _days = 30;
  bool _compareBranches = false;
  bool _showHourly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedBusinessId = (widget.businessId ?? '').trim().isNotEmpty
        ? widget.businessId!.trim()
        : (ref.watch(selectedOwnerBusinessIdProvider) ?? '');
    if (selectedBusinessId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.empty(
          icon: Icons.analytics_outlined,
          title: l10n.ownerAnalyticsMissingBusinessTitle,
          description: l10n.ownerAnalyticsMissingBusinessDescription,
        ),
      );
    }

    final canReadAsync = ref.watch(
      hasBusinessPermissionProvider((
        selectedBusinessId,
        BusinessPermission.businessRead,
      )),
    );
    final businessesAsync = ref.watch(ownerBusinessesProvider);

    final canRead = canReadAsync.when<bool?>(
      loading: () => null,
      error: (_, _) => false,
      data: (value) => value,
    );
    if (canRead == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: OwnerPanelFeedback.loading(cardCount: 4),
      );
    }
    if (!canRead) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.error(
          title: l10n.ownerAnalyticsForbiddenTitle,
          description: l10n.ownerAnalyticsForbiddenDescription,
        ),
      );
    }

    return businessesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: OwnerPanelFeedback.loading(cardCount: 5),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.error(
          title: l10n.ownerAnalyticsErrorTitle,
          description: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(ownerBusinessesProvider),
        ),
      ),
      data: (businesses) {
        final selectedBusiness = _findBusiness(businesses, selectedBusinessId);
        final branchCompareAvailable = _branchCompareAvailable(
          businesses,
          selectedBusiness,
        );
        final snapshotAsync = ref.watch(
          _ownerAnalyticsSnapshotProvider((
            selectedBusinessId,
            _days,
            _compareBranches && branchCompareAvailable,
          )),
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownerBusinessesProvider);
            ref.invalidate(
              _ownerAnalyticsSnapshotProvider((
                selectedBusinessId,
                _days,
                _compareBranches && branchCompareAvailable,
              )),
            );
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PanelPageHeader(
                eyebrow: 'Owner',
                title: Text(l10n.ownerAnalyticsTitle),
                description: l10n.ownerAnalyticsDescription,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                AppCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PresetChip(
                      label: l10n.ownerAnalyticsPreset24Hours,
                      selected: _showHourly,
                      onTap: () => setState(() => _showHourly = true),
                    ),
                    _PresetChip(
                      label: l10n.ownerAnalyticsPreset7Days,
                      selected: !_showHourly && _days == 7,
                      onTap: () => setState(() { _showHourly = false; _days = 7; }),
                    ),
                    _PresetChip(
                      label: l10n.ownerAnalyticsPreset30Days,
                      selected: !_showHourly && _days == 30,
                      onTap: () => setState(() { _showHourly = false; _days = 30; }),
                    ),
                    _PresetChip(
                      label: l10n.ownerAnalyticsPreset90Days,
                      selected: !_showHourly && _days == 90,
                      onTap: () => setState(() { _showHourly = false; _days = 90; }),
                    ),
                    if (branchCompareAvailable)
                      FilterChip(
                        selected: _compareBranches,
                        label: Text(l10n.ownerAnalyticsBranchCompareToggle),
                        onSelected: (value) =>
                            setState(() => _compareBranches = value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_showHourly)
                ref.watch(_ownerAnalyticsHourlyProvider(selectedBusinessId)).when(
                  loading: () => const OwnerPanelFeedback.loading(cardCount: 4),
                  error: (error, _) => OwnerPanelFeedback.error(
                    title: l10n.ownerAnalyticsErrorTitle,
                    description: AppErrorMapper.message(error),
                    onRetry: () => ref.invalidate(
                      _ownerAnalyticsHourlyProvider(selectedBusinessId),
                    ),
                  ),
                  data: (hourlySnapshot) => Column(
                    children: [
                      _KpiGrid(summary: hourlySnapshot.summary),
                      const SizedBox(height: 12),
                      _HourlyTrendCard(points: hourlySnapshot.hourly),
                    ],
                  ),
                )
              else
              snapshotAsync.when(
                loading: () => const OwnerPanelFeedback.loading(cardCount: 6),
                error: (error, _) => OwnerPanelFeedback.error(
                  title: l10n.ownerAnalyticsErrorTitle,
                  description: AppErrorMapper.message(error),
                  onRetry: () => ref.invalidate(
                    _ownerAnalyticsSnapshotProvider((
                      selectedBusinessId,
                      _days,
                      _compareBranches && branchCompareAvailable,
                    )),
                  ),
                ),
                data: (snapshot) => Column(
                  children: [
                    _KpiGrid(summary: snapshot.summary),
                    const SizedBox(height: 12),
                    _DailyTrendCard(
                      days: _days,
                      points: snapshot.daily,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 980;
                        final itemsCard = _RankedCard(
                          title: l10n.ownerAnalyticsTopItemsTitle,
                          emptyTitle: l10n.ownerAnalyticsNoItemDataTitle,
                          emptyDescription:
                              l10n.ownerAnalyticsNoItemDataDescription,
                          rows: snapshot.topItems,
                        );
                        final categoriesCard = _RankedCard(
                          title: l10n.ownerAnalyticsTopCategoriesTitle,
                          emptyTitle: l10n.ownerAnalyticsNoCategoryDataTitle,
                          emptyDescription:
                              l10n.ownerAnalyticsNoCategoryDataDescription,
                          rows: snapshot.topCategories,
                        );
                        if (!wide) {
                          return Column(
                            children: [
                              itemsCard,
                              const SizedBox(height: 12),
                              categoriesCard,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: itemsCard),
                            const SizedBox(width: 12),
                            Expanded(child: categoriesCard),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 980;
                        final sourcesCard = _RankedCard(
                          title: l10n.ownerAnalyticsSourceBreakdownTitle,
                          emptyTitle: l10n.ownerAnalyticsNoSourceDataTitle,
                          emptyDescription:
                              l10n.ownerAnalyticsNoSourceDataDescription,
                          rows: snapshot.sourceBreakdown,
                          labelMapper: _sourceLabel,
                        );
                        final branchCard = _BranchCompareCard(
                          rows: snapshot.branchCompare,
                        );
                        if (!_compareBranches || !branchCompareAvailable) {
                          return sourcesCard;
                        }
                        if (!wide) {
                          return Column(
                            children: [
                              sourcesCard,
                              const SizedBox(height: 12),
                              branchCard,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: sourcesCard),
                            const SizedBox(width: 12),
                            Expanded(child: branchCard),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  OwnerBusiness? _findBusiness(List<OwnerBusiness> items, String businessId) {
    for (final item in items) {
      if (item.businessId == businessId) return item;
    }
    return null;
  }

  bool _branchCompareAvailable(
    List<OwnerBusiness> items,
    OwnerBusiness? selectedBusiness,
  ) {
    final chainId = selectedBusiness?.chainId;
    if (chainId == null || chainId.isEmpty) return false;
    return items.where((item) => item.chainId == chainId).length > 1;
  }

  String _sourceLabel(BuildContext context, String value) {
    return switch (value) {
      'qr_short_link' => context.l10n.ownerAnalyticsSourceQrShortLink,
      'normal' => context.l10n.ownerAnalyticsSourceNormal,
      'qr' => context.l10n.ownerAnalyticsSourceQrShortLink,
      _ => value,
    };
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(label: label, selected: selected, onTap: onTap);
  }
}

class _HourlyTrendCard extends StatelessWidget {
  const _HourlyTrendCard({required this.points});

  final List<OwnerAnalyticsHourlyPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      1,
      (prev, item) => [prev, item.menuOpens, item.qrScans].reduce((a, b) => a > b ? a : b),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ownerAnalyticsHourlyTrendTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            Text(
              context.l10n.ownerAnalyticsNoTrendDataDescription,
              style: const TextStyle(color: AppColors.muted),
            )
          else
            Column(
              children: [
                for (final point in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${point.hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _MetricBar(
                            color: AppColors.primary,
                            value: point.menuOpens,
                            max: maxValue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${point.menuOpens}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final OwnerAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = <Widget>[
      _KpiCard(
        icon: Icons.qr_code_scanner_rounded,
        iconColor: AppColors.info,
        title: l10n.ownerAnalyticsQrScansTitle,
        value: '${summary.qrScans}',
      ),
      _KpiCard(
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.primary,
        title: l10n.ownerAnalyticsMenuOpensTitle,
        value: '${summary.menuOpens}',
      ),
      _KpiCard(
        icon: Icons.category_rounded,
        iconColor: AppColors.success,
        title: l10n.ownerAnalyticsCategoryViewsTitle,
        value: '${summary.categoryViews}',
      ),
      _KpiCard(
        icon: Icons.touch_app_rounded,
        iconColor: AppColors.warning,
        title: l10n.ownerAnalyticsItemClicksTitle,
        value: '${summary.itemClicks}',
      ),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DailyTrendCard extends StatelessWidget {
  const _DailyTrendCard({
    required this.days,
    required this.points,
  });

  final int days;
  final List<OwnerAnalyticsDailyPoint> points;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.ownerAnalyticsDailyTrendTitle(days),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ChartLegend(color: AppColors.primary, label: 'Menü açılışı'),
              const SizedBox(width: 12),
              _ChartLegend(color: AppColors.info, label: 'QR tarama'),
            ],
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            Text(
              context.l10n.ownerAnalyticsNoTrendDataDescription,
              style: const TextStyle(color: AppColors.muted),
            )
          else
            SizedBox(
              height: 160,
              child: _AnalyticsLineChart(
                points: points,
                primaryValue: (p) => p.menuOpens,
                secondaryValue: (p) => p.qrScans,
                xLabel: (p) => p.day.length >= 10 ? p.day.substring(5) : p.day,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _AnalyticsLineChart extends StatelessWidget {
  const _AnalyticsLineChart({
    required this.points,
    required this.primaryValue,
    required this.secondaryValue,
    required this.xLabel,
  });

  final List<OwnerAnalyticsDailyPoint> points;
  final int Function(OwnerAnalyticsDailyPoint) primaryValue;
  final int Function(OwnerAnalyticsDailyPoint) secondaryValue;
  final String Function(OwnerAnalyticsDailyPoint) xLabel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnalyticsLinePainter(
        points: points,
        primaryValue: primaryValue,
        secondaryValue: secondaryValue,
        xLabel: xLabel,
        primaryColor: AppColors.primary,
        secondaryColor: AppColors.info,
        gridColor: AppColors.border,
        labelColor: AppColors.muted,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AnalyticsLinePainter extends CustomPainter {
  const _AnalyticsLinePainter({
    required this.points,
    required this.primaryValue,
    required this.secondaryValue,
    required this.xLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<OwnerAnalyticsDailyPoint> points;
  final int Function(OwnerAnalyticsDailyPoint) primaryValue;
  final int Function(OwnerAnalyticsDailyPoint) secondaryValue;
  final String Function(OwnerAnalyticsDailyPoint) xLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color labelColor;

  static const double _leftPad = 40;
  static const double _bottomPad = 24;
  static const double _rightPad = 8;
  static const double _topPad = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;

    final maxVal = points.fold<int>(1, (m, p) {
      final v = [primaryValue(p), secondaryValue(p)];
      return v.fold(m, (a, b) => b > a ? b : a);
    });

    double xOf(int i) => _leftPad + i * chartW / (points.length - 1);
    double yOf(int v) => _topPad + chartH * (1 - v / maxVal);

    // Grid lines + Y labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: labelColor, fontSize: 10);

    const gridCount = 4;
    for (var i = 0; i <= gridCount; i++) {
      final y = _topPad + chartH * i / gridCount;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width - _rightPad, y),
          gridPaint);
      final val = (maxVal * (1 - i / gridCount)).round();
      _drawText(canvas, '$val', Offset(0, y - 6), labelStyle, width: 36);
    }

    // X axis labels — show up to 7 evenly
    final step = (points.length / 6).ceil().clamp(1, points.length);
    for (var i = 0; i < points.length; i += step) {
      final x = xOf(i);
      _drawText(
        canvas,
        xLabel(points[i]),
        Offset(x - 20, size.height - _bottomPad + 5),
        labelStyle,
        width: 40,
        center: true,
      );
    }

    // Draw series
    _drawSeries(canvas, points, secondaryValue, xOf, yOf, secondaryColor,
        fill: false);
    _drawSeries(canvas, points, primaryValue, xOf, yOf, primaryColor,
        fill: true);
  }

  void _drawSeries(
    Canvas canvas,
    List<OwnerAnalyticsDailyPoint> pts,
    int Function(OwnerAnalyticsDailyPoint) val,
    double Function(int) xOf,
    double Function(int) yOf,
    Color color, {
    required bool fill,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = xOf(i);
      final y = yOf(val(pts[i]));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(xOf(pts.length - 1), _topPad + (yOf(0) - _topPad + _bottomPad))
        ..lineTo(xOf(0), _topPad + (yOf(0) - _topPad + _bottomPad))
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, _topPad, 1, yOf(0) - _topPad)),
      );
    }

    // Dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(val(pts[i]))), 3, dotPaint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double width,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final dx = center ? offset.dx + (width - tp.width) / 2 : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_AnalyticsLinePainter old) =>
      old.points != points || old.primaryColor != primaryColor;
}

class _RankedCard extends StatelessWidget {
  const _RankedCard({
    required this.title,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.rows,
    this.labelMapper,
  });

  final String title;
  final String emptyTitle;
  final String emptyDescription;
  final List<OwnerAnalyticsCountRow> rows;
  final String Function(BuildContext context, String value)? labelMapper;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<int>(1, (prev, item) => item.count > prev ? item.count : prev);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            OwnerPanelFeedback.empty(
              icon: Icons.insights_outlined,
              title: emptyTitle,
              description: emptyDescription,
            )
          else
            Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            (labelMapper?.call(context, rows[i].label) ??
                                    rows[i].label)
                                .trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: _MetricBar(
                            color: AppColors.info,
                            value: rows[i].count,
                            max: maxValue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${rows[i].count}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BranchCompareCard extends StatelessWidget {
  const _BranchCompareCard({required this.rows});

  final List<OwnerAnalyticsBranchRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ownerAnalyticsBranchCompareTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            OwnerPanelFeedback.empty(
              icon: Icons.compare_arrows_outlined,
              title: context.l10n.ownerAnalyticsBranchCompareEmptyTitle,
              description:
                  context.l10n.ownerAnalyticsBranchCompareEmptyDescription,
            )
          else
            Column(
              children: [
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: row.selected
                          ? AppColors.primarySoft
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: row.selected
                            ? AppColors.borderStrong
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.ownerAnalyticsBranchCompareMetrics(
                            row.menuOpens,
                            row.qrScans,
                            row.menuViews,
                          ),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.color,
    required this.value,
    required this.max,
  });

  final Color color;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 10,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
