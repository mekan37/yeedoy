# Web Drawer Navigasyon + Header/Layout Düzeltmeleri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Web uygulamasına mobil uygulamadaki `AppDrawer`'ı çevir, header eksik olan `(kimlik)` sayfalarını düzelt ve genişlik tutarsızlığını gider.

**Architecture:** Zustand store (`web-kabuk-deposu.ts`) drawer open/close state'ini tutar. `HamburgerDugmesi` (client) toggle yapar; `AppDrawer` (client) store'u dinler ve overlay+panel render eder. `PublicShell` (server) unread count fetch eder ve `AppDrawer`'a prop olarak geçer.

**Tech Stack:** Next.js 15 App Router, TypeScript, Tailwind CSS, Zustand, `@supabase/ssr`

---

## Dosya Haritası

| Eylem | Dosya |
|---|---|
| Oluştur | `uygulamalar/web/src/lib/web-kabuk-deposu.ts` |
| Oluştur | `uygulamalar/web/src/ui/kabuk/hamburger-dugmesi.tsx` |
| Oluştur | `uygulamalar/web/src/ui/kabuk/uygulama-cekmecesi.tsx` |
| Değiştir | `uygulamalar/web/src/ui/acik/yerlesim.tsx` |
| Değiştir | `uygulamalar/web/app/(kimlik)/layout.tsx` |
| Değiştir | `uygulamalar/web/app/(kimlik)/profil/page.tsx` |

---

## Task 1: Zustand Drawer Store

**Files:**
- Create: `uygulamalar/web/src/lib/web-kabuk-deposu.ts`

- [ ] **Step 1: Dosyayı oluştur**

```ts
// uygulamalar/web/src/lib/web-kabuk-deposu.ts
import { create } from 'zustand';

interface WebKabukStore {
  isDrawerOpen: boolean;
  openDrawer: () => void;
  closeDrawer: () => void;
  toggleDrawer: () => void;
}

export const useWebKabukStore = create<WebKabukStore>()((set) => ({
  isDrawerOpen: false,
  openDrawer:  () => set({ isDrawerOpen: true }),
  closeDrawer: () => set({ isDrawerOpen: false }),
  toggleDrawer: () => set((s) => ({ isDrawerOpen: !s.isDrawerOpen })),
}));
```

Not: `persist` yok — drawer, sayfa yenilenince kapalı başlamalı.

- [ ] **Step 2: Typecheck**

Çalışma dizini: `uygulamalar/web`

```
npm run typecheck
```

Beklenen: hata yok.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/src/lib/web-kabuk-deposu.ts
git commit -m "feat(web): add drawer Zustand store"
```

---

## Task 2: Hamburger Butonu

**Files:**
- Create: `uygulamalar/web/src/ui/kabuk/hamburger-dugmesi.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
// uygulamalar/web/src/ui/kabuk/hamburger-dugmesi.tsx
'use client';

import { useWebKabukStore } from '@/src/lib/web-kabuk-deposu';

export function HamburgerDugmesi() {
  const toggleDrawer = useWebKabukStore((s) => s.toggleDrawer);
  const isOpen = useWebKabukStore((s) => s.isDrawerOpen);

  return (
    <button
      type="button"
      onClick={toggleDrawer}
      aria-label={isOpen ? 'Menüyü kapat' : 'Menüyü aç'}
      aria-expanded={isOpen}
      className="flex h-10 w-10 items-center justify-center rounded-2xl text-text hover:bg-cardAlt focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 md:hidden"
    >
      <svg
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        aria-hidden="true"
      >
        <line x1="2" y1="5" x2="18" y2="5" />
        <line x1="2" y1="10" x2="18" y2="10" />
        <line x1="2" y1="15" x2="18" y2="15" />
      </svg>
    </button>
  );
}
```

- [ ] **Step 2: Typecheck**

```
npm run typecheck
```

Beklenen: hata yok.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/src/ui/kabuk/hamburger-dugmesi.tsx
git commit -m "feat(web): add hamburger button client component"
```

