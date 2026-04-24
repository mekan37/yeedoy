import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

class OwnerGrowthDayRow {
  const OwnerGrowthDayRow({
    required this.day,
    required this.menuViews,
    required this.qrScans,
    required this.outboundClicks,
  });

  final DateTime day;
  final int menuViews;
  final int qrScans;
  final int outboundClicks;
}

final ownerGrowthSeriesProvider =
    FutureProvider.family<List<OwnerGrowthDayRow>, String?>((
      ref,
      businessId,
    ) async {
      if (businessId == null || businessId.trim().isEmpty) return const [];
      final client = ref.watch(supabaseProvider);
      try {
        final res = await client.rpc(
          'analytics_growth_v3',
          params: {'p_days': 30, 'p_business_id': businessId},
        );
        final rows = (res as List?) ?? const [];
        return rows.whereType<Map>().map((r) {
          final map = r.cast<String, dynamic>();
          final dayRaw = map['day'];
          final day = dayRaw is String
              ? DateTime.tryParse(dayRaw) ?? DateTime.now()
              : DateTime.now();
          final menuViews = (map['menu_link_opened'] as num?)?.toInt() ?? 0;
          final qrScans = (map['qr_scanned'] as num?)?.toInt() ?? 0;
          final outboundClicks =
              ((map['business_reservation_click'] as num?)?.toInt() ?? 0) +
              ((map['business_order_click'] as num?)?.toInt() ?? 0) +
              ((map['business_phone_click'] as num?)?.toInt() ?? 0) +
              ((map['business_whatsapp_click'] as num?)?.toInt() ?? 0);
          return OwnerGrowthDayRow(
            day: day,
            menuViews: menuViews,
            qrScans: qrScans,
            outboundClicks: outboundClicks,
          );
        }).toList()
          ..sort((a, b) => a.day.compareTo(b.day));
      } catch (_) {
        return const [];
      }
    });

class OwnerGrowthSummary {
  const OwnerGrowthSummary({
    required this.menuViews,
    required this.qrScans,
    required this.searchImpressions,
    required this.conversions,
    required this.outboundClicks,
    required this.reservationClicks,
    required this.orderClicks,
    required this.priceDropoffEstimate,
    required this.districtPriceGapPct,
    required this.districtPricePosition,
  });

  final int menuViews;
  final int qrScans;
  final int searchImpressions;
  final int conversions;
  final int outboundClicks;
  final int reservationClicks;
  final int orderClicks;
  final int priceDropoffEstimate;
  final double? districtPriceGapPct;
  final String districtPricePosition;
}

final ownerGrowthSummaryProvider =
    FutureProvider.family<OwnerGrowthSummary?, String?>((
      ref,
      businessId,
    ) async {
      if (businessId == null || businessId.trim().isEmpty) return null;
      final client = ref.watch(supabaseProvider);
      try {
        dynamic res;
        try {
          res = await client.rpc(
            'analytics_growth_v3',
            params: {'p_days': 30, 'p_business_id': businessId},
          );
        } catch (_) {
          res = await client.rpc(
            'analytics_growth_v2',
            params: {'p_days': 30, 'p_business_id': businessId},
          );
        }
        final rows = (res as List?) ?? const [];
        var menuViews = 0;
        var qrScans = 0;
        var menuShared = 0;
        var appInstall = 0;
        var reservationClicks = 0;
        var orderClicks = 0;
        var phoneClicks = 0;
        var whatsappClicks = 0;
        var priceDropoffEstimate = 0;
        var districtPriceGapPct = 0.0;
        var districtPriceGapSamples = 0;
        var districtPricePosition = 'unknown';
        for (final row in rows.whereType<Map>()) {
          final map = row.cast<String, dynamic>();
          menuViews += (map['menu_link_opened'] as num?)?.toInt() ?? 0;
          qrScans += (map['qr_scanned'] as num?)?.toInt() ?? 0;
          menuShared += (map['menu_shared'] as num?)?.toInt() ?? 0;
          appInstall += (map['app_install_from_menu'] as num?)?.toInt() ?? 0;
          reservationClicks +=
              (map['business_reservation_click'] as num?)?.toInt() ?? 0;
          orderClicks += (map['business_order_click'] as num?)?.toInt() ?? 0;
          phoneClicks += (map['business_phone_click'] as num?)?.toInt() ?? 0;
          whatsappClicks +=
              (map['business_whatsapp_click'] as num?)?.toInt() ?? 0;
          priceDropoffEstimate +=
              (map['price_dropoff_estimate'] as num?)?.toInt() ?? 0;
          final gap = (map['district_price_gap_pct'] as num?)?.toDouble();
          if (gap != null) {
            districtPriceGapPct += gap;
            districtPriceGapSamples += 1;
          }
          final pos = (map['district_price_position'] ?? '').toString().trim();
          if (pos.isNotEmpty && pos != 'unknown') {
            districtPricePosition = pos;
          }
        }
        final outboundClicks =
            reservationClicks + orderClicks + phoneClicks + whatsappClicks;
        final avgGap = districtPriceGapSamples > 0
            ? districtPriceGapPct / districtPriceGapSamples
            : null;
        return OwnerGrowthSummary(
          menuViews: menuViews,
          qrScans: qrScans,
          searchImpressions: menuShared,
          conversions: appInstall,
          outboundClicks: outboundClicks,
          reservationClicks: reservationClicks,
          orderClicks: orderClicks,
          priceDropoffEstimate: priceDropoffEstimate,
          districtPriceGapPct: avgGap,
          districtPricePosition: districtPricePosition,
        );
      } catch (e) {
        try {
          final res = await client.rpc(
            'analytics_growth_v1',
            params: {'p_days': 30, 'p_business_id': businessId},
          );
          final rows = (res as List?) ?? const [];
          var menuViews = 0;
          var qrScans = 0;
          var menuShared = 0;
          var appInstall = 0;
          for (final row in rows.whereType<Map>()) {
            final map = row.cast<String, dynamic>();
            menuViews += (map['menu_link_opened'] as num?)?.toInt() ?? 0;
            qrScans += (map['qr_scanned'] as num?)?.toInt() ?? 0;
            menuShared += (map['menu_shared'] as num?)?.toInt() ?? 0;
            appInstall += (map['app_install_from_menu'] as num?)?.toInt() ?? 0;
          }
          return OwnerGrowthSummary(
            menuViews: menuViews,
            qrScans: qrScans,
            searchImpressions: menuShared,
            conversions: appInstall,
            outboundClicks: 0,
            reservationClicks: 0,
            orderClicks: 0,
            priceDropoffEstimate: 0,
            districtPriceGapPct: null,
            districtPricePosition: 'unknown',
          );
        } catch (_) {
          throw Exception(AppErrorMapper.message(e));
        }
      }
    });
