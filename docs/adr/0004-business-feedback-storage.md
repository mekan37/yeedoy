# ADR-0004: İşletme Geri Bildirim Formu Depolama

**Durum:** Kabul edildi  
**Tarih:** 2026-04-22  
**Karar verenler:** Geliştirme ekibi

## Bağlam

Müşterilerin dijital menü hakkında geri bildirim vermesi isteniyor (rating, kısa metin, kategori). Next.js web uygulamasına basit bir form ekleniyor. Veri nerede depolanacak?

## Değerlendirilen Alternatifler

1. **Supabase tablosu `menu_feedback`** — Doğrudan Supabase insert, RLS ile korumalı.
2. **Harici form servisi (Typeform, Tally vb.)** — 3rd party bağımlılık.
3. **Next.js route handler → email** — SMTP ile bildirim, kalıcı depolama yok.

## Karar

**Seçenek 1**: Supabase `menu_feedback` tablosu. Next.js route handler (`/api/feedback`) IP bazlı rate-limit (5 istek / dakika) ve zod doğrulama ile veriyi insert eder.

## Tablo Yapısı

```sql
CREATE TABLE menu_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  rating smallint CHECK (rating BETWEEN 1 AND 5),
  category text CHECK (category IN ('menu','price','service','app','other')),
  message text CHECK (char_length(message) <= 500),
  created_at timestamptz DEFAULT now()
);
-- Anonim insert izni; SELECT sadece service_role
ALTER TABLE menu_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_insert" ON menu_feedback FOR INSERT TO anon WITH CHECK (true);
```

## Gerekçe

- Seçenek 2 bağımlılık getirir, veri sahipliği yok.
- Seçenek 3 kalıcı analiz imkânı sunmaz.
- Supabase ekosistemi mevcut; yeni bağımlılık gerektirmez.

## Sonuçlar

**Olumlu:** Mevcut Supabase RBAC + admin panel'den veri görülebilir.  
**Olumsuz:** Admin panel'e `menu_feedback` sayfası eklenmedikçe veri yalnızca SQL ile okunabilir (teknik borç kabul edildi).

## Kısıtlama

Next.js içine owner/admin CRUD taşınmaz (CLAUDE.md kuralı). Admin görünümü sadece Supabase Studio veya panel Flutter Web üzerinden yapılır.