---

## Task 3: AppDrawer Bileşeni

**Files:**
- Create: `uygulamalar/web/src/ui/kabuk/uygulama-cekmecesi.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
// uygulamalar/web/src/ui/kabuk/uygulama-cekmecesi.tsx
'use client';

import Link from 'next/link';
import { useWebKabukStore } from '@/src/lib/web-kabuk-deposu';
import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';
import { ThemeToggle } from '@/src/ui/bilesenler/tema-degistirici';

export interface DrawerSessionUser {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
}

interface AppDrawerProps {
  sessionUser: DrawerSessionUser | null;
  unreadCount: number;
}

const NAV_SECTIONS: { title: string; items: { href: string; label: string; icon: string }[] }[] = [
  {
    title: 'Keşfet',
    items: [
      { href: '/kesif',       label: 'Keşfet',    icon: '🔍' },
      { href: '/en-iyiler',   label: 'En İyiler', icon: '🏆' },
      { href: '/liderler',    label: 'Liderler',  icon: '📍' },
      { href: '/butce',       label: 'Bütçe',     icon: '💰' },
    ],
  },
  {
    title: 'Özellikler',
    items: [
      { href: '/akilli-akis',     label: 'Akıllı Akış',            icon: '✨' },
      { href: '/tat-ikizi',       label: 'Taste Twin',             icon: '🤝' },
      { href: '/fiyat-uyarilari', label: 'Fiyat Uyarıları',       icon: '🔔' },
      { href: '/ortak-listeler',  label: 'Kolaborasyon Listeleri', icon: '📋' },
    ],
  },
];

const ACCOUNT_ITEMS: { href: string; label: string; icon: string; showBadge: boolean; requiresAuth: boolean }[] = [
  { href: '/favoriler',       label: 'Favorilerim',  icon: '❤️', showBadge: false, requiresAuth: true  },
  { href: '/profil',          label: 'Profil',       icon: '👤', showBadge: false, requiresAuth: true  },
  { href: '/gelen-kutusu',    label: 'Gelen Kutusu', icon: '📥', showBadge: true,  requiresAuth: true  },
  { href: '/oneriler',        label: 'Önerilerim',   icon: '💡', showBadge: false, requiresAuth: true  },
  { href: '/yasal',           label: 'Yasal',        icon: '📄', showBadge: false, requiresAuth: false },
];

export function AppDrawer({ sessionUser, unreadCount }: AppDrawerProps) {
  const { isDrawerOpen, closeDrawer } = useWebKabukStore();
  const initials =
    sessionUser?.displayName?.[0]?.toUpperCase() ??
    sessionUser?.email?.[0]?.toUpperCase() ??
    'K';

  return (
    <>
      {/* Backdrop */}
      {isDrawerOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm"
          onClick={closeDrawer}
          aria-hidden="true"
        />
      )}

      {/* Drawer paneli */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-80 overflow-y-auto bg-bg shadow-xl transition-transform duration-300 ease-in-out ${
          isDrawerOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
        aria-label="Navigasyon menüsü"
        role="dialog"
        aria-modal="true"
      >
        <div className="flex flex-col gap-3 p-4 pb-8">

          {/* Gradient başlık kartı */}
          <div
            className="flex items-center rounded-[18px] px-4 py-3 shadow-lg"
            style={{
              background:
                'linear-gradient(135deg, var(--yd-color-primary-deep) 0%, var(--yd-color-primary) 100%)',
            }}
          >
            <YeedoyLogo size={28} textColor="white" />
          </div>

          {/* Profil alanı */}
          {sessionUser ? (
            <Link
              href="/profil"
              onClick={closeDrawer}
              className="flex items-center gap-3 rounded-full border border-border bg-cardAlt px-3 py-2 hover:bg-card"
            >
              <div className="flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-sm font-[900] text-primary">
                {sessionUser.avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={sessionUser.avatarUrl}
                    alt=""
                    className="h-8 w-8 rounded-full object-cover"
                  />
                ) : (
                  initials
                )}
              </div>
              <span className="flex-1 text-sm font-[800] text-textStrong">
                {sessionUser.displayName ?? sessionUser.email}
              </span>
              <ChevronRight />
            </Link>
          ) : (
            <Link
              href="/giris"
              onClick={closeDrawer}
              className="flex items-center justify-center rounded-full border border-primary/30 bg-primary/10 px-4 py-2.5 text-sm font-[900] text-primary hover:bg-primary/20"
            >
              Giriş Yap
            </Link>
          )}

          {/* Nav bölümleri */}
          {NAV_SECTIONS.map((section) => (
            <div
              key={section.title}
              className="rounded-2xl border border-border bg-cardAlt p-3 shadow-sm"
            >
              <p className="mb-2 text-sm font-[800] text-textStrong">{section.title}</p>
              {section.items.map((item) => (
                <DrawerTile
                  key={item.href}
                  href={item.href}
                  icon={item.icon}
                  label={item.label}
                  onClose={closeDrawer}
                />
              ))}
            </div>
          ))}

          {/* Hesap bölümü */}
          <div className="rounded-2xl border border-border bg-cardAlt p-3 shadow-sm">
            <p className="mb-2 text-sm font-[800] text-textStrong">Hesap</p>
            {ACCOUNT_ITEMS.map((item) => (
              <DrawerTile
                key={item.href}
                href={
                  item.requiresAuth && !sessionUser
                    ? `/giris?redirect=${item.href}`
                    : item.href
                }
                icon={item.icon}
                label={item.label}
                badge={item.showBadge && unreadCount > 0 ? unreadCount : undefined}
                onClose={closeDrawer}
              />
            ))}
          </div>

          {/* Alt satır: tema toggle + marka adı */}
          <div className="flex items-center justify-between px-1 pt-1">
            <ThemeToggle className="min-h-9 min-w-9 rounded-xl" />
            <span className="text-xs font-[800] text-muted">Yeedoy</span>
          </div>
        </div>
      </aside>
    </>
  );
}

// ── İç bileşenler ─────────────────────────────────────────────────────────────

function DrawerTile({
  href,
  icon,
  label,
  badge,
  onClose,
}: {
  href: string;
  icon: string;
  label: string;
  badge?: number;
  onClose: () => void;
}) {
  return (
    <Link
      href={href}
      onClick={onClose}
      className="flex items-center gap-3 rounded-xl px-2 py-2.5 text-sm font-[700] text-text hover:bg-card"
    >
      <span className="shrink-0 text-base leading-none">{icon}</span>
      <span className="flex-1">{label}</span>
      {badge !== undefined && (
        <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-[900] text-white">
          {badge > 99 ? '99+' : badge}
        </span>
      )}
      <ChevronRight />
    </Link>
  );
}

function ChevronRight() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="shrink-0 text-muted"
      aria-hidden="true"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
```

