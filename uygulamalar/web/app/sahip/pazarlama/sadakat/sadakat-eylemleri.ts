'use server';

export type SadakatEylemSonucu = { ok: true } | { ok: false; error: string };

// MVP scope dışı: sadakat programı (loyalty) kapsam dışı bırakıldı
// (docs/engineering/2026-yeedoy-final-forbidden-scope-sweep.md). Kill-switch.
export async function upsertSadakatEylemi(
  _oncekiDurum: SadakatEylemSonucu | null,
  _formData: FormData,
): Promise<SadakatEylemSonucu> {
  return { ok: false, error: 'feature_disabled' };
}
