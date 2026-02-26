import { NextResponse } from 'next/server';
import QRCode from 'qrcode';
import React from 'react';
import { Document, Image, Page, Text, View, StyleSheet, pdf } from '@react-pdf/renderer';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { createServiceRoleClient } from '@/src/lib/supabaseAdmin';
import { hitRateLimit } from '@/src/lib/rate-limit';
import { shortCode } from '@/src/lib/slug';
import { canManageBusiness } from '@/src/lib/ownership';

const styles = StyleSheet.create({
  page: { padding: 28, fontSize: 12 },
  title: { fontSize: 20, marginBottom: 12 },
  section: { marginBottom: 12 },
});

export const runtime = 'nodejs';

async function uploadWithBucketEnsure(
  admin: ReturnType<typeof createServiceRoleClient>,
  path: string,
  bytes: Uint8Array,
  contentType: string,
) {
  let result = await admin.storage.from('menu-assets').upload(path, bytes, {
    upsert: true,
    contentType,
  });

  if (result.error && result.error.message.toLowerCase().includes('bucket not found')) {
    await admin.storage.createBucket('menu-assets', { public: true });
    result = await admin.storage.from('menu-assets').upload(path, bytes, {
      upsert: true,
      contentType,
    });
  }

  return result;
}

async function readWebStream(stream: ReadableStream<Uint8Array>): Promise<Uint8Array> {
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;
    chunks.push(value);
    total += value.length;
  }
  const merged = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.length;
  }
  return merged;
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  if (hitRateLimit(user.id)) {
    return NextResponse.json({ error: 'Rate limit exceeded' }, { status: 429 });
  }

  const body = await request.json().catch(() => ({}));
  const businessId = String(body.business_id ?? '');
  const format = String(body.format ?? 'svg') as 'svg' | 'png' | 'poster_pdf';

  const allowed = await canManageBusiness(supabase, user.id, businessId);
  if (!allowed) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const admin = createServiceRoleClient();
  const { data: business } = await admin
    .from('businesses')
    .select('id,name,slug')
    .eq('id', businessId)
    .maybeSingle();

  const locale = String(body.locale ?? 'tr').trim() || 'tr';
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000';
  const slugOrId = (business?.slug ?? business?.id ?? businessId).toString();
  const target = `${appUrl}/b/${slugOrId}?lang=${encodeURIComponent(locale)}`;

  const code = shortCode(8);

  let bytes: Uint8Array;
  let contentType = 'image/svg+xml';
  let ext = 'svg';

  if (format === 'png') {
    const png = await QRCode.toBuffer(target, { type: 'png', width: 1024, margin: 1 });
    bytes = new Uint8Array(png);
    contentType = 'image/png';
    ext = 'png';
  } else if (format === 'poster_pdf') {
    const pngDataUrl = await QRCode.toDataURL(target, { width: 512, margin: 1 });
    const doc = (
      <Document>
        <Page size="A4" style={styles.page}>
          <Text style={styles.title}>{business?.name ?? 'Business'}</Text>
          <View style={styles.section}><Text>Scan QR to open menu</Text></View>
          <View style={styles.section}><Text>{target}</Text></View>
          <View style={styles.section}><Image src={pngDataUrl} style={{ width: 240, height: 240 }} /></View>
        </Page>
      </Document>
    );
    const buff = await pdf(doc).toBuffer();
    if (buff instanceof Uint8Array) {
      bytes = buff;
    } else if (buff instanceof ArrayBuffer) {
      bytes = new Uint8Array(buff);
    } else {
      bytes = await readWebStream(buff as unknown as ReadableStream<Uint8Array>);
    }
    contentType = 'application/pdf';
    ext = 'pdf';
  } else {
    const svg = await QRCode.toString(target, { type: 'svg', width: 1024, margin: 1 });
    bytes = new TextEncoder().encode(svg);
    contentType = 'image/svg+xml';
    ext = 'svg';
  }

  const path = `qr/${businessId}/${format}-${Date.now()}.${ext}`;
  const { error: uploadError } = await uploadWithBucketEnsure(admin, path, bytes, contentType);
  if (uploadError) return NextResponse.json({ error: uploadError.message }, { status: 400 });

  const { data: pub } = admin.storage.from('menu-assets').getPublicUrl(path);
  return NextResponse.json({ ok: true, url: pub.publicUrl, short_url: target, code, locale });
}