- [ ] **Step 2: Typecheck**

```
npm run typecheck
```

Beklenen: hata yok.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/src/ui/kabuk/uygulama-cekmecesi.tsx
git commit -m "feat(web): add AppDrawer client component"
```

---

## Task 4: PublicHeader + PublicShell Güncelleme

**Files:**
- Modify: `uygulamalar/web/src/ui/acik/yerlesim.tsx`

- [ ] **Step 1: Import'ları ekle**

`yerlesim.tsx`'in başına şu importları ekle (mevcut import bloğunun sonuna):

```ts
import { HamburgerDugmesi } from '@/src/ui/kabuk/hamburger-dugmesi';
import { AppDrawer, type DrawerSessionUser } from '@/src/ui/kabuk/uygulama-cekmecesi';
```

- [ ] **Step 2: `getUnreadCount` yardımcı fonksiyonunu ekle**

`getSessionUser` fonksiyonunun hemen altına ekle:

```ts
async function getUnreadCount(userId: string): Promise<number> {
  try {
    const supabase = await createSupabaseServerClient();
    const { count, error } = await (supabase as any)
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false) as { count: number | null; error: { code?: string } | null };
    if (error?.code === '42P01') {
      const { count: c2 } = await (supabase as any)
        .from('user_notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false) as { count: number | null };
      return c2 ?? 0;
    }
    return count ?? 0;
  } catch {
    return 0;
  }
}
```

- [ ] **Step 3: `PublicHeader`'a `HamburgerDugmesi` ekle**

`PublicHeader` içindeki `{/* Sağ araçlar */}` div'ini bul:

```tsx
{/* Sağ araçlar */}
<div className="flex items-center gap-2">
  <ThemeToggle />
