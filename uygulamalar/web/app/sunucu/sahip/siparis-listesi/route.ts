import { NextResponse } from 'next/server';

// MVP scope dışı: masa siparişi / POS kapsam dışı bırakıldı
// (docs/engineering/2026-yeedoy-final-forbidden-scope-sweep.md). Kill-switch.
export async function GET() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
