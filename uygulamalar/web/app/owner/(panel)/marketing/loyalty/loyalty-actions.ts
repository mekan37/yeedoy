'use server';

export type LoyaltyActionResult = { ok: true } | { ok: false; error: string };

// MVP scope dışı: sadakat programı (loyalty) kapsam dışı bırakıldı
// (docs/engineering/2026-yeedoy-final-forbidden-scope-sweep.md). Kill-switch.
export async function upsertLoyaltyAction(
  _prevState: LoyaltyActionResult | null,
  _formData: FormData,
): Promise<LoyaltyActionResult> {
  return { ok: false, error: 'feature_disabled' };
}
