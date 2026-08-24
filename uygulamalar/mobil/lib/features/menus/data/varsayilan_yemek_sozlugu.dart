/// Sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafını bulur.
///
/// Kaynak: DB-tabanlı `stock_dish_images` kütüphanesi (get_stock_dish_images_v1
/// RPC'siyle çekilir, bkz. menu_page.dart'taki _stockDishImagesProvider) —
/// admin panelinden (`/yonetici/gorsel-kutuphanesi`) yönetilir. Web
/// karşılığı: uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts —
/// aynı eşleştirme algoritması, ayrı Dart implementasyonu (Dart/TS runtime
/// paylaşımı mümkün olmadığı için).
class StockDishImage {
  const StockDishImage({
    required this.id,
    required this.imageUrl,
    required this.keywords,
  });

  final String id;
  final String imageUrl;
  final List<String> keywords;

  factory StockDishImage.fromMap(Map<String, dynamic> map) {
    return StockDishImage(
      id: (map['id'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      keywords: ((map['keywords'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class VarsayilanYemekSozlugu {
  const VarsayilanYemekSozlugu._();

  // Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler
  // — "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur,
  // böylece hem admin'in girdiği anahtar ifade hem sahibin yazım biçimi
  // (bitişik/ayrık) eşleşmeyi bozmaz.
  static String _normalize(String s) {
    var n = s.toLowerCase();
    n = n
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    return n.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  /// Ürün adına eşleşen en iyi (en uzun/özgül anahtar ifadeli) stok görselin
  /// URL'ini döner. Eşleşme yoksa null — çağıran taraf mevcut jenerik
  /// ikon/placeholder'a düşmeli.
  static String? bul(String urunAdi, List<StockDishImage> kutuphane) {
    final n = _normalize(urunAdi);
    if (n.isEmpty) return null;

    String? bestUrl;
    var bestLen = 0;
    for (final item in kutuphane) {
      for (final kw in item.keywords) {
        final nk = _normalize(kw);
        if (nk.isNotEmpty && n.contains(nk) && nk.length > bestLen) {
          bestLen = nk.length;
          bestUrl = item.imageUrl;
        }
      }
    }
    return bestUrl;
  }
}
