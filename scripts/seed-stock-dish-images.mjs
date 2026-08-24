import fs from 'node:fs';

// uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts'teki YEMEK_SOZLUGU
// ile birebir aynı — bu Task 9'da bu dosyadaki statik sözlük kaldırılacağı
// için burada bir kez, kalıcı SQL veriye dönüştürülmek üzere kopyalanıyor.
const YEMEK_SOZLUGU = {
  corbalar: [
    'anali_kizli', 'arabasi', 'ayak_paca', 'balik', 'bamya', 'beyran', 'brokoli',
    'dil_paca', 'domates', 'dugun', 'ezogelin', 'iskembe', 'kelle_paca', 'kofte',
    'lebeniye', 'mahluta', 'mantar', 'maras_tarhanasi', 'mercimek', 'paca',
    'sehriye', 'siveydiz', 'tarhana', 'tavuk_suyu', 'tuzlama', 'yayla', 'yogurtlu',
  ],
  'salata-meze': [
    'acili_ezme', 'atom', 'babagannus', 'cacik', 'coban', 'deniz_borulcesi',
    'enginar', 'fava', 'gavurdagi', 'haydari', 'humus', 'kopoglu', 'koz_biber',
    'kozlenmis_patlican', 'kisir', 'lahana', 'mevsim', 'muhammara', 'pancar',
    'patates', 'piyaz', 'roka', 'saksuka', 'sezar', 'tarator', 'ton_balikli',
    'tursu', 'yesil', 'yogurtlu_semizotu', 'zeytinyagli_barbunya',
  ],
  sulu_yemekler: [
    'ali_nazik', 'bamya', 'bezelye_etli', 'coban_kavurma', 'dana_haslama',
    'eksili_kofte', 'et_sote', 'etli_guvec', 'etli_lahana', 'etli_nohut',
    'etli_patates', 'hunkar_begendi', 'islim_kebabi', 'ispanak', 'izmir_kofte',
    'kabak', 'kabak_oturtma', 'kapuska', 'karni_yarik', 'kereviz', 'kuru_fasulye',
    'musakka', 'nohut', 'orman_kebabi', 'patates_oturtma', 'patlican_kebabi',
    'pilav_ustu_kuru', 'pirasa', 'sac_kavurma', 'sebzeli_guvec', 'sulu_kofte',
    'tas_kebabi', 'tavuk_haslama', 'tavuk_sote', 'tavuk_yahni', 'taze_fasulye',
    'terbiyeli_kofte', 'turlu', 'yumurtali_ispanak',
  ],
  zeytinyaglilar: [
    'bakla', 'bamya', 'barbunya', 'bezelye', 'biber_dolmasi', 'biber_kizartmasi',
    'borulce', 'bruksel_lahanasi', 'enginar', 'imam_bayildi', 'kabak',
    'kabak_dolmasi', 'kabak_kizartmasi', 'karniyarik', 'kereviz', 'lahana_sarma',
    'patlican_dolmasi', 'patlican_kizartmasi', 'pirasa', 'taze_fasulye',
    'yaprak_sarma',
  ],
};

// Aynı slug birden fazla klasörde farklı fotoğrafla var (ör. "bamya" hem
// çorba hem sulu yemek hem zeytinyağlı) — flat (kategori-önsüzsüz) eşleştirmede
// çakışmayı önlemek için bu satırlara ayırt edici anahtar kelime veriliyor.
// Admin daha sonra "Görsel Kütüphanesi" sayfasından istediği gibi değiştirebilir.
const OVERRIDES = {
  'corbalar/bamya': 'bamya corbasi',
  'sulu_yemekler/bamya': 'etli bamya',
  'zeytinyaglilar/bamya': 'zeytinyagli bamya',
  'sulu_yemekler/kabak': 'kabak yemegi',
  'zeytinyaglilar/kabak': 'zeytinyagli kabak',
  'sulu_yemekler/kereviz': 'kereviz yemegi',
  'zeytinyaglilar/kereviz': 'zeytinyagli kereviz',
  'sulu_yemekler/pirasa': 'pirasa yemegi',
  'zeytinyaglilar/pirasa': 'zeytinyagli pirasa',
  'sulu_yemekler/taze_fasulye': 'taze fasulye yemegi',
  'zeytinyaglilar/taze_fasulye': 'zeytinyagli taze fasulye',
  'salata-meze/enginar': 'enginar salatasi',
  'zeytinyaglilar/enginar': 'zeytinyagli enginar',
};

const SUPABASE_URL = 'https://dktdnbeougrmhkzplbap.supabase.co';

function sqlEscape(s) {
  return s.replace(/'/g, "''");
}

const rows = [];
for (const [klasor, sluglar] of Object.entries(YEMEK_SOZLUGU)) {
  for (const slug of sluglar) {
    const key = `${klasor}/${slug}`;
    const keyword = OVERRIDES[key] ?? slug.replace(/_/g, ' ');
    const imageUrl = `${SUPABASE_URL}/storage/v1/object/public/menu-media/varsayilan-yemekler/${klasor}/${slug}.webp`;
    rows.push(`  ('${sqlEscape(imageUrl)}', ARRAY['${sqlEscape(keyword)}']::text[])`);
  }
}

const sql = `-- 117 mevcut stok görselinin (varsayilan-yemek-gorseli.ts / varsayilan_yemek_sozlugu.dart
-- statik sözlüklerinden taşınan) stock_dish_images tablosuna ilk yükleme migration'ı.
-- Dosyalar Supabase Storage'da (menu-media/varsayilan-yemekler/...) zaten duruyor,
-- yeniden yüklenmiyor — sadece katalog satırı olarak kaydediliyor.
INSERT INTO public.stock_dish_images (image_url, keywords) VALUES
${rows.join(',\n')}
ON CONFLICT DO NOTHING;
`;

fs.writeFileSync('supabase/migrations/20260824000006_seed_stock_dish_images.sql', sql);
console.log(`${rows.length} satır supabase/migrations/20260824000006_seed_stock_dish_images.sql dosyasına yazıldı.`);
