# Sadakat v1 — Faz 3: Müşteri Web UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Müşterinin kendi sadakat kartlarını görebileceği ve owner'ın taratacağı QR kodunu göreceği `/sadakat` sayfasını (şu an `app/(kimlik)/sadakat/page.tsx` redirect stub'ı) gerçek bir sayfaya dönüştürmek. Bu faz olmadan Faz 1-2'de kurulan hiçbir şey gerçek bir müşteriyle uçtan uca test edilemiyor — owner tarama ekranı hazır ama müşterinin taratacağı kod hiçbir yerde üretilmiyordu.

**Architecture:** Tek sunucu bileşeni sayfa. QR kodu **sunucu tarafında** (`qrcode` npm paketi, zaten `uygulamalar/web/package.json`'da mevcut bağımlılık — yeni paket eklenmiyor) `user.id`'yi düz metin olarak kodlayıp `data:image/png` URI'sine çevirir, `<img>` ile gösterilir — client-side QR kütüphanesi gerekmez. Kart listesi `get_my_loyalty_cards_v1()` RPC'sinden (Faz 1'de zaten var) gelir. DB değişikliği yok.

**Tech Stack:** Next.js 15 Server Component, `qrcode` (mevcut bağımlılık).

---

### Task 1: Web — müşteri sayfası (QR + kart listesi)

**Files:**
- Modify: `uygulamalar/web/app/(kimlik)/sadakat/page.tsx` (redirect stub'ı gerçek sayfaya dönüştür)

- [ ] **Step 1: page.tsx'i tamamen değiştir**

Replace the entire content of `uygulamalar/web/app/(kimlik)/sadakat/page.tsx` (currently `redirect('/kesif')`) with:

```tsx
import type { Metadata } from 'next';
import QRCode from 'qrcode';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';

export const metadata: Metadata = {
  title: 'Sadakat Kartlarım | Yeedoy',
  robots: { index: false, follow: false },
};

type SadakatKarti = {
  program_id: string;
  mode: 'stamp' | 'points';
  business_name: string;
  logo_url: string | null;
  progress: number;
  reward_threshold: number;
  reward_desc: string;
};

export default async function SadakatPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const qrDataUrl = await QRCode.toDataURL(user.id, { margin: 1, width: 220 });

  const { data: cards } = (await (supabase as any).rpc('get_my_loyalty_cards_v1')) as {
    data: SadakatKarti[] | null;
  };
  const list = cards ?? [];

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-2xl px-4 py-12">
        <div className="mb-6">
          <h1 className="text-2xl font-black text-textStrong">Sadakat Kartlarım</h1>
          <p className="mt-1 text-sm text-muted">
            Damga/puan kazanmak için işletmede bu kodu gösterin.
          </p>
        </div>

        <div className="mb-8 flex flex-col items-center gap-3 rounded-2xl border border-border bg-card p-6">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={qrDataUrl} alt="Sadakat kodum" width={220} height={220} className="rounded-xl" />
          <p className="text-xs text-muted">Bu kod size özeldir, paylaşmayın.</p>
        </div>

        {list.length === 0 ? (
          <div className="rounded-2xl border border-border bg-card p-10 text-center">
            <p className="mb-3 text-3xl">🎁</p>
            <p className="mb-2 font-bold text-textStrong">Henüz sadakat kartınız yok</p>
            <p className="text-sm text-muted">
              Katıldığınız işletmelerin sadakat programları burada görünecek.
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {list.map((card) => (
              <div key={card.program_id} className="rounded-2xl border border-border bg-card p-5">
                <div className="flex items-center gap-3">
                  {card.logo_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={card.logo_url}
                      alt={card.business_name}
                      className="h-10 w-10 rounded-full object-cover"
                    />
                  ) : (
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-zinc-100 text-sm font-black text-zinc-500">
                      {card.business_name.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="font-black text-textStrong">{card.business_name}</p>
                    <p className="text-xs text-muted">{card.reward_desc}</p>
                  </div>
                </div>
                <div className="mt-3 h-2.5 overflow-hidden rounded-full bg-zinc-100">
                  <div
                    className="h-2.5 rounded-full bg-primary"
                    style={{
                      width: `${Math.min(100, Math.round((card.progress / card.reward_threshold) * 100))}%`,
                    }}
                  />
                </div>
                <p className="mt-1.5 text-xs font-bold text-textStrong">
                  {card.progress} / {card.reward_threshold}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
```

Not: `(kimlik)/layout.tsx` zaten `if (!user) redirect('/giris?redirect=/profil')` ile auth kontrolünü yapıyor — sayfanın kendi başına redirect etmesine gerek yok, `user` burada null olamaz ama TypeScript için `if (!user) return null;` güvenlik payı bırakıyor (mevcut `avantajlar/page.tsx` de aynı deseni kullanmıyor ama `user!.id` ile non-null assertion yapıyor — biz daha güvenli olan `if (!user) return null` yolunu tercih ediyoruz).

- [ ] **Step 2: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add "app/(kimlik)/sadakat/page.tsx"
git commit -m "feat(web): sadakat v1 faz 3 — müşteri sayfası: kendi QR kodu + kart listesi, redirect stub'ı kaldırıldı"
```

---

### Task 2: Web — owner-side eski kill-switch route'unu temizle

**Files:**
- Delete: `uygulamalar/web/app/sunucu/sahip/sadakat/route.ts`

Bu, eski (artık DB'den tamamen kaldırılmış) sadakat tasarımının 410 döndüren kill-switch'iydi. Gerçek özellik artık Supabase RPC üzerinden (`sadakat-islemleri.ts`) çalışıyor, bu route'a hiçbir kod referans vermiyor (doğrulandı). **Not:** `app/(auth)/loyalty/page.tsx` kasıtlı olarak dokunulmuyor — bu, projedeki geniş bir desenin parçası (eski İngilizce URL'lerin Türkçe karşılıklarına yönlendirildiği ~15 kardeş route arasından biri, `(auth)/favorites`, `(auth)/profile` vb. ile aynı desen), tek başına silinmesi tutarsız olur.

- [ ] **Step 1: Dosyayı sil**

```bash
rm "app/sunucu/sahip/sadakat/route.ts"
rmdir "app/sunucu/sahip/sadakat" 2>/dev/null || true
```

- [ ] **Step 2: Typecheck**

Run (uygulamalar/web içinden): `pnpm run typecheck`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add -A app/sunucu/sahip/sadakat
git commit -m "chore(web): sadakat v1 — eski owner kill-switch route'unu kaldır (artık RPC üzerinden çalışıyor)"
```

---

### Task 3: Doğrulama — uçtan uca gerçek tarayıcı testi

**Files:** (yalnızca doğrulama, yeni kod yok)

- [ ] **Step 1: Dev server'ı başlat, iki test hesabı kur**

Local Supabase (Docker) çalışıyor olmalı. Gerekirse `.env.local`'ı local Supabase'e işaret edecek şekilde ayarla (Faz 2'de yapıldığı gibi: `NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321`, publishable key `supabase status`'tan). İki test hesabı: (a) Faz 2'de kurulan owner hesabı (standard planlı bir işletmesi ve aktif bir sadakat programı olmalı), (b) yeni bir test **müşteri** hesabı (`/auth/v1/signup` ile, farklı bir email).

- [ ] **Step 2: Müşteri tarafını doğrula**

Müşteri hesabıyla giriş yap, `/sadakat` sayfasına git. Expected: QR kod görüntüsü render olur (bir `<img>` elemanı, `src` `data:image/png;base64,...` ile başlar — JS ile kontrol edilebilir), "Henüz sadakat kartınız yok" boş durumu görünür (müşteri henüz hiç damga almadı).

- [ ] **Step 3: Uçtan uca akışı doğrula**

Müşteri hesabının `user.id`'sini tarayıcıda JS ile oku (`document.querySelector('img[alt="Sadakat kodum"]')` civarından değil, doğrudan Supabase session'dan — ya da basitçe local DB'den `auth.users`'tan email ile bul). Owner hesabıyla `scan_loyalty_qr_v1(business_id, o_user_id)`'i SQL üzerinden (veya owner panelindeki tarama ekranını simüle ederek) çağır. Sonra müşteri hesabıyla `/sadakat`'a dön → kart artık görünmeli, progress bar ilerlemeli olarak.

- [ ] **Step 4: Kullanıcıya rapor**

Test sonucu, hangi dosyalar değişti — özetle. Bu noktada Sadakat v1'in DB→owner-web→müşteri-web zinciri baştan sona gerçek bir tarayıcıda doğrulanmış olacak. Faz 4 (mobil UI) hâlâ kapsam dışı kalıyor — mobilde müşteri kartlarını/QR'ını görmek için `features/sadakat/` klasörünün yeni RPC şemasına göre yeniden yazılması gerekiyor, ayrı bir faz.
