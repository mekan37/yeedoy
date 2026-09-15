import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';

const MAX_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']);

// İstemcinin beyan ettiği Content-Type sahtelenebilir — ilk baytlar (magic
// number) beyan edilen türle eşleşmiyorsa reddedilir. Aynı desen S-1'de
// (medya/yukleme-yardimcisi.ts) kuruldu; bu route PDF de kabul ettiği ve
// public değil signed-URL/private bucket kullandığı için o helper'ı doğrudan
// çağırmak yerine aynı kontrolü burada tekrarlıyor.
async function magicBytesEslesiyorMu(file: File, mimeType: string): Promise<boolean> {
  const head = new Uint8Array(await file.slice(0, 8).arrayBuffer());
  const startsWith = (bytes: number[]) => bytes.every((b, i) => head[i] === b);
  switch (mimeType) {
    case 'image/jpeg':
    case 'image/jpg':
      return startsWith([0xff, 0xd8, 0xff]);
    case 'image/png':
      return startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    case 'image/webp':
      return startsWith([0x52, 0x49, 0x46, 0x46]); // 'RIFF' (WEBP imzası bayt 8-11'de, 8 baytlık head'i aşar — RIFF yeterli ayırt edici)
    case 'application/pdf':
      return startsWith([0x25, 0x50, 0x44, 0x46]); // '%PDF'
    default:
      return false;
  }
}

export async function POST(request: NextRequest) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Giriş yapmanız gerekiyor.' }, { status: 401 });
  }

  // Sahiplik kanıtı yükleme nadir bir işlemdir — dakikada 5 yeterince
  // cömert, kötüye kullanımı (depolama maliyeti / spam) sınırlar.
  const rl = await rateLimit(`sahiplik-kaniti:${user.id}`, 5, 60_000);
  if (!rl.ok) {
    return NextResponse.json({ error: 'rate_limited' }, { status: 429 });
  }

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json({ error: 'Form verisi okunamadı.' }, { status: 400 });
  }

  const file = formData.get('file') as File | null;
  if (!file) {
    return NextResponse.json({ error: 'Dosya bulunamadı.' }, { status: 400 });
  }

  if (file.size > MAX_SIZE) {
    return NextResponse.json({ error: 'Dosya 10 MB\'tan büyük olamaz.' }, { status: 400 });
  }

  if (!ALLOWED_TYPES.has(file.type)) {
    return NextResponse.json({ error: 'Sadece PDF, JPG ve PNG dosyaları kabul edilir.' }, { status: 400 });
  }

  if (!(await magicBytesEslesiyorMu(file, file.type))) {
    return NextResponse.json({ error: 'Dosya içeriği beyan edilen türle eşleşmiyor.' }, { status: 400 });
  }

  const MIME_TO_EXT: Record<string, string> = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'application/pdf': 'pdf',
  };
  const ext  = MIME_TO_EXT[file.type] ?? 'bin';
  const path = `${user.id}/${Date.now()}-kanit.${ext}`;

  const bytes = await file.arrayBuffer();

  const { error } = await supabase.storage
    .from('claim-evidence')
    .upload(path, bytes, {
      contentType: file.type,
      upsert: false,
    });

  if (error) {
    return NextResponse.json({ error: 'upload_failed' }, { status: 500 });
  }

  // Signed URL (admin okuyabilmesi için 30 gün geçerli)
  const { data: signedData } = await supabase.storage
    .from('claim-evidence')
    .createSignedUrl(path, 60 * 60 * 24 * 30);

  return NextResponse.json({ url: signedData?.signedUrl ?? null, path });
}
