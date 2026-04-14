# Yeedoy Sistem Ozeti

**Guncelleme:** 2026-03-11
**Kapsam:** `apps/`, `packages/`, `supabase/`

## Yeedoy Nedir?

Yeedoy uc ana katmandan olusan bir restoran ve kafe seffaflik platformudur:

1. Topluluk temelli fiyat dogrulama
2. Canli dijital menu ve QR dagitimi
3. Owner ve admin operasyon yuzeyleri

## Uc Uygulamali Yapi

| Uygulama | Teknoloji | Ana Rol |
|---|---|---|
| `apps/mobile_flutter` | Flutter + Riverpod + GoRouter | Kesif, menu, katkilar, review |
| `apps/panel_flutter_web` | Flutter Web + Riverpod + GoRouter | Owner CRUD, admin moderasyon, analytics |
| `apps/web_next` | Next.js + React + Tailwind | Public menu, SEO, QR Studio |

Tum uygulamalar tek bir Supabase backend'ini paylasir.

## Temel Uc Uca Akislar

### Tuketici kesif akisi

Mobil uygulama uzerinde kullanici isletme ve menu kesfeder, katkida bulunur, arka tarafta moderasyon ve confidence mantigi devreye girer.

### QR menu akisi

Owner panelden QR niyeti olusturur, oturum handoff ile `web_next` tarafina tasinir, QR indirilir ve kisa link canonical public menuye yonlenir.

### Owner onboarding akisi

Owner claim olusturur, admin onaylar, kullanici `/owner/*` alanina erisir ve aktif business baglami ile menu, ekip ve analytics alanlarini yonetir.

### Fiyat katkisi akisi

Mobil uygulama fiyat onerisi gonderir, RPC write deseni bu oneriyi alir, admin panelden karar verir, confidence sinyali guncellenir.

### Admin moderasyon akisi

Report, claim, submission ve queue item'lari panelde RBAC kontrollu olarak incelenir; kararlar audit kaydina yazilir.

## Uygulama Sinir Kontrati

| Sorumluluk | Sahibi |
|---|---|
| Tuketici kesif ve review | `mobile_flutter` |
| Public menu render ve SEO | `web_next` |
| QR uretimi ve branding | `web_next` |
| Otorize handoff | `web_next` |
| Business ve menu CRUD | `panel_flutter_web` |
| Admin moderasyon | `panel_flutter_web` |
| Owner analytics ve growth | `panel_flutter_web` |

## Backend Ozet

- Veritabani Supabase/PostgreSQL tabanlidir.
- Hassas tablolarda RLS vardir; public menu tablolarinda anonim okuma desteklenir.
- Yazma islemleri agirlikli olarak RPC-first desenindedir.
- Mobil write denemelerinde idempotency anahtarlari kullanilir.
- Panel tarafinda TTL cache ve prefix invalidation desenleri vardir.

## Public URL Modeli

Canonical public menu fallback zinciri:

```text
public_slug -> slug -> businessId
```

- Ana hedef: `/m/{public_slug}`
- Eski UUID linkleri geri uyumlu redirect ile tasinir
- Kisa linkler `/q/{shortCode}` uzerinden canonical hedefe gider

## Temel Teknik Kararlar

| Karar | Gerekce |
|---|---|
| Write yuzeyinin panelde toplanmasi | Admin ve owner CRUD'u ikinci kez Next.js'te yazmamak |
| QR Studio icin session handoff | Panel oturumunu kontrollu sekilde public web tarafina gecirmek |
| RPC tabanli write modeli | Dogrudan tablo mutasyonunu azaltmak |
| Slug merkezli URL yapisi | SEO ve kalici link istikrari |
| TTL cache | Buyuk liste ekranlarinda RPC yukunu azaltmak |
| Deferred route loading | Agir ekranlarin ilk yukunu azaltmak |

## Paylasilan Paketler

| Paket | Durum | Not |
|---|---|---|
| `packages/shared_models` | Aktif | Ortak modeller ve yardimci tipler |
| `packages/shared_ui_components` | Aktif | Ortak Flutter UI parcaciklari |
| `packages/ui_tokens` | Sinirli | Web tarafinda birincil kaynak degil |

## Sonraki Okuma

- Mimari ayrinti: `docs/architecture.md`
- Veri modeli: `docs/data-model.md`
- Yetki modeli: `docs/rbac.md`
- Panel durum matrisi: `docs/ADMIN_OWNER_GAP_ANALYSIS.md`
- Olcek plani: `docs/SCALING_ROADMAP.md`
