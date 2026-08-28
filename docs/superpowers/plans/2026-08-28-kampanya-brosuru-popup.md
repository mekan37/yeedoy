# Kampanya Broşürü Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sahip panelinde kampanyalara opsiyonel bir görsel ("broşür") yüklenebilsin ve işletme detay sayfasının Kampanyalar sekmesinde bir kampanya kartına tıklanınca bu görsel (varsa) büyük halde bir popup'ta gösterilsin.

**Architecture:** `public.campaigns.image_url` kolonu ve `owner_upsert_campaign_v1` RPC'si zaten bu alanı destekliyor; public okuma tarafı (`isletme/[slug]/page.tsx`) da zaten `image_url`'i `KampanyaBilgi.imageUrl`'e map'liyor. Eksik olan tek şey: (1) sahip panelindeki formun bu alanı hiç göstermemesi/göndermemesi, (2) public tarafta bu alanın hiç render edilmemesi ve kartın tıklanamaması. Değişiklik yok — DB/migration gerekmiyor.

**Tech Stack:** Next.js 15 App Router (Server Actions), Zod, Supabase Storage (`menu-media` bucket), Vitest.

---

### Task 1: Medya yükleme route'una `campaign` tipi ekle

**Files:**
- Modify: `uygulamalar/web/app/sunucu/medya/yukleme/route.ts`
- Test: `uygulamalar/web/test/lib/medya-yukleme-route.test.ts`

- [x] **Step 1: Şemayı export et ve başarısız olacak testi yaz**

`uygulamalar/web/app/sunucu/medya/yukleme/route.ts` dosyasında satır 10-13'ü değiştir:

```ts
export const uploadSchema = z.object({
  businessId: z.string().uuid(),
  type: z.enum(['logo', 'cover', 'background', 'item']),
});
```

