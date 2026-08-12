# CRM v2 — Müşteri Listesi Arama — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sahip/musteriler` listesinde müşteri adına göre anlık, client-side arama eklemek.

**Architecture:** `musteri-listesi.tsx` client component'e dönüşür; filtreleme mantığı test edilebilir bir saf fonksiyona (`filtrelenmisMusteriler`) çıkarılır ve `useMemo` ile bağlanır. RPC/migration değişikliği yok — mevcut `get_business_customers_v1` dönüşü üzerinde çalışılır.

**Tech Stack:** Next.js 15 (App Router), React `useState`/`useMemo`, Vitest.

**Design doc:** `docs/superpowers/specs/2026-08-12-crm-v2-arama-filtre-design.md`

---

### Task 1: Client-side arama filtresi

**Files:**
- Modify: `uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx`
- Modify: `uygulamalar/web/test/lib/musteri-listesi.test.ts`

- [ ] **Step 1: Write the failing tests**

`uygulamalar/web/test/lib/musteri-listesi.test.ts` dosyasının tamamını şu içerikle değiştir (mevcut export-check testini korur, yeni `describe` bloğu ekler):

```typescript
import { describe, it, expect } from 'vitest';
import { MusteriListesi, filtrelenmisMusteriler, type MusteriOzet } from '@/app/sahip/musteriler/musteri-listesi';
import { ZamanCizelgesi } from '@/app/sahip/musteriler/[user_id]/zaman-cizelgesi';

describe('CRM müşteri bileşenleri', () => {
  it('bileşenler export edilir', () => {
    expect(typeof MusteriListesi).toBe('function');
    expect(typeof ZamanCizelgesi).toBe('function');
  });
});

function fakeMusteri(overrides: Partial<MusteriOzet>): MusteriOzet {
  return {
    user_id: 'u1',
    display_name: 'Test Müşteri',
    avatar_url: null,
    last_interaction_at: '2026-08-01T00:00:00Z',
    review_count: 0,
    reservation_count: 0,
    loyalty_progress: null,
    loyalty_reward_threshold: null,
    tags: [],
    ...overrides,
  };
}

describe('filtrelenmisMusteriler', () => {
  const musteriler: MusteriOzet[] = [
    fakeMusteri({ user_id: 'u1', display_name: 'Ahmet Yılmaz' }),
    fakeMusteri({ user_id: 'u2', display_name: 'İstanbul Şube Müşterisi' }),
    fakeMusteri({ user_id: 'u3', display_name: 'Zeynep Kaya' }),
  ];

  it('boş arama metniyle tüm listeyi döner', () => {
    expect(filtrelenmisMusteriler(musteriler, '')).toEqual(musteriler);
  });

  it('eşleşen isimde tek sonuç döner', () => {
    const sonuc = filtrelenmisMusteriler(musteriler, 'Zeynep');
    expect(sonuc.map((m) => m.user_id)).toEqual(['u3']);
  });

  it('eşleşmeyen aramada boş dizi döner', () => {
    expect(filtrelenmisMusteriler(musteriler, 'Mehmet')).toEqual([]);
  });

  it('Türkçe büyük/küçük harf duyarlılığını doğru işler (İ/i)', () => {
    const sonuc = filtrelenmisMusteriler(musteriler, 'istanbul');
    expect(sonuc.map((m) => m.user_id)).toEqual(['u2']);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd uygulamalar/web && pnpm run test:unit -- musteri-listesi`
Expected: FAIL — `filtrelenmisMusteriler` is not exported from `musteri-listesi.tsx` (import error).

- [ ] **Step 3: Implement the filtering + search UI**

`uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx` dosyasının tamamını şu içerikle değiştir:

