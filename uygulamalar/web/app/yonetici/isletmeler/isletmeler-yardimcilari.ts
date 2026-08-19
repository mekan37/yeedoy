export interface IsletmeSatiri {
  id: string;
  name: string;
  slug: string | null;
  public_slug: string | null;
  category: string;
  city: string | null;
  district: string | null;
  phone: string | null;
  logoUrl: string | null;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  ownerName: string | null;
}

export function getPublicBusinessHref(b: { public_slug: string | null; slug: string | null }): string | null {
  const slug = b.public_slug ?? b.slug;
  return slug ? `/isletme/${encodeURIComponent(slug)}` : null;
}

export function isletmelerCsvOlustur(rows: IsletmeSatiri[]): string {
  const basliklar = ['İşletme', 'Kategori', 'Şehir', 'İlçe', 'Telefon', 'Sahip', 'Durum', 'Doğrulama', 'Kayıt Tarihi'];
  const satirlar = rows.map((r) => [
    r.name,
    r.category,
    r.city ?? '',
    r.district ?? '',
    r.phone ?? '',
    r.ownerName ?? '',
    r.is_active ? 'Aktif' : 'Pasif',
    r.is_verified ? 'Doğrulandı' : 'Doğrulanmadı',
    new Date(r.created_at).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
