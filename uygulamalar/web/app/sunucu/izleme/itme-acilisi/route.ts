import { NextResponse } from 'next/server';

// MVP scope dışı: pazarlama otomasyonu (push bildirim kampanyaları) kapsam dışı bırakıldı
// (docs/arsiv/2026-yeedoy-final-forbidden-scope-sweep.md). Kill-switch.
export async function POST() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
