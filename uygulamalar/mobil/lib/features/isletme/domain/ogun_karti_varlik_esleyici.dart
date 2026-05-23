import 'ogun_karti_saglayici_secenegi.dart';

class MealCardAssetMapper {
  static const String _basePath = 'assets/meal_cards/';

  static String assetPathForKey(String key) {
    switch (key.trim().toLowerCase()) {
      case 'multinet':
        return '${_basePath}meal_card_multinet.png';
      case 'edenred':
        return '${_basePath}meal_card_edenred.png';
      case 'tokenflex':
        return '${_basePath}meal_card_tokenflex.png';
      case 'setcard':
        return '${_basePath}meal_card_setcard.png';
      case 'pluxee':
        return '${_basePath}meal_card_pluxee.png';
      case 'metropol':
        return '${_basePath}meal_card_metropol.png';
      case 'yemekmatik':
        return '${_basePath}meal_card_yemekmatik.png';
      default:
        return '${_basePath}meal_card_multinet.png';
    }
  }

  static String assetPathForProvider(MealCardProviderOption provider) {
    final assetName = provider.assetName.trim();
    if (assetName.isNotEmpty) {
      return '$_basePath$assetName';
    }
    return assetPathForKey(provider.key);
  }
}


