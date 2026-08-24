import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafını bulur.
///
/// Kaynak: C:\yeedoy\assets\menu-kategroi-varsayilan (117 görsel, 800x800
/// webp), `menu-media/varsayilan-yemekler/{klasor}/{slug}.webp` altında
/// Supabase Storage'a yüklü. Web karşılığı:
/// uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts — iki dosya da
/// aynı klasör/slug listesini taşır, biri değişirse diğeri de güncellenmeli.
class VarsayilanYemekSozlugu {
  const VarsayilanYemekSozlugu._();

  static const Map<String, List<String>> _kategoriKlasorAnahtar = {
    'corbalar': ['corba'],
    'salata-meze': ['salata', 'meze', 'mezze'],
    'sulu_yemekler': [
      'anayemek',
      'suluyemek',
      'evyemek',
      'gununyemek',
      'sicakyemek',
    ],
    'zeytinyaglilar': ['zeytinyagli', 'zeytinyag'],
  };

  static const Map<String, List<String>> _yemekSozlugu = {
    'corbalar': [
      'anali_kizli', 'arabasi', 'ayak_paca', 'balik', 'bamya', 'beyran',
      'brokoli', 'dil_paca', 'domates', 'dugun', 'ezogelin', 'iskembe',
      'kelle_paca', 'kofte', 'lebeniye', 'mahluta', 'mantar',
      'maras_tarhanasi', 'mercimek', 'paca', 'sehriye', 'siveydiz',
      'tarhana', 'tavuk_suyu', 'tuzlama', 'yayla', 'yogurtlu',
    ],
    'salata-meze': [
      'acili_ezme', 'atom', 'babagannus', 'cacik', 'coban',
      'deniz_borulcesi', 'enginar', 'fava', 'gavurdagi', 'haydari',
      'humus', 'kopoglu', 'koz_biber', 'kozlenmis_patlican', 'kisir',
      'lahana', 'mevsim', 'muhammara', 'pancar', 'patates', 'piyaz',
      'roka', 'saksuka', 'sezar', 'tarator', 'ton_balikli', 'tursu',
      'yesil', 'yogurtlu_semizotu', 'zeytinyagli_barbunya',
    ],
    'sulu_yemekler': [
      'ali_nazik', 'bamya', 'bezelye_etli', 'coban_kavurma',
      'dana_haslama', 'eksili_kofte', 'et_sote', 'etli_guvec',
      'etli_lahana', 'etli_nohut', 'etli_patates', 'hunkar_begendi',
      'islim_kebabi', 'ispanak', 'izmir_kofte', 'kabak', 'kabak_oturtma',
      'kapuska', 'karni_yarik', 'kereviz', 'kuru_fasulye', 'musakka',
      'nohut', 'orman_kebabi', 'patates_oturtma', 'patlican_kebabi',
      'pilav_ustu_kuru', 'pirasa', 'sac_kavurma', 'sebzeli_guvec',
      'sulu_kofte', 'tas_kebabi', 'tavuk_haslama', 'tavuk_sote',
      'tavuk_yahni', 'taze_fasulye', 'terbiyeli_kofte', 'turlu',
      'yumurtali_ispanak',
    ],
    'zeytinyaglilar': [
      'bakla', 'bamya', 'barbunya', 'bezelye', 'biber_dolmasi',
      'biber_kizartmasi', 'borulce', 'bruksel_lahanasi', 'enginar',
      'imam_bayildi', 'kabak', 'kabak_dolmasi', 'kabak_kizartmasi',
      'karniyarik', 'kereviz', 'lahana_sarma', 'patlican_dolmasi',
      'patlican_kizartmasi', 'pirasa', 'taze_fasulye', 'yaprak_sarma',
    ],
  };

  // Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler
  // — "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur,
  // böylece sahiplerin yazım biçimi (bitişik/ayrık/alt çizgili) eşleşmeyi
  // bozmaz.
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

  static String? _bulKlasor(String kategoriAdi) {
    final n = _normalize(kategoriAdi);
    for (final entry in _kategoriKlasorAnahtar.entries) {
      if (entry.value.any((a) => n.contains(a))) return entry.key;
    }
    return null;
  }

  /// Ürün adı ve (varsa) kategori adına göre stok yemek fotoğrafı URL'i
  /// döner. Kategori 4 kapsanan gruptan birine (çorba/salata-meze/sulu
  /// yemek/zeytinyağlı) eşleşmiyorsa veya ürün adı o grup içindeki hiçbir
  /// yemekle örtüşmüyorsa null döner — çağıran taraf mevcut jenerik
  /// ikon/placeholder'a düşmeli.
  static String? bul(String urunAdi, String? kategoriAdi) {
    if (kategoriAdi == null || kategoriAdi.trim().isEmpty) return null;
    final klasor = _bulKlasor(kategoriAdi);
    if (klasor == null) return null;

    final n = _normalize(urunAdi);
    if (n.isEmpty) return null;

    final slugler = List<String>.from(_yemekSozlugu[klasor] ?? const []);
    slugler.sort((a, b) => b.length.compareTo(a.length));
    for (final slug in slugler) {
      final anahtar = _normalize(slug);
      if (n.contains(anahtar)) {
        final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').replaceAll(
          RegExp(r'/$'),
          '',
        );
        if (supabaseUrl.isEmpty) return null;
        return '$supabaseUrl/storage/v1/object/public/menu-media/varsayilan-yemekler/$klasor/$slug.webp';
      }
    }
    return null;
  }
}
