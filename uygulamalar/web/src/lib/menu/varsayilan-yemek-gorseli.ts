import { appConfig } from '@/src/lib/ayarlar';

/**
 * Ürün için sahip görsel yüklemediyse gösterilecek stok yemek fotoğrafı.
 * Kaynak: C:\yeedoy\assets\menu-kategroi-varsayilan (117 görsel, 800x800 webp),
 * `menu-media/varsayilan-yemekler/{klasor}/{slug}.webp` altında Storage'a yüklü.
 * Mobil karşılığı: uygulamalar/mobil/lib/features/menus/data/varsayilan_yemek_sozlugu.dart
 * — iki dosya da aynı klasör/slug listesini taşır, biri değişirse diğeri de güncellenmeli.
 */

const KATEGORI_KLASOR_ANAHTAR: Record<string, string[]> = {
  corbalar: ['corba'],
  'salata-meze': ['salata', 'meze', 'mezze'],
  sulu_yemekler: ['anayemek', 'suluyemek', 'evyemek', 'gununyemek', 'sicakyemek'],
  zeytinyaglilar: ['zeytinyagli', 'zeytinyag'],
};

const YEMEK_SOZLUGU: Record<string, string[]> = {
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

// Türkçe karakterleri sadeleştirip tüm boşluk/noktalama işaretlerini siler —
// "Karnıyarık", "karni_yarik" ve "Karnı Yarık" hepsi "karniyarik" olur, böylece
// sahiplerin yazım biçimi (bitişik/ayrık/alt çizgili) eşleşmeyi bozmaz.
function normalizeTr(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/ç/g, 'c')
    .replace(/ğ/g, 'g')
    .replace(/ı/g, 'i')
    .replace(/ö/g, 'o')
    .replace(/ş/g, 's')
    .replace(/ü/g, 'u')
    .replace(/[^a-z0-9]+/g, '');
}

function bulKlasor(kategoriAdi: string): string | null {
  const n = normalizeTr(kategoriAdi);
  for (const [klasor, anahtarlar] of Object.entries(KATEGORI_KLASOR_ANAHTAR)) {
    if (anahtarlar.some((a) => n.includes(a))) return klasor;
  }
  return null;
}

/**
 * Ürün adı ve (varsa) kategori adına göre stok yemek fotoğrafı URL'i döner.
 * Kategori 4 kapsanan gruptan birine (çorba/salata-meze/sulu yemek/zeytinyağlı)
 * eşleşmiyorsa veya ürün adı o grup içindeki hiçbir yemekle örtüşmüyorsa null
 * döner — çağıran taraf mevcut jenerik ikon/emoji fallback'ine düşmeli.
 */
export function bulVarsayilanYemekGorseli(
  urunAdi: string,
  kategoriAdi: string | null | undefined,
): string | null {
  if (!kategoriAdi) return null;
  const klasor = bulKlasor(kategoriAdi);
  if (!klasor) return null;

  const n = normalizeTr(urunAdi);
  if (!n) return null;

  const slugler = YEMEK_SOZLUGU[klasor] ?? [];
  const siraliSlugler = [...slugler].sort((a, b) => b.length - a.length);
  for (const slug of siraliSlugler) {
    const anahtar = normalizeTr(slug);
    if (n.includes(anahtar)) {
      return `${appConfig.supabaseUrl()}/storage/v1/object/public/menu-media/varsayilan-yemekler/${klasor}/${slug}.webp`;
    }
  }
  return null;
}
