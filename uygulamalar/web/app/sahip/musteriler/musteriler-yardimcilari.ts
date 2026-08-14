export function zincirAciklamasiOlustur(zincirAdi: string | null): string {
  const temel = 'İşletmenizle etkileşimi olan tüm müşteriler';
  if (!zincirAdi) return temel;
  return `${temel} — Zincir çapında • ${zincirAdi}`;
}
