import { NextResponse } from 'next/server';

// MVP scope dışı: owner-broadcast pazarlama bildirimleri kapsam dışı bırakıldı. Kill-switch.
export async function POST() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
