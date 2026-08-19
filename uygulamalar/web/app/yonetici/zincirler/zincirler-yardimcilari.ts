export interface ZincirSatiri {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  logoUrl: string | null;
  isVerified: boolean;
  templateBusinessName: string | null;
  activeBranchCount: number;
  createdAt: string;
}

export function zincirlerCsvOlustur(rows: ZincirSatiri[]): string {
  const basliklar = ['Zincir', 'Slug', 'Kategori', 'Aktif Şube', 'Şablon Şube', 'Doğrulama', 'Oluşturulma'];
  const satirlar = rows.map((r) => [
    r.name,
    r.slug ?? '',
    r.category ?? '',
    String(r.activeBranchCount),
    r.templateBusinessName ?? '',
    r.isVerified ? 'Onaylı' : 'Onaysız',
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
