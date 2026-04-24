import 'package:home_widget/home_widget.dart';

import '../../features/discovery/domain/business_card.dart';

class HomeWidgetService {
  static const String _androidProviderName =
      'com.yeedoy.app.YeedoyWidgetProvider';

  static Future<void> update(List<BusinessCardModel> nearby) async {
    if (nearby.isEmpty) return;

    final top = nearby.first;
    final price = top.medianPriceCents != null
        ? '~${(top.medianPriceCents! / 100).round()}₺'
        : null;

    final parts = <String>[
      ?top.district ?? top.city,
      if (top.avgRating != null) '★${top.avgRating!.toStringAsFixed(1)}',
      ?price,
    ];

    final subtitle = parts.isNotEmpty
        ? parts.join(' · ')
        : 'Yakındaki mekanları keşfet';

    await HomeWidget.saveWidgetData('widget_business_name', top.name);
    await HomeWidget.saveWidgetData('widget_subtitle', subtitle);
    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }

  static Future<void> clear() async {
    await HomeWidget.saveWidgetData<String?>('widget_business_name', null);
    await HomeWidget.saveWidgetData<String?>(
        'widget_subtitle', 'Yakındaki mekanları keşfet');
    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }
}
