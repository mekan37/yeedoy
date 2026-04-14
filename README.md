# Yeedoy Monorepo

Bu depo, aynı Supabase veri modeli üzerinde çalışan çoklu istemci mimarisini içerir:

- `apps/mobile_flutter` — Son kullanıcı mobil uygulaması (iOS/Android)
- `apps/panel_flutter_web` — Admin/Owner paneli (Flutter Web)
- `apps/web_next` — İşletme dashboard + QR/public menu web yüzeyi (Next.js)
- `supabase/` — Veritabanı migration'ları, Edge Functions

---

## Gereksinimler

| Araç | Versiyon |
|---|---|
| Flutter | 3.x |
| Node.js | 18+ |
| Docker Desktop | (çalışıyor olmalı) |
| Supabase CLI | 2.x |

---

## 1. Local Supabase Başlat

Tüm uygulamalar local Supabase'e bağlanır. Docker Desktop açık olmalı.

```bash
# İlk kurulum veya sıfırlama
supabase start

# Durumu kontrol et
supabase status

# Durdurmak için
supabase stop
```

**Local bağlantı bilgileri:**
| | |
|---|---|
| API URL | `http://127.0.0.1:54321` |
| Studio | `http://127.0.0.1:54323` |
| DB | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |
| Anon Key | `supabase status --output env` çıktısından al |

---

## 2. Mobile Flutter (iOS/Android)

```bash
cd apps/mobile_flutter

# Bağımlılıkları yükle
flutter pub get

# Android emulator veya bağlı cihazda çalıştır
flutter run

# iOS simülatörde çalıştır
flutter run -d ios

# Belirli bir cihaz seç
flutter devices
flutter run -d <device-id>
```

**`.env` dosyası** (`apps/mobile_flutter/.env`):
```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<supabase status --output env ile al>
```

---

## 3. Panel Flutter Web (Admin/Owner)

```bash
cd apps/panel_flutter_web

# Bağımlılıkları yükle
flutter pub get

# Web'de çalıştır (Chrome)
flutter run -d chrome

# Belirli port ile çalıştır
flutter run -d chrome --web-port 50809

# Production build
flutter build web
```

**`.env` dosyası** (`apps/panel_flutter_web/.env`):
```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<supabase status --output env ile al>
```

**Giriş bilgileri (local):**
| Email | Şifre | Rol |
|---|---|---|
| `admin@yeedoy.com` | `Tunahan_120819` | Admin |
| `admin@menubak.tr` | `Tunahan_120819` | Admin |
| `a@a.com` | `Tunahan_120819` | User |

---

## 4. Web Next.js

```bash
cd apps/web_next

# Bağımlılıkları yükle
npm install

# Development sunucusu başlat
npm run dev
# → http://localhost:3000

# Tip kontrolü
npm run typecheck

# Lint
npm run lint

# Production build
npm run build
npm run start
```

**`.env.local` dosyası** (`apps/web_next/.env.local`):
```
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<supabase status --output env ile al>
SUPABASE_SERVICE_ROLE_KEY=<supabase status --output env ile al>
```

---

## 5. Tüm Sistemi Birden Başlat

Farklı terminallerde çalıştır:

```bash
# Terminal 1 — Supabase
supabase start

# Terminal 2 — Next.js web
cd apps/web_next && npm run dev

# Terminal 3 — Panel (Flutter Web)
cd apps/panel_flutter_web && flutter run -d chrome --web-port 50809 --target lib/main_web.dart

# Terminal 4 — Mobile
cd apps/mobile_flutter && flutter run
```

---

## 6. OCR ve AI Menü Analizi

Sistem iki katmanlı OCR mimarisi kullanır:

### 6a. Mobil OCR (Google ML Kit) — otomatik

Mobil uygulamada fotoğraf çekince **on-device** OCR devreye girer. Ek kurulum gerekmez; Google ML Kit bağımlılığı `pubspec.yaml` içinde mevcut.

```
apps/mobile_flutter/lib/features/menus/data/ocr_price_extractor.dart
apps/mobile_flutter/lib/features/menus/ui/menu_ocr_flow.dart
```

### 6b. Edge Function — AI Menü Analizi

`supabase/functions/ai-menu-analyze` fonksiyonu:
1. (Opsiyonel) PaddleOCR servisine görüntü gönderir → ham metin alır
2. Ham metni OpenRouter (Llama 3.1 8B free) ile analiz eder
3. Sonuçları `menu_item_ai_analysis` tablosuna yazar

**Lokal deploy:**

```bash
# Supabase çalışıyor olmalı
supabase functions serve ai-menu-analyze --env-file supabase/.env.local
```

**`supabase/.env.local` dosyası oluştur:**

```
OPENROUTER_API_KEY=<openrouter.ai üzerinden al — ücretsiz plan yeterli>

# Opsiyonel: PaddleOCR self-hosted servis (aşağıya bak)
# PADDLE_OCR_URL=http://localhost:8765
# PADDLE_OCR_SECRET=<rastgele güçlü string>
```