```

Bu satırı şu hale getir (ThemeToggle'dan önce HamburgerDugmesi ekle):

```tsx
{/* Sağ araçlar */}
<div className="flex items-center gap-2">
  <HamburgerDugmesi />
  <ThemeToggle />
```

- [ ] **Step 4: `PublicShell`'i güncelle**

Şu anki `PublicShell`:

```tsx
export async function PublicShell({
  children,
  footer = true,
  variant = 'public',
}: {
  children: ReactNode;
  footer?: boolean;
  variant?: 'public' | 'owner';
}) {
  return (
    <div className="min-h-screen bg-bg pb-20 text-text md:pb-0">
      <PublicHeader variant={variant} />
      {children}
      {footer ? <PublicFooter /> : null}
      <MobileBottomNav />
    </div>
  );
}
```

Şu hale getir:

```tsx
export async function PublicShell({
  children,
  footer = true,
  variant = 'public',
}: {
  children: ReactNode;
  footer?: boolean;
  variant?: 'public' | 'owner';
}) {
  const sessionUser = await getSessionUser();
  const unreadCount = sessionUser ? await getUnreadCount(sessionUser.id) : 0;
  const drawerUser: DrawerSessionUser | null = sessionUser;

  return (
    <div className="min-h-screen bg-bg pb-20 text-text md:pb-0">
      <PublicHeader variant={variant} />
      <AppDrawer sessionUser={drawerUser} unreadCount={unreadCount} />
      {children}
      {footer ? <PublicFooter /> : null}
      <MobileBottomNav />
    </div>
  );
}
```

- [ ] **Step 5: Typecheck**

```
npm run typecheck
```

Beklenen: hata yok. Eğer `DrawerSessionUser` tip uyumsuzluğu varsa, `getSessionUser` dönüş tipinin `id` alanını içerdiğini doğrula (mevcut kod `id: user.id` döndürüyor, uyumlu olmalı).

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/src/ui/acik/yerlesim.tsx
git commit -m "feat(web): wire AppDrawer into PublicShell, add hamburger to header"
```

---

## Task 5: `(kimlik)` Layout Header Düzeltmesi

**Files:**
- Modify: `uygulamalar/web/app/(kimlik)/layout.tsx`

- [ ] **Step 1: Mevcut layout'u gör**

Şu anki içerik:

```tsx
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { ReactNode } from 'react';

export default async function AuthLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/profil');
  return <>{children}</>;
}
```

- [ ] **Step 2: `PublicShell` ekle**

Import ekle ve `return` satırını değiştir:

```tsx
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { ReactNode } from 'react';
import { PublicShell } from '@/src/ui/acik/yerlesim';

export default async function AuthLayout({ children }: { children: ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/profil');
  return <PublicShell>{children}</PublicShell>;
}
```

- [ ] **Step 3: Typecheck**

```
npm run typecheck
```

Beklenen: hata yok.

- [ ] **Step 4: Smoke test — tarayıcıda `/profil` aç**

`uygulamalar/web` dizininde dev server'ı başlat:

