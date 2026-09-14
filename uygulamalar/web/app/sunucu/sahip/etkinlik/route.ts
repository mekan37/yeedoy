import { NextResponse } from 'next/server';

// "Etkinlik" özelliği devre dışı — business_events tablosu hiçbir
// migration'da tanımlanmamış, her çağrı 500 dönüyordu (Sahip Paneli
// Güvenlik Denetimi P2). Ürün kararı: özellik geçici olarak kapatıldı.
export async function POST() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}

export async function PATCH() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
