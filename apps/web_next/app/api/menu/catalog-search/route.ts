import { NextResponse } from 'next/server';
import { searchMenuCatalog } from '@/src/lib/menuCatalog';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const q = searchParams.get('q') ?? '';
  const limitRaw = Number(searchParams.get('limit') ?? 12);
  const limit = Number.isFinite(limitRaw)
    ? Math.max(1, Math.min(30, Math.trunc(limitRaw)))
    : 12;

  const items = searchMenuCatalog(q, limit);
  return NextResponse.json({ items });
}