```
npm run dev
```

`http://localhost:3000/profil` adresine git. Beklenen: üstte header (logo + nav + tema toggle), altta footer görünür.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/\(kimlik\)/layout.tsx
git commit -m "fix(web): wrap auth layout with PublicShell to restore header"
```

---

## Task 6: `/profil` Genişlik Düzeltmesi

**Files:**
- Modify: `uygulamalar/web/app/(kimlik)/profil/page.tsx`

- [ ] **Step 1: Dar genişlik div'ini bul**

`profil/page.tsx` içinde şu satırı ara:

```tsx
<div className="mx-auto max-w-xl px-4 pb-20 pt-10">
```

- [ ] **Step 2: `Container` ile değiştir**

Import ekle (dosyanın başındaki import bloğuna):

```tsx
import { Container } from '@/src/ui/acik/ortak';
```

Ardından şu satırı değiştir:

```tsx
// Eski:
<div className="mx-auto max-w-xl px-4 pb-20 pt-10">

// Yeni:
<Container className="pb-20 pt-10">
```

Kapanış etiketini de güncelle (`</div>` → `</Container>`). Dosyadaki bu `div`'in tam nerede kapandığını görmek için `return` bloğunun sonunu kontrol et.

- [ ] **Step 3: Typecheck + lint**

```
npm run typecheck && npm run lint
```

Beklenen: hata yok.

- [ ] **Step 4: Smoke test**

`http://localhost:3000/profil` sayfasında içerik genişliğinin ana sayfa (`http://localhost:3000`) içerik genişliğiyle eşleştiğini doğrula.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/\(kimlik\)/profil/page.tsx
git commit -m "fix(web): use Container on profil page for consistent width"
```

---

## Task 7: Drawer Manuel Smoke Test

Bu task koda dokunmaz — doğrulama adımları.

- [ ] **Step 1: Mobil viewport'ta hamburger testi**

Tarayıcı DevTools'ta viewport'u 375px genişliğe ayarla. `http://localhost:3000` adresini aç. Header'da hamburger ikonu görünmeli.

- [ ] **Step 2: Drawer aç/kapa**

Hamburgera tıkla → drawer soldan açılmalı (300ms animasyon). Drawer dışına (backdrop) tıkla → kapanmalı. Tekrar aç → bir linke tıkla → drawer kapanmalı ve ilgili sayfaya gitmeli.

- [ ] **Step 3: Desktop'ta hamburger gizli**

Viewport'u 1280px yap. Hamburger görünmemeli, yatay nav görünmeli.

- [ ] **Step 4: Giriş yapılmamış drawer testi**

Çıkış yap. Drawer'ı aç. "Profil" bölümü yerine "Giriş Yap" butonu görünmeli. Hesap bölümündeki auth gerektiren linklere tıklayınca `/giris?redirect=...` adresine yönlenmeli.

- [ ] **Step 5: Dark mode**

Tema toggle ile dark mode'a geç. Drawer gradient ve renkler doğru görünmeli (CSS variables dark mode'da çalışıyor).

- [ ] **Step 6: Final commit**

```bash
git add -p   # staging gerekirse
git commit -m "feat(web): web drawer nav + header layout fixes"
```

---

## Olası Sorunlar

| Sorun | Çözüm |
|---|---|
| `DrawerSessionUser` tip hatası | `getSessionUser()` zaten `id` döndürüyor — `DrawerSessionUser` ile aynı şekil |
| `(kimlik)` layout redirect URL | Şu an `/giris?redirect=/profil` sabit — gerekirse `usePathname` ile dinamik yapılabilir (kapsam dışı) |
| `notifications` tablosu yok | `getUnreadCount` `42P01` hatasını yakalar ve `0` döndürür |
| Drawer `z-index` çakışması | Header `z-40` → backdrop `z-40` → drawer `z-50`; sticky header `z-40` zaten uyumlu |