```tsx
'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';

export type MusteriOzet = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  last_interaction_at: string;
  review_count: number;
  reservation_count: number;
  loyalty_progress: number | null;
  loyalty_reward_threshold: number | null;
  tags: { id: string; tag: string }[];
};

export function filtrelenmisMusteriler(musteriler: MusteriOzet[], aramaMetni: string): MusteriOzet[] {
  const normalize = (s: string) => s.toLocaleLowerCase('tr');
  const aranan = normalize(aramaMetni.trim());
  if (aranan === '') return musteriler;
  return musteriler.filter((m) => normalize(m.display_name).includes(aranan));
}

export function MusteriListesi({ musteriler }: { musteriler: MusteriOzet[] }) {
  const [aramaMetni, setAramaMetni] = useState('');
  const filtreli = useMemo(
    () => filtrelenmisMusteriler(musteriler, aramaMetni),
    [musteriler, aramaMetni],
  );

  if (musteriler.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç müşteri etkileşimi yok.</p>;
  }

  return (
    <div className="flex flex-col gap-3">
      <input
        value={aramaMetni}
        onChange={(e) => setAramaMetni(e.target.value)}
        placeholder="Müşteri ara..."
        className="w-64 rounded-xl border border-border bg-card px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      />
      {filtreli.length === 0 ? (
        <p className="text-sm text-muted">&quot;{aramaMetni}&quot; ile eşleşen müşteri bulunamadı.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
                <th className="py-2">Müşteri</th>
                <th className="py-2">Son Etkileşim</th>
                <th className="py-2">Yorum</th>
                <th className="py-2">Rezervasyon</th>
                <th className="py-2">Sadakat</th>
                <th className="py-2">Etiketler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtreli.map((m) => (
                <tr key={m.user_id}>
                  <td className="py-2">
                    <Link
                      href={`/sahip/musteriler/${m.user_id}`}
                      className="font-semibold text-textStrong hover:underline"
                    >
                      {m.display_name}
                    </Link>
                  </td>
                  <td className="py-2 text-muted">
                    {new Date(m.last_interaction_at).toLocaleDateString('tr-TR')}
                  </td>
                  <td className="py-2 text-textStrong">{m.review_count}</td>
                  <td className="py-2 text-textStrong">{m.reservation_count}</td>
                  <td className="py-2 text-textStrong">{m.loyalty_progress ?? '—'}</td>
                  <td className="py-2">
                    <div className="flex flex-wrap gap-1">
                      {m.tags.map((t) => (
                        <span
                          key={t.id}
                          className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary"
                        >
                          {t.tag}
                        </span>
                      ))}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd uygulamalar/web && pnpm run test:unit -- musteri-listesi`
Expected: PASS — all 5 tests (1 export-check + 4 `filtrelenmisMusteriler`) green.

- [ ] **Step 5: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors (pre-existing unrelated warnings in other files are fine).

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx uygulamalar/web/test/lib/musteri-listesi.test.ts
git commit -m "feat(web): CRM v2 — müşteri listesinde isim bazlı client-side arama"
```

---

### Task 2: Doğrulama — gerçek tarayıcı testi

**Files:** Yok (sadece manuel doğrulama, kod değişikliği yok).

- [ ] **Step 1: Dev server'ı başlat**

Run: `cd uygulamalar/web && pnpm run dev` (arka planda).

- [ ] **Step 2: Tarayıcıda `/sahip/musteriler` sayfasını aç ve doğrula**

- Arama kutusuna bir müşterinin adının bir parçasını yaz → liste anında filtrelenmeli (sayfa yenilenmemeli).
- Eşleşmeyen bir metin yaz → "... ile eşleşen müşteri bulunamadı." mesajı görünmeli.
- Arama kutusunu temizle → tüm liste geri gelmeli.
- Eğer test verisinde Türkçe büyük/küçük harf içeren bir isim varsa (örn. "İstanbul" geçen bir isim), küçük harf "istanbul" ile arayıp eşleştiğini doğrula.

- [ ] **Step 3: Dev server'ı durdur, tarayıcı sekmesini kapat**

- [ ] **Step 4: Kullanıcıya rapor**

Hangi senaryoların test edildiğini ve hangi dosyaların değiştiğini özetle.