(Tek değişiklik: `const` → `export const`. Enum'a henüz `'campaign'` eklenmedi.)

Yeni test dosyasını oluştur:

```ts
import { describe, it, expect } from 'vitest';
import { uploadSchema } from '@/app/sunucu/medya/yukleme/route';

describe('uploadSchema', () => {
  it('campaign tipini kabul eder', () => {
    const result = uploadSchema.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      type: 'campaign',
    });
    expect(result.success).toBe(true);
  });

  it('bilinmeyen bir tipi reddeder', () => {
    const result = uploadSchema.safeParse({
      businessId: '11111111-1111-4111-8111-111111111111',
      type: 'brochure',
    });
    expect(result.success).toBe(false);
  });

  it('geçersiz businessId (uuid değil) reddedilir', () => {
    const result = uploadSchema.safeParse({
      businessId: 'not-a-uuid',
      type: 'campaign',
    });
    expect(result.success).toBe(false);
  });
});
```

- [x] **Step 2: Testi çalıştır, "campaign tipini kabul eder" testinin FAIL olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/medya-yukleme-route.test.ts`
Expected: `bilinmeyen bir tipi reddeder` ve `geçersiz businessId...` PASS, `campaign tipini kabul eder` FAIL (çünkü enum'da `'campaign'` yok).

- [x] **Step 3: `campaign` tipini enum'a ve storage path mantığına ekle**

`route.ts` satır 10-13'ü güncelle:

```ts
export const uploadSchema = z.object({
  businessId: z.string().uuid(),
  type: z.enum(['logo', 'cover', 'background', 'item', 'campaign']),
});
```

Satır 73-77'deki path mantığını güncelle:

```ts
  const extension = extensionFromMimeType(file.type);
  const path =
    parsed.data.type === 'item'
      ? `businesses/${parsed.data.businessId}/items/${randomUUID()}.${extension}`
      : parsed.data.type === 'campaign'
        ? `businesses/${parsed.data.businessId}/campaigns/${randomUUID()}.${extension}`
        : `businesses/${parsed.data.businessId}/branding/${parsed.data.type}/${randomUUID()}.${extension}`;
```

- [x] **Step 4: Testi tekrar çalıştır, tümünün PASS olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/medya-yukleme-route.test.ts`
Expected: 3 test de PASS.

- [x] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sunucu/medya/yukleme/route.ts uygulamalar/web/test/lib/medya-yukleme-route.test.ts
git commit -m "feat(web): medya yükleme route'una kampanya görseli (campaign) tipi eklendi"
```

---

### Task 2: Görsel sıkıştırma yardımcı fonksiyonunu paylaşılan bir dosyaya çıkar

Bu fonksiyon şu an sadece `isletme-gorselleri-editoru.tsx` içinde tanımlı. Task 4'te kampanya formunun da aynı fonksiyona ihtiyacı olacak — CLAUDE.md kuralı gereği ("duplicated primitive... don't write a fourth copy") kopyalamak yerine paylaşılan bir dosyaya taşınıyor.

**Files:**
- Create: `uygulamalar/web/src/lib/gorsel-sikistir.ts`
- Modify: `uygulamalar/web/app/sahip/ayarlar/sekmeler/isletme-gorselleri-editoru.tsx`

- [x] **Step 1: Yeni paylaşılan dosyayı oluştur**

```ts
export async function compressToWebP(file: File, maxPx: number): Promise<File> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const objectUrl = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      let { width, height } = img;
      if (width > maxPx || height > maxPx) {
        const ratio = Math.min(maxPx / width, maxPx / height);
        width = Math.round(width * ratio);
        height = Math.round(height * ratio);
      }
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      canvas.getContext('2d')!.drawImage(img, 0, 0, width, height);
      canvas.toBlob(
        (blob) => {
          if (!blob) { reject(new Error('compress_failed')); return; }
          resolve(new File([blob], file.name.replace(/\.[^.]+$/, '.webp'), { type: 'image/webp' }));
        },
        'image/webp',
        0.85,
      );
    };
    img.onerror = () => { URL.revokeObjectURL(objectUrl); reject(new Error('load_failed')); };
    img.src = objectUrl;
  });
}
```

(Not: Bu fonksiyon tarayıcı `Image`/`canvas` API'lerine bağımlı; mevcut haliyle de test edilmiyordu — bu taşıma test kapsamını değiştirmiyor.)

- [x] **Step 2: `isletme-gorselleri-editoru.tsx`'te yerel tanımı kaldır, import ekle**

Dosyanın en üstündeki import bloğuna ekle (satır 4-5 civarı):

```ts
import { updateBusinessBranding } from '../ayarlar-islemleri';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';
```

Dosyadaki satır 20-48 arasındaki (`async function compressToWebP(file: File, maxPx: number): Promise<File> { ... }`) yerel fonksiyon tanımının tamamını sil.

- [x] **Step 3: Typecheck ile doğrula**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: Hata yok (fonksiyon artık import'tan geliyor, imza aynı).

- [x] **Step 4: Commit**

```bash
git add uygulamalar/web/src/lib/gorsel-sikistir.ts uygulamalar/web/app/sahip/ayarlar/sekmeler/isletme-gorselleri-editoru.tsx
git commit -m "refactor(web): compressToWebP paylaşılan bir yardımcı dosyaya taşındı"
```

---

### Task 3: Kampanya kaydetme action'ı `image_url` alanını kabul etsin

**Files:**
- Modify: `uygulamalar/web/app/sahip/pazarlama/kampanyalar/kampanya-islemleri.ts`
- Test: `uygulamalar/web/test/lib/kampanya-islemleri.test.ts`

- [x] **Step 1: Şemayı export et ve başarısız olacak testi yaz**

`kampanya-islemleri.ts` satır 11'i değiştir:

```ts
export const KampanyaSemasi = z.object({
```

(Tek değişiklik: `const` → `export const`. `image_url` alanı henüz eklenmedi.)

Yeni test dosyasını oluştur:

```ts
import { describe, it, expect } from 'vitest';
import { KampanyaSemasi } from '@/app/sahip/pazarlama/kampanyalar/kampanya-islemleri';

describe('KampanyaSemasi', () => {
  const base = {
    business_id: '11111111-1111-4111-8111-111111111111',
    title: 'Kahvaltıda %20 İndirim',
    type: 'discount' as const,
    status: 'active' as const,
  };

  it('image_url olmadan kabul eder (opsiyonel)', () => {
    const result = KampanyaSemasi.safeParse(base);
    expect(result.success).toBe(true);
  });

  it('geçerli bir image_url kabul eder', () => {
    const result = KampanyaSemasi.safeParse({
      ...base,
      image_url: 'https://example.supabase.co/storage/v1/object/public/menu-media/businesses/x/campaigns/y.webp',
    });
    expect(result.success).toBe(true);
  });

  it('null image_url kabul eder (görsel kaldırıldığında)', () => {
    const result = KampanyaSemasi.safeParse({ ...base, image_url: null });
    expect(result.success).toBe(true);
  });

  it('geçersiz bir image_url (url formatında değil) reddedilir', () => {
    const result = KampanyaSemasi.safeParse({ ...base, image_url: 'not-a-url' });
    expect(result.success).toBe(false);
  });
});
```

- [x] **Step 2: Testi çalıştır, "geçersiz bir image_url reddedilir" testinin FAIL olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/kampanya-islemleri.test.ts`
Expected: `image_url` alanı şemada henüz tanımlı olmadığı için zod, nesnedeki bu fazladan alanı varsayılan olarak yok sayar — bu yüzden `image_url olmadan kabul eder`, `geçerli bir image_url kabul eder` ve `null image_url kabul eder` testleri (üçü de `success: true` bekliyor) zaten yanlışlıkla PASS olur. Sadece `geçersiz bir image_url (url formatında değil) reddedilir` testi FAIL olmalı — çünkü `'not-a-url'` değeri de yok sayılıp `success: true` dönüyor ama test `false` bekliyor.

- [x] **Step 3: `image_url` alanını şemaya ekle**

`kampanya-islemleri.ts` satır 11-24'teki şemayı güncelle:

```ts
export const KampanyaSemasi = z.object({
  business_id:      z.string().uuid(),
  title:            z.string().min(1).max(120),
  type:             z.enum(['discount', 'special_offer', 'loyalty', 'announcement']),
  status:           z.enum(['draft', 'planned', 'active', 'completed']),
  description:      z.string().max(500).optional(),
  discount_percent: z.coerce.number().int().min(1).max(100).optional().nullable(),
  // Native <input type="datetime-local"> gönderir: "YYYY-MM-DDTHH:mm" (saat dilimi yok).
  // Kesin ISO-8601 formatı burada zorunlu tutulmuyor; kampanyaKaydet içinde
  // new Date(...).toISOString() ile dönüştürülüp doğrulanıyor.
  starts_at:        z.string().optional().nullable(),
  ends_at:          z.string().optional().nullable(),
  image_url:        z.string().url().optional().nullable(),
  id:               z.string().uuid().optional().nullable(),
});
```

`kampanyaKaydet` fonksiyonu içindeki `raw` objesine ekle (satır 39-49 civarı):

```ts
  const raw = {
    business_id:      formData.get('business_id'),
    title:            formData.get('title'),
    type:             formData.get('type'),
    status:           formData.get('status'),
    description:      formData.get('description') || undefined,
    discount_percent: formData.get('discount_percent') || null,
    starts_at:        formData.get('starts_at') || null,
    ends_at:          formData.get('ends_at') || null,
    image_url:        formData.get('image_url') || null,
    id:               formData.get('id') || null,
  };
```

RPC çağrısına `p_image_url` parametresini ekle (satır 69-79 civarı):

```ts
    const { error } = await (supabase as any).rpc('owner_upsert_campaign_v1', {
      p_business_id:     d.business_id,
      p_title:           d.title,
      p_type:            d.type,
      p_status:          d.status,
      p_description:     d.description ?? null,
      p_discount_percent: d.discount_percent ?? null,
      p_starts_at:       startsAtIso,
      p_ends_at:         endsAtIso,
      p_image_url:       d.image_url ?? null,
      p_id:              d.id ?? null,
    }) as { error: { message: string } | null };
```

- [x] **Step 4: Testi tekrar çalıştır, tümünün PASS olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/kampanya-islemleri.test.ts`
Expected: 4 test de PASS — özellikle `geçersiz bir image_url (url formatında değil) reddedilir` artık gerçekten reddediyor.

- [x] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/pazarlama/kampanyalar/kampanya-islemleri.ts uygulamalar/web/test/lib/kampanya-islemleri.test.ts
git commit -m "feat(web): kampanya kaydetme action'ı image_url alanını kabul ediyor"
```

---

### Task 4: Sahip paneli kampanya formuna görsel yükleme alanı ekle

**Files:**
- Modify: `uygulamalar/web/app/sahip/pazarlama/kampanyalar/kampanya-formu.tsx`

- [x] **Step 1: `Kampanya` interface'ine `image_url` ekle, importları güncelle**

Dosyanın üstündeki import satırını değiştir:

```ts
'use client';

import { useActionState, useEffect, useRef, useState } from 'react';
import { kampanyaKaydet } from './kampanya-islemleri';
import { compressToWebP } from '@/src/lib/gorsel-sikistir';
```

`Kampanya` interface'ini güncelle (satır 9-21):

```ts
export interface Kampanya {
  id: string;
  title: string;
  description: string | null;
  type: KampanyaTipi;
  status: KampanyaDurumu;
  discount_percent: number | null;
  starts_at: string | null;
  ends_at: string | null;
  image_url: string | null;
  view_count: number;
  click_count: number;
  created_at: string;
}
```

- [x] **Step 2: Görsel yükleme state'ini ve handler'larını ekle**

`KampanyaFormu` fonksiyonunun başındaki state tanımlarına ekle (satır 49-52 civarı, `hasSubmitted` tanımından hemen sonra):

```ts
  const [state, action, pending] = useActionState(kampanyaKaydet, null);
  const formRef = useRef<HTMLFormElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const hasSubmitted = useRef(false);
  const isEdit = !!campaign;

  const [imageUrl, setImageUrl] = useState<string | null>(campaign?.image_url ?? null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  async function handleImageUpload(file: File) {
    setUploadError(null);
    setUploading(true);
    try {
      const compressed = await compressToWebP(file, 1600);
      const fd = new FormData();
      fd.append('businessId', businessId);
      fd.append('type', 'campaign');
      fd.append('file', compressed);

      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: fd });
      const result = await response.json().catch(() => null) as { data?: { url?: string }; error?: string } | null;

      if (!response.ok) {
        setUploadError(
          result?.error === 'rate_limited' ? 'Çok fazla istek, bekleyin.' :
          result?.error === 'file_too_large' ? 'Dosya çok büyük.' :
          result?.error === 'invalid_mime_type' ? 'Desteklenmeyen dosya türü.' :
          result?.error === 'forbidden' ? 'Bu işletmeyi düzenleme yetkiniz yok.' : 'Yükleme başarısız.',
        );
        return;
      }

      const url = result?.data?.url;
      if (!url) throw new Error('invalid_upload_response');
      setImageUrl(url);
    } catch {
      setUploadError('Yükleme sırasında bir bağlantı hatası oluştu. Lütfen tekrar deneyin.');
    } finally {
      setUploading(false);
    }
  }

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (f) handleImageUpload(f);
    e.target.value = '';
  }
```

- [x] **Step 3: Formda görsel alanını render et**

"Açıklama" alanından hemen sonra, "Tip + Durum" grid'inden önce ekle (satır 108-110 civarı):

```tsx
          {/* Görsel */}
          <Field label="Kampanya Görseli" hint="Opsiyonel — broşür/afiş görseli">
            <input type="hidden" name="image_url" value={imageUrl ?? ''} />
            {imageUrl ? (
              <div className="relative overflow-hidden rounded-xl border border-border" style={{ aspectRatio: '16/9' }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={imageUrl} alt="Kampanya görseli" className="h-full w-full object-cover" />
                <button
                  type="button"
                  onClick={() => setImageUrl(null)}
                  aria-label="Görseli kaldır"
                  className="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-black/50 text-white transition hover:bg-black/70"
                >
                  <CloseIcon />
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                className="flex h-24 w-full items-center justify-center gap-2 rounded-xl border border-dashed border-border text-sm font-bold text-muted transition hover:border-primary/40 hover:text-primary disabled:opacity-60"
              >
                {uploading ? <SpinIcon /> : null}
                {uploading ? 'Yükleniyor...' : 'Görsel Yükle'}
              </button>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={onFileChange}
            />
            {uploadError && <p className="mt-1.5 text-xs font-bold text-danger">{uploadError}</p>}
          </Field>
```

- [x] **Step 4: Typecheck ve lint ile doğrula**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 5: Tarayıcıda manuel doğrulama** — ⚠️ TAMAMLANMADI (agent güvenlik sınıflandırıcısı gerçek bir sahip oturumu taklit etme girişimini bilerek engelledi; kod yolu statik olarak doğrulandı ama gerçek tıklama testi bir insan tarafından yapılmalı)

`pnpm run dev` ile web'i başlat, `/sahip/pazarlama/kampanyalar` sayfasına git, bir kampanya oluştur/düzenle, "Görsel Yükle" butonuna bas, bir JPEG/PNG seç → önizleme görünmeli → "Kaydet"e bas → kampanyanın kaydedildiğini doğrula. Ardından formu tekrar aç, görselin (X butonu ile) kaldırılabildiğini doğrula.

- [x] **Step 6: Commit**

```bash
git add uygulamalar/web/app/sahip/pazarlama/kampanyalar/kampanya-formu.tsx
git commit -m "feat(web): sahip paneli kampanya formuna görsel yükleme alanı eklendi"
```

---

### Task 5: İşletme detay sayfası — kampanya kartı görseli + tıklanabilir broşür popup

**Files:**
- Modify: `uygulamalar/web/app/(genel)/isletme/[slug]/isletme-detay-tablari.tsx:612-676`

- [x] **Step 1: `KampanyaKartiDetay`, yeni `KampanyaBrosurPopup` ve güncellenmiş `KampanyalarIcerik`'i yaz**

Dosyadaki 612. satırdan 676. satıra kadar olan "Kampanyalar tab content" bloğunun tamamını şununla değiştir:

```tsx
// ── Kampanyalar tab content ────────────────────────────────────────────────────

function KampanyaKartiDetay({ k, onSec }: { k: KampanyaBilgi; onSec: (k: KampanyaBilgi) => void }) {
  const gunKaldi = gunKaldiHesapla(k.endsAt);
  const badge = kampanyaBadge(k.type, k.discountPercent);
  const renk = TUR_RENK[k.type];
  const gorselUrl = buildMenuImageUrl(k.imageUrl, { width: 640, quality: 78 });

  return (
    <button
      type="button"
      onClick={() => onSec(k)}
      className="w-full overflow-hidden rounded-[20px] border border-border bg-card text-left shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2"
    >
      {gorselUrl ? (
        <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={gorselUrl} alt={k.title} className="h-full w-full object-cover" loading="lazy" />
          <div className="absolute inset-x-0 bottom-0 h-12 bg-linear-to-t from-black/50 to-transparent" aria-hidden="true" />
        </div>
      ) : (
        <div className="h-1.5" style={{ background: renk }} />
      )}
      <div className="p-5">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div className="flex flex-wrap items-center gap-1.5">
            {badge.map((line, i) => (
              <span
                key={i}
                className={`rounded-full px-2.5 py-1 font-black text-white ${line.buyuk ? 'text-sm' : 'text-[10px] uppercase tracking-wide'}`}
                style={{ background: renk }}
              >
                {line.metin}
              </span>
            ))}
          </div>
          {gunKaldi != null && (
            <span className="flex shrink-0 items-center gap-1 rounded-full bg-danger/10 px-2.5 py-1 text-[11px] font-black text-danger">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
              </svg>
              {gunKaldi === 0 ? 'Son gün' : `${gunKaldi} gün kaldı`}
            </span>
          )}
        </div>
        <h3 className="mb-1.5 text-base font-black text-textStrong">{k.title}</h3>
        {k.description && (
          <p className="text-sm leading-6 text-muted line-clamp-2">{k.description}</p>
        )}
      </div>
    </button>
  );
}

function KampanyaBrosurPopup({ k, onClose }: { k: KampanyaBilgi; onClose: () => void }) {
  const gunKaldi = gunKaldiHesapla(k.endsAt);
  const badge = kampanyaBadge(k.type, k.discountPercent);
  const renk = TUR_RENK[k.type];
  const gorselUrl = buildMenuImageUrl(k.imageUrl, { width: 960, quality: 82 });

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-xs" onClick={onClose} />
      <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card shadow-2xl sm:rounded-2xl">
        <button
          type="button"
          onClick={onClose}
          aria-label="Kapat"
          className="absolute right-3 top-3 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur-sm transition hover:bg-black/60"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>

        {gorselUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={gorselUrl} alt={k.title} className="max-h-[420px] w-full object-cover" />
        )}

        <div className="p-6">
          <div className="mb-3 flex flex-wrap items-center gap-1.5">
            {badge.map((line, i) => (
              <span
                key={i}
                className={`rounded-full px-2.5 py-1 font-black text-white ${line.buyuk ? 'text-sm' : 'text-[10px] uppercase tracking-wide'}`}
                style={{ background: renk }}
              >
                {line.metin}
              </span>
            ))}
            {gunKaldi != null && (
              <span className="flex items-center gap-1 rounded-full bg-danger/10 px-2.5 py-1 text-[11px] font-black text-danger">
                {gunKaldi === 0 ? 'Son gün' : `${gunKaldi} gün kaldı`}
              </span>
            )}
          </div>
          <h2 className="mb-2 text-xl font-black text-textStrong">{k.title}</h2>
          {k.description && (
            <p className="text-sm leading-6 text-muted">{k.description}</p>
          )}
        </div>
      </div>
    </div>
  );
}

function KampanyalarIcerik({ kampanyalar }: { kampanyalar: KampanyaBilgi[] }) {
  const [acikKampanya, setAcikKampanya] = useState<KampanyaBilgi | null>(null);

  if (kampanyalar.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-[20px] border border-border bg-card py-16 text-center shadow-yd1">
        <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-cardAlt">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-muted" aria-hidden="true">
            <path d="M20.59 13.41 13.42 20.6a2 2 0 0 1-2.83 0L2.5 12.5V2h10.5l8.09 8.09a2 2 0 0 1 0 2.82z" />
            <circle cx="6.5" cy="6.5" r="1.5" />
          </svg>
        </div>
        <p className="text-sm font-extrabold text-textStrong">Şu an aktif kampanya yok</p>
        <p className="mt-1 text-xs text-muted">Bu işletme yeni bir kampanya oluşturduğunda burada göreceksin.</p>
      </div>
    );
  }

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2">
        {kampanyalar.map((k) => (
          <KampanyaKartiDetay key={k.id} k={k} onSec={setAcikKampanya} />
        ))}
      </div>
      {acikKampanya && (
        <KampanyaBrosurPopup k={acikKampanya} onClose={() => setAcikKampanya(null)} />
      )}
    </>
  );
}
```

Not: `useState`, `useEffect`, `buildMenuImageUrl`, `kampanyaBadge`, `TUR_RENK`, `gunKaldiHesapla` dosyanın üstünde zaten import edilmiş durumda (satır 3-22) — yeni bir import eklemeye gerek yok.

- [x] **Step 2: Typecheck ve lint ile doğrula**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 3: Tarayıcıda manuel doğrulama** — ⚠️ TAMAMLANMADI (bu worktree'nin .env.local'ı canlı/production Supabase projesine bağlı; agent'lar buna karşı dev server başlatmaktan kaçındı, statik doğrulama yapıldı — gerçek tıklama testi bir insan tarafından yapılmalı)

`pnpm run dev` ile web'i başlat, Task 4'te görsel eklenen kampanyanın işletmesine ait `/isletme/[slug]?tab=kampanyalar` sayfasına git:
- Görseli olan kampanya kartında küçük bir thumbnail görünmeli.
- Karta tıklayınca popup açılmalı, görsel büyük halde görünmeli.
- X butonu, backdrop'a tıklama ve Escape tuşu — üçü de popup'ı kapatmalı.
- Görseli olmayan (varsa) başka bir kampanya kartına tıklayınca da popup açılmalı, bu sefer görsel olmadan sadece metin büyütülmüş halde gösterilmeli.

- [x] **Step 4: Commit**

```bash
git add "uygulamalar/web/app/(genel)/isletme/[slug]/isletme-detay-tablari.tsx"
git commit -m "feat(web): işletme detay sayfası Kampanyalar sekmesine görsel + tıklanabilir broşür popup eklendi"
```

---

### Task 6: Son doğrulama

**Files:** (yok — sadece doğrulama)

- [x] **Step 1: Tam doğrulama komutunu çalıştır**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit testler (Task 1 ve 3'teki yeni testler dahil) + build hepsi PASS.

Sonuç: PASS — typecheck temiz, lint 0 hata (45 önceden var olan, bu değişiklikle ilgisiz uyarı), 35/35 test dosyası ve 188/188 test PASS (baseline 33 dosya/181 testten +2 dosya/+7 test — Task 1 ve 3'ün yeni testleriyle tam eşleşiyor), production build başarılı.

- [ ] **Step 2: Uçtan uca manuel akış** — ⚠️ TAMAMLANMADI (bu worktree'nin .env.local'ı canlı/production Supabase projesine bağlı olduğu için agent'lar gerçek bir sahip oturumu açmaktan/dev server'ı canlı veriye karşı çalıştırmaktan kaçındı — bir insan tarafından yapılmalı)

Sahip panelinde yeni bir kampanya oluştur, görsel yükle, `active` durumuna al → işletme detay sayfasında kartta görünmesini, tıklanınca popup'ta doğru gösterilmesini doğrula (Task 4/5'teki adımların birleşik hâli, gerçek bir kampanya üzerinden baştan sona).