**Fonksiyonu test et (curl):**

```bash
# Önce bir kullanıcı JWT token al (Supabase Studio → Authentication → Users → Copy JWT)
curl -X POST http://127.0.0.1:54321/functions/v1/ai-menu-analyze \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"job_id": "<menu_ocr_jobs tablosundan bir id>"}'
```

### 6c. PaddleOCR Servisi — opsiyonel (Docker)

PaddleOCR, sunucu taraflı yüksek doğruluklu OCR sağlar. Kurmak için:

```bash
# Docker ile PaddleOCR REST servisi başlat
docker run -d \
  --name paddleocr-service \
  -p 8765:8765 \
  -e SERVICE_SECRET=<PADDLE_OCR_SECRET ile aynı değer> \
  paddlepaddle/paddle:latest \
  python -m paddleocr.server --port 8765
```

> Not: PaddleOCR Docker image ilk çalıştırmada ~2GB indirir. Hazır olana kadar Edge Function ham metinle çalışmaya devam eder.

**Flow özeti:**

```
Mobil fotoğraf
    └─► Google ML Kit (on-device, hızlı) → fiyat çıkarımı
    └─► Supabase Storage (file_url)
            └─► Edge Function: ai-menu-analyze
                    ├─► PaddleOCR (kuruluysa) → raw_text
                    └─► OpenRouter Llama 3.1 8B → items JSON
                                └─► menu_item_ai_analysis tablosu
```

### 6d. AI Menü Görseli Oluşturma (owner panel)

`supabase/functions/ai-menu-image-gen` fonksiyonu:
1. Owner panelde menü item eklerken "AI Oluştur" sekmesine tıklanır
2. Edge Function ürün adını **Google Gemma** (`google/gemma-4-26b-a4b-it:free`) via OpenRouter'a gönderir
3. Gemma, ürün adından profesyonel yemek fotoğrafı promptu üretir
4. Prompt **Pollinations.ai** ücretsiz image gen API'sine gönderilir → görsel URL döner
5. Kullanıcı önizler, beğenirse "Kaydet" ile menu item fotoğraflarına eklenir

**Lokal çalıştırma:**

```bash
# Tüm Edge Function'ları birden çalıştır (önerilen)
supabase functions serve --env-file supabase/.env.local

# Sadece image gen fonksiyonu
supabase functions serve ai-menu-image-gen --env-file supabase/.env.local
```

**`supabase/.env.local` içine ekle** (yoksa oluştur):

```
OPENROUTER_API_KEY=<openrouter.ai → Keys → Create Key — ücretsiz plan yeterli>
```

> Pollinations.ai görsel üretimi için API key gerekmez — tamamen ücretsiz ve anonim.

**Fonksiyonu test et (curl):**

```bash
curl -X POST http://127.0.0.1:54321/functions/v1/ai-menu-image-gen \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"item_name": "Mercimek Çorbası"}'

# Beklenen yanıt:
# { "ok": true, "image_url": "https://image.pollinations.ai/prompt/...", "prompt": "..." }
```

**Remote deploy (production):**

```bash
supabase functions deploy ai-menu-image-gen
# Env değişkenini production'a ekle:
supabase secrets set OPENROUTER_API_KEY=<key>
```

**Flow özeti:**

```
Owner panel → Menü item fotoğraf ekle → "AI Oluştur" sekmesi
    └─► Edge Function: ai-menu-image-gen
            ├─► OpenRouter Gemma 4 26B → food photography prompt
            └─► Pollinations.ai (flux-realism) → 512×512 görsel URL
                        └─► menu_item_photos tablosuna kaydedilir
```

---

## 8. Veritabanı

```bash
# Migration uygula (local)
supabase db push --local

# Remote Supabase'den schema çek (proje aktifken)
SUPABASE_DB_PASSWORD=<şifre> supabase db pull --schema public,auth,storage

# DB sıfırla (tüm migration'ları baştan uygular)
supabase db reset
```

---

## 9. Doğrulama Komutları

```bash
# Flutter analiz
flutter analyze                        # mobile veya panel dizininde

# Next.js
cd apps/web_next
npm run typecheck
npm run lint

# L10n denetimi
node tools/l10n_audit.mjs
```

---

## Kaynak Dökümanlar

- `docs/SYSTEM_OVERVIEW.md` — Mimari genel bakış
- `docs/ARCHITECTURE_AUDIT.md` — Güçlü yönler ve riskler
- `docs/DATABASE_REVIEW.md` — Tablo grupları, RPC listesi
- `docs/ADMIN_OWNER_GAP_ANALYSIS.md` — Özellik durum matrisi
- `docs/SCALING_ROADMAP.md` — 3 aşamalı büyüme planı
- `CLAUDE.md` — Claude/AI çalışma notları
- `AGENTS.md` — Ajan mimarisi kuralları
