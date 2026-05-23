import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

const MAX_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']);

export async function POST(request: NextRequest) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Giriş yapmanız gerekiyor.' }, { status: 401 });
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

  const ext  = file.name.split('.').pop()?.toLowerCase() ?? 'bin';
  const path = `${user.id}/${Date.now()}-kanit.${ext}`;

  const bytes = await file.arrayBuffer();

  const { error } = await (supabase as any).storage
    .from('claim-evidence')
    .upload(path, bytes, {
      contentType: file.type,
      upsert: false,
    });

  if (error) {
    return NextResponse.json({ error: `Yükleme hatası: ${error.message}` }, { status: 500 });
  }

  // Signed URL (admin okuyabilmesi için 30 gün geçerli)
  const { data: signedData } = await (supabase as any).storage
    .from('claim-evidence')
    .createSignedUrl(path, 60 * 60 * 24 * 30);

  return NextResponse.json({ url: signedData?.signedUrl ?? null, path });
}
