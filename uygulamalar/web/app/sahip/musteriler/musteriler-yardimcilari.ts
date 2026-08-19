export function zincirAciklamasiOlustur(zincirAdi: string | null): string {
  const temel = 'İşletmenizle etkileşimi olan tüm müşterileri görüntüleyin ve analiz edin.';
  if (!zincirAdi) return temel;
  return `${temel} Zincir çapında • ${zincirAdi}`;
}

export type MusteriTuru = 'sadik' | 'tekrar' | 'yeni' | 'tek_seferlik';

export const MUSTERI_TURU_ETIKETI: Record<MusteriTuru, string> = {
  sadik: 'Sadık Müşteri',
  tekrar: 'Tekrar Eden',
  yeni: 'Yeni Müşteri',
  tek_seferlik: 'Tek Seferlik',
};

const YENI_MUSTERI_GUN_ESIGI = 30;
const SADIK_ETKILESIM_ESIGI = 5;

export function toplamEtkilesim(m: {
  review_count: number;
  reservation_count: number;
  loyalty_event_count: number;
  is_following: boolean;
}): number {
  return m.review_count + m.reservation_count + m.loyalty_event_count + (m.is_following ? 1 : 0);
}

export function filtrelenmisMusteriler<T extends { display_name: string }>(musteriler: T[], aramaMetni: string): T[] {
  const normalize = (s: string) => s.toLocaleLowerCase('tr');
  const aranan = normalize(aramaMetni.trim());
  if (aranan === '') return musteriler;
  return musteriler.filter((m) => normalize(m.display_name).includes(aranan));
}

export function musteriTuruBelirle(m: {
  review_count: number;
  reservation_count: number;
  loyalty_event_count: number;
  loyalty_progress: number | null;
  is_following: boolean;
  first_interaction_at: string;
}): MusteriTuru {
  const toplam = toplamEtkilesim(m);
  const gunOnce = (Date.now() - new Date(m.first_interaction_at).getTime()) / 86400000;

  if (m.loyalty_progress !== null || toplam >= SADIK_ETKILESIM_ESIGI) return 'sadik';
  if (gunOnce <= YENI_MUSTERI_GUN_ESIGI) return 'yeni';
  if (toplam >= 2) return 'tekrar';
  return 'tek_seferlik';
}
