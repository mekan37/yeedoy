import { NextResponse } from 'next/server';

// Denetimde bulundu: üretilen anahtarları doğrulayan/tüketen hiçbir yer
// yoktu — özellik baştan sona dekoratifti. Canlıda 0 aktif anahtar vardı.
// push-kampanyalari ile aynı desenle geçici olarak kill-switch'lendi.
export async function POST() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}

export async function DELETE() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
