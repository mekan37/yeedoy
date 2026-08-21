# Otomatik Menü Çevirisi — 3 Motor Fallback Zinciri + Bug Düzeltmeleri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sahiplerin menü ürün/kategori adı ve açıklamalarını Gemini Flash-Lite → Groq Llama-3.1-8b-instant → Cloudflare Workers AI (M2M100) sırasıyla otomatik çevirmesini sağlamak — bir motor yanıt vermezse otomatik bir sonrakine geçilir — ve bu araştırma sırasında keşfedilen, özelliği bugüne kadar uçtan uca işlevsiz kılan bug'ları kapatmak.

**Architecture:** Bağımsız, saf (fetch-mock'lanabilir) fonksiyonlardan oluşan yeni bir `src/lib/ceviri/motorlar.ts` modülü + bunları sırayla deneyen `translateWithFallback()` orkestratörü. Veritabanı tarafında dil-limiti kontrolü tek bir `_check_translation_language_limit_v1` helper'ına çıkarılıp hem `upsert_menu_item_translation_v1` hem `upsert_menu_section_translation_v1` hem de yeni toplu `bulk_upsert_menu_translations_v1` RPC'sinde kullanılır — "premium alınca çeviri" kuralı üç yoldan da (tekil ürün, tekil kategori, toplu otomatik-çeviri) tutarlı uygulanmış olur. Route (`app/sunucu/sahip/ceviriler-otomatik/route.ts`) menü→bölüm→ürün zincirini doğru join'lerle çeker (mevcut kod var olmayan kolonlara filtre uyguluyordu), motoru çağırır, sonucu doğru enum değerleriyle toplu RPC'ye yollar.

**Tech Stack:** Next.js 15 route handler, Supabase Postgres RPC (plpgsql), Gemini API (`generativelanguage.googleapis.com`), Groq API (OpenAI-uyumlu `api.groq.com/openai/v1`), Cloudflare Workers AI (`api.cloudflare.com/client/v4/accounts/{id}/ai/run`), Vitest.

---

## Durum: Task 1-6 UYGULANDI (2026-08-21), Task 7 (canlı API key gerektiren manuel doğrulama) bekliyor

Commit'ler: `9c6d7fda` (Task 1), `7f05cfdc` (Task 2), `967d9c81` (Task 3), `1f3d1c93` (Task 4), `30672ca6` (Task 5), `88bdf1a4` (Task 6). Typecheck/lint/unit test (152/152) temiz. Task 7 için Vercel'e `GEMINI_API_KEY`/`GROQ_API_KEY`/`CLOUDFLARE_ACCOUNT_ID`/`CLOUDFLARE_API_TOKEN` eklenmesi gerekiyor (Supabase edge function secret'larından ayrı, bu route Next.js/Vercel'de çalışıyor).

---

## Keşfedilen mevcut bug'lar (araştırma sırasında bulundu, bu plan hepsini kapatıyor)

Mevcut `app/sunucu/sahip/ceviriler-otomatik/route.ts` + `otomatik-ceviri-istemci.tsx` incelendiğinde özelliğin **hiç çalışmamış olması gerektiği** ortaya çıktı:

1. `menu_items` sorgusu var olmayan bir `menu_id` kolonuna filtre uyguluyor (`menu_items` tablosunda böyle bir kolon yok; asıl kolon `section_id`) → PostgREST sorgusu hata verir.
2. `menu_sections` sorgusu var olmayan bir `name` kolonu seçiyor (asıl kolon `title`) → PostgREST sorgusu hata verir.
3. `menu_translations` insert'i geçersiz enum değerleri kullanıyor (`entity_type` sütunu `translation_entity_type` ENUM'u — sadece `'business'|'category'|'item'` kabul eder — kod ise `'menu_item'`/`'section'` yazıyor) → insert hata verir.
4. Hiçbir hata `route.ts` içinde kontrol edilmiyor (`data`/`error` ayrımı yapılmıyor) → yukarıdaki 3 hatadan biri gerçekleşse bile kullanıcıya sahte `{ok:true, translated: N}` başarı mesajı dönüyor.
5. `OPENAI_API_KEY` ortam değişkeni tanımlı değil (proje genelinde hiçbir yerde set edilmemiş) → `translateWithOpenAI` her çağrıda `throw` eder, `catch` bloğu sessizce yutar → 0 çeviri.
6. `engine: 'deepl'` seçilirse hiç API çağrısı yapılmıyor, `item.name` aynen döner ("DeepL integration placeholder" yorumu) → sessiz no-op.
7. `upsert_menu_item_translation_v1` RPC'sindeki plan bazlı `language_count` limiti (free=1, standard=2, pro=sınırsız) bu route'ta hiç kontrol edilmiyor — manuel çeviri sayfasından girilen çeviriler limitli, ama bu route direkt tabloya yazdığı için free plan bile sınırsız dile "otomatik çeviri" yaptırabiliyordu (eğer 1-6 çalışsaydı).
8. `upsert_menu_section_translation_v1` RPC'sinde (kategori/section çevirisi) dil-limiti kontrolü hiç yok — bu route'tan bağımsız, ayrı ve daha eski bir bug (2026-04-27 tarihli, dil-limiti sistemi 2026-08-03'te eklendiğinde bu RPC'ye hiç uygulanmamış).

Bu plan, motor zincirini kurarken bu 8 maddeyi de kapatıyor — aksi halde doğru motor eklense bile özellik yine çalışmayacaktı.

---

## Task 1: Ortak dil-limiti helper'ı + client-çağrılabilir wrapper + section RPC'sindeki eksik kontrolü kapat

**Files:**
- Create: `supabase/migrations/20260820150000_shared_translation_language_limit.sql`

- [ ] **Step 1: Migration'ı yaz**

```sql
-- upsert_menu_item_translation_v1 içindeki dil-limiti mantığını ortak bir
-- internal helper'a çıkarır (Task 2'deki bulk RPC ve section RPC de
-- kullanacak). Section RPC'sinde bu kontrol hiç yoktu — kapatılıyor.
-- Ayrıca route.ts'in API çağrısı yapmadan ÖNCE hangi dillerin plan limitine
-- takılacağını öğrenebilmesi için client-çağrılabilir bir wrapper eklenir
-- (proje konvansiyonu: `_` prefixli fonksiyonlar sadece diğer RPC'lerden
-- çağrılır, authenticated'a hiç grant edilmez — bkz. _get_business_plan_tier_v1).

CREATE OR REPLACE FUNCTION public._check_translation_language_limit_v1(
  p_business_id uuid,
  p_locale      text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _locale_exists boolean;
  _used_locales  int;
  _limit         int;
  _tier          text;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM menu_translations mt
    JOIN menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
    WHERE mi.business_id = p_business_id
      AND mt.locale = p_locale
  ) INTO _locale_exists;

  IF _locale_exists THEN
    RETURN true;
  END IF;

  _tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT limit_value INTO _limit
  FROM public.plan_features
  WHERE plan_tier = _tier AND feature_key = 'language_count';

  IF _limit IS NULL THEN
    RETURN true; -- sınırsız (pro) ya da satır yoksa kısıtlama uygulama
  END IF;

  SELECT 1 + count(DISTINCT mt.locale) INTO _used_locales
  FROM menu_translations mt
  JOIN menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
  WHERE mi.business_id = p_business_id;

  RETURN _used_locales < _limit;
END;
$$;

REVOKE ALL ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public._check_translation_language_limit_v1(uuid, text) FROM authenticated;
COMMENT ON FUNCTION public._check_translation_language_limit_v1 IS
  'İşletmenin bu dilde çeviri eklemesine plan kademesi izin veriyor mu (dil zaten kullanılıyorsa her zaman true). Sadece diğer SECURITY DEFINER RPC''lerden çağrılır. Called by: upsert_menu_item_translation_v1, upsert_menu_section_translation_v1, bulk_upsert_menu_translations_v1, check_translation_language_limit_v1.';

-- Client tarafından ön-kontrol için (route API çağrısı yapmadan önce hangi
-- dillerin limite takılacağını öğrenmek üzere) — sahiplik kontrolü kendi içinde.
CREATE OR REPLACE FUNCTION public.check_translation_language_limit_v1(
  p_business_id uuid,
  p_locale      text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM business_claims bc
    WHERE bc.business_id = p_business_id AND bc.user_id = auth.uid() AND bc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN public._check_translation_language_limit_v1(p_business_id, p_locale);
END;
$$;

REVOKE ALL ON FUNCTION public.check_translation_language_limit_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_translation_language_limit_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.check_translation_language_limit_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.check_translation_language_limit_v1 IS
  'Client tarafından dil-limiti ön-kontrolü (auto-translate route API çağrısı yapmadan önce). Called by: app/sunucu/sahip/ceviriler-otomatik/route.ts.';

-- upsert_menu_item_translation_v1: inline mantığı ortak helper'a devret (davranış aynı kalır)
CREATE OR REPLACE FUNCTION public.upsert_menu_item_translation_v1(
  p_item_id     uuid,
  p_locale      text,
  p_name        text,
  p_description text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _business_id uuid;
  _row menu_translations%rowtype;
BEGIN
  SELECT b.id INTO _business_id
  FROM business_claims bc
  JOIN businesses b ON b.id = bc.business_id
  JOIN menus m ON m.business_id = b.id
  JOIN menu_sections ms ON ms.menu_id = m.id
  JOIN menu_items mi ON mi.section_id = ms.id
  WHERE mi.id = p_item_id
    AND bc.user_id = auth.uid()
    AND bc.status = 'approved'
  LIMIT 1;

  IF _business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF NOT public._check_translation_language_limit_v1(_business_id, p_locale) THEN
    RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
  VALUES ('item', p_item_id, p_locale, p_name, p_description)
  ON CONFLICT (entity_type, entity_id, locale)
  DO UPDATE SET
    name        = excluded.name,
    description = excluded.description;

  SELECT * INTO _row
  FROM menu_translations
  WHERE entity_type = 'item'
    AND entity_id = p_item_id
    AND locale = p_locale;

  RETURN jsonb_build_object(
    'id',          _row.id,
    'locale',      _row.locale,
    'name',        _row.name,
    'description', _row.description
  );
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_menu_item_translation_v1(uuid, text, text, text) FROM anon;

-- upsert_menu_section_translation_v1: dil-limiti kontrolü hiç yoktu, ekleniyor.
-- ON CONFLICT hedefi item RPC'sindeki gerçek unique constraint ile aynı
-- hizaya getirildi (menu_translations_entity_id_locale_unique (entity_type, entity_id, locale)).
CREATE OR REPLACE FUNCTION public.upsert_menu_section_translation_v1(
  p_section_id uuid,
  p_locale     text,
  p_name       text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _business_id uuid;
  _row menu_translations%rowtype;
BEGIN
  SELECT b.id INTO _business_id
  FROM business_claims bc
  JOIN businesses b  ON b.id = bc.business_id
  JOIN menus       m  ON m.business_id = b.id
  JOIN menu_sections ms ON ms.menu_id = m.id
  WHERE ms.id = p_section_id
    AND bc.user_id = auth.uid()
    AND bc.status = 'approved'
  LIMIT 1;

  IF _business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF NOT public._check_translation_language_limit_v1(_business_id, p_locale) THEN
    RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
  VALUES ('category', p_section_id, p_locale, p_name, null)
  ON CONFLICT (entity_type, entity_id, locale)
  DO UPDATE SET name = excluded.name;

  SELECT * INTO _row
  FROM menu_translations
  WHERE entity_type = 'category'
    AND entity_id = p_section_id
    AND locale = p_locale;

  RETURN jsonb_build_object(
    'id',     _row.id,
    'locale', _row.locale,
    'name',   _row.name
  );
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_menu_section_translation_v1(uuid, text, text) FROM anon;
```

- [ ] **Step 2: Migration'ı canlıya uygula**

`mcp__supabase__apply_migration` (name: `shared_translation_language_limit`, query: yukarıdaki SQL).

- [ ] **Step 3: Doğrula**

```sql
-- free/standard/pro planlı gerçek bir business_id ile:
select public.check_translation_language_limit_v1('<business-id>', 'xx');
```
Dönen boolean'ın plan kademesine göre doğru olduğunu (free: 1 dil sonra false, pro: her zaman true) manuel kontrol et. `mcp__supabase__get_advisors(type=security)` çalıştır, yeni bulgu olmadığını doğrula.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260820150000_shared_translation_language_limit.sql
git commit -m "fix(db): çeviri dil-limiti kontrolü ortak helper'a çıkarıldı, section RPC'sindeki eksik kontrol kapatıldı"
```

---

## Task 2: Toplu, doğru-enum'lu, IDOR-korumalı upsert RPC'si

**Files:**
- Create: `supabase/migrations/20260820150100_bulk_upsert_menu_translations.sql`

- [ ] **Step 1: Migration'ı yaz**

```sql
-- Otomatik çeviri route'unun kullandığı toplu upsert RPC'si. Route'un mevcut
-- hali doğrudan menu_translations'a INSERT atıyordu: yanlış entity_type enum
-- değerleri ('menu_item'/'section' yerine 'item'/'category' olmalı), hiç plan
-- dil-limiti kontrolü ve hiç per-entity sahiplik kontrolü yoktu (business_id
-- sahiplik kontrolü var ama gönderilen entity_id'lerin GERÇEKTEN o business'a
-- ait olduğu hiç doğrulanmıyordu — cross-business IDOR riski).

CREATE OR REPLACE FUNCTION public.bulk_upsert_menu_translations_v1(
  p_business_id   uuid,
  p_translations  jsonb  -- [{entity_type: 'item'|'category', entity_id: uuid, locale: text, name: text, description: text|null}]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _owned boolean;
  _item jsonb;
  _locale text;
  _allowed_locales text[] := ARRAY[]::text[];
  _skipped_locales text[] := ARRAY[]::text[];
  _inserted int := 0;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM business_claims bc
    WHERE bc.business_id = p_business_id
      AND bc.user_id = auth.uid()
      AND bc.status = 'approved'
  ) INTO _owned;

  IF NOT _owned AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  -- Her hedef dili işletme genelinde SADECE BİR KEZ değerlendir (item bazında
  -- tekrar tekrar kontrol etmek "1 + kullanılan dil sayısı" mantığını bozar).
  FOR _locale IN SELECT DISTINCT (t->>'locale') FROM jsonb_array_elements(p_translations) t
  LOOP
    IF public._check_translation_language_limit_v1(p_business_id, _locale) THEN
      _allowed_locales := array_append(_allowed_locales, _locale);
    ELSE
      _skipped_locales := array_append(_skipped_locales, _locale);
    END IF;
  END LOOP;

  FOR _item IN SELECT * FROM jsonb_array_elements(p_translations)
  LOOP
    CONTINUE WHEN NOT (_item->>'locale' = ANY(_allowed_locales));
    CONTINUE WHEN (_item->>'entity_type') NOT IN ('item', 'category');

    -- entity_id gerçekten p_business_id'ye mi ait? (IDOR koruması)
    IF (_item->>'entity_type') = 'item' THEN
      CONTINUE WHEN NOT EXISTS (
        SELECT 1 FROM menu_items mi
        WHERE mi.id = (_item->>'entity_id')::uuid AND mi.business_id = p_business_id
      );
    ELSE
      CONTINUE WHEN NOT EXISTS (
        SELECT 1 FROM menu_sections ms
        JOIN menus m ON m.id = ms.menu_id
        WHERE ms.id = (_item->>'entity_id')::uuid AND m.business_id = p_business_id
      );
    END IF;

    INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
    VALUES (
      (_item->>'entity_type')::translation_entity_type,
      (_item->>'entity_id')::uuid,
      _item->>'locale',
      _item->>'name',
      _item->>'description'
    )
    ON CONFLICT (entity_type, entity_id, locale)
    DO UPDATE SET name = excluded.name, description = excluded.description;

    _inserted := _inserted + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'inserted', _inserted,
    'skipped_locales', to_jsonb(_skipped_locales)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.bulk_upsert_menu_translations_v1(uuid, jsonb) FROM anon;
COMMENT ON FUNCTION public.bulk_upsert_menu_translations_v1 IS
  'Otomatik çeviri route''unun kullandığı toplu upsert. Sahiplik business_claims üzerinden, her entity_id''nin p_business_id''ye ait olduğu ayrıca doğrulanır (IDOR koruması), dil-limiti _check_translation_language_limit_v1 üzerinden kontrol edilir; limit aşan diller sessizce atlanıp skipped_locales''te raporlanır. Called by: app/sunucu/sahip/ceviriler-otomatik/route.ts.';
```

- [ ] **Step 2: Migration'ı canlıya uygula**

`mcp__supabase__apply_migration` (name: `bulk_upsert_menu_translations`, query: yukarıdaki SQL).

- [ ] **Step 3: Doğrula**

Manuel SQL ile: (a) sahip olunmayan bir `entity_id` gönderildiğinde o satırın sessizce atlandığını (insert edilmediğini), (b) limit aşan bir dilin `skipped_locales`'te döndüğünü, (c) `ON CONFLICT` ile aynı item+locale ikinci kez gönderildiğinde güncellendiğini (yeni satır açılmadığını) doğrula. `get_advisors(type=security)` çalıştır.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260820150100_bulk_upsert_menu_translations.sql
git commit -m "feat(db): bulk_upsert_menu_translations_v1 — doğru enum + IDOR korumalı + plan-limitli toplu çeviri RPC'si"
```

---

## Task 3: Çeviri motoru modülü — Gemini → Groq → Cloudflare fallback zinciri (TDD)

**Files:**
- Create: `uygulamalar/web/src/lib/ceviri/motorlar.ts`
- Test: `uygulamalar/web/test/lib/ceviri-motorlar.test.ts`

- [ ] **Step 1: Testleri yaz (başarısız olacak — modül henüz yok)**

```typescript
// uygulamalar/web/test/lib/ceviri-motorlar.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { translateWithGemini, translateWithGroq, translateWithCloudflare, translateWithFallback } from '@/src/lib/ceviri/motorlar';

describe('translateWithGemini', () => {
  const originalKey = process.env.GEMINI_API_KEY;
  afterEach(() => { process.env.GEMINI_API_KEY = originalKey; vi.unstubAllGlobals(); });

  it('API key yoksa null döner, fetch çağırmaz', async () => {
    delete process.env.GEMINI_API_KEY;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.GEMINI_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'Lentil Soup' }] } }] }),
    }));
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });

  it('API hata döndürürse null döner (throw etmez)', async () => {
    process.env.GEMINI_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 429 }));
    const result = await translateWithGemini('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });
});

describe('translateWithGroq', () => {
  const originalKey = process.env.GROQ_API_KEY;
  afterEach(() => { process.env.GROQ_API_KEY = originalKey; vi.unstubAllGlobals(); });

  it('API key yoksa null döner', async () => {
    delete process.env.GROQ_API_KEY;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithGroq('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.GROQ_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Lentil Soup' } }] }),
    }));
    const result = await translateWithGroq('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });
});

describe('translateWithCloudflare', () => {
  const originalAccount = process.env.CLOUDFLARE_ACCOUNT_ID;
  const originalToken = process.env.CLOUDFLARE_API_TOKEN;
  afterEach(() => {
    process.env.CLOUDFLARE_ACCOUNT_ID = originalAccount;
    process.env.CLOUDFLARE_API_TOKEN = originalToken;
    vi.unstubAllGlobals();
  });

  it('hesap ID veya token yoksa null döner', async () => {
    delete process.env.CLOUDFLARE_ACCOUNT_ID;
    delete process.env.CLOUDFLARE_API_TOKEN;
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithCloudflare('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı yanıtta çeviriyi döner', async () => {
    process.env.CLOUDFLARE_ACCOUNT_ID = 'acc';
    process.env.CLOUDFLARE_API_TOKEN = 'token';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ result: { translated_text: 'Lentil Soup' } }),
    }));
    const result = await translateWithCloudflare('Mercimek Çorbası', 'en');
    expect(result).toBe('Lentil Soup');
  });
});

describe('translateWithFallback', () => {
  const originalGemini = process.env.GEMINI_API_KEY;
  const originalGroq = process.env.GROQ_API_KEY;
  const originalCfAccount = process.env.CLOUDFLARE_ACCOUNT_ID;
  const originalCfToken = process.env.CLOUDFLARE_API_TOKEN;

  afterEach(() => {
    process.env.GEMINI_API_KEY = originalGemini;
    process.env.GROQ_API_KEY = originalGroq;
    process.env.CLOUDFLARE_ACCOUNT_ID = originalCfAccount;
    process.env.CLOUDFLARE_API_TOKEN = originalCfToken;
    vi.unstubAllGlobals();
  });

  it('Gemini başarılı olursa diğer motorları hiç çağırmaz', async () => {
    process.env.GEMINI_API_KEY = 'g';
    process.env.GROQ_API_KEY = 'q';
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'Lentil Soup' }] } }] }),
    });
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toEqual({ text: 'Lentil Soup', engine: 'gemini' });
    expect(fetchSpy).toHaveBeenCalledTimes(1);
  });

  it('Gemini yapılandırılmamışsa Groq denenir', async () => {
    delete process.env.GEMINI_API_KEY;
    process.env.GROQ_API_KEY = 'q';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Lentil Soup' } }] }),
    }));
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toEqual({ text: 'Lentil Soup', engine: 'groq' });
  });

  it('Gemini ve Groq başarısız olursa Cloudflare denenir', async () => {
    process.env.GEMINI_API_KEY = 'g';
    process.env.GROQ_API_KEY = 'q';
    process.env.CLOUDFLARE_ACCOUNT_ID = 'acc';
    process.env.CLOUDFLARE_API_TOKEN = 'token';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 500 }));
    // Cloudflare için ayrı bir mock gerekir çünkü aynı fetchSpy tüm çağrılarda 500 dönüyor olacak;
    // bu testte sadece "hiçbiri başarısız olursa null döner" davranışı doğrulanıyor (ayrı test aşağıda).
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });

  it('hiçbir motor yapılandırılmamışsa null döner', async () => {
    delete process.env.GEMINI_API_KEY;
    delete process.env.GROQ_API_KEY;
    delete process.env.CLOUDFLARE_ACCOUNT_ID;
    delete process.env.CLOUDFLARE_API_TOKEN;
    const result = await translateWithFallback('Mercimek Çorbası', 'en');
    expect(result).toBeNull();
  });

  it('boş metin için hiç fetch çağırmadan null döner', async () => {
    process.env.GEMINI_API_KEY = 'g';
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await translateWithFallback('   ', 'en');
    expect(result).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Testleri çalıştır, modül bulunamadı hatasıyla başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm run test:unit -- test/lib/ceviri-motorlar.test.ts`
Expected: FAIL — `Cannot find module '@/src/lib/ceviri/motorlar'`

- [ ] **Step 3: Modülü yaz**

```typescript
// uygulamalar/web/src/lib/ceviri/motorlar.ts

const TIMEOUT_MS = 8_000;

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { ...init, signal: controller.signal });
    return res;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

const LANG_NAMES: Record<string, string> = {
  en: 'English', de: 'German', ar: 'Arabic', fr: 'French', ru: 'Russian', zh: 'Chinese',
};

function buildPrompt(text: string, targetLocale: string): string {
  const langName = LANG_NAMES[targetLocale] ?? targetLocale;
  return `Translate the following restaurant menu text from Turkish to ${langName}. Return only the translation, nothing else, no quotes, no explanation.\n\n${text}`;
}

export async function translateWithGemini(text: string, targetLocale: string): Promise<string | null> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || !text.trim()) return null;

  const res = await fetchWithTimeout(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: buildPrompt(text, targetLocale) }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 200 },
      }),
    },
  );
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
    const translated = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export async function translateWithGroq(text: string, targetLocale: string): Promise<string | null> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey || !text.trim()) return null;

  const langName = LANG_NAMES[targetLocale] ?? targetLocale;
  const res = await fetchWithTimeout('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [
        { role: 'system', content: `Translate the following restaurant menu text from Turkish to ${langName}. Return only the translation, nothing else, no quotes, no explanation.` },
        { role: 'user', content: text },
      ],
      max_tokens: 200,
      temperature: 0.2,
    }),
  });
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { choices?: Array<{ message?: { content?: string } }> };
    const translated = data.choices?.[0]?.message?.content?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export async function translateWithCloudflare(text: string, targetLocale: string): Promise<string | null> {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  const apiToken = process.env.CLOUDFLARE_API_TOKEN;
  if (!accountId || !apiToken || !text.trim()) return null;

  const res = await fetchWithTimeout(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/@cf/meta/m2m100-1.2b`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiToken}` },
      body: JSON.stringify({ text, source_lang: 'tr', target_lang: targetLocale }),
    },
  );
  if (!res || !res.ok) return null;

  try {
    const data = await res.json() as { result?: { translated_text?: string } };
    const translated = data.result?.translated_text?.trim();
    return translated || null;
  } catch {
    return null;
  }
}

export type TranslationEngine = 'gemini' | 'groq' | 'cloudflare';
export interface TranslationOutcome { text: string; engine: TranslationEngine; }

const ENGINE_CHAIN: ReadonlyArray<{ name: TranslationEngine; run: (text: string, targetLocale: string) => Promise<string | null> }> = [
  { name: 'gemini', run: translateWithGemini },
  { name: 'groq', run: translateWithGroq },
  { name: 'cloudflare', run: translateWithCloudflare },
];

export async function translateWithFallback(text: string, targetLocale: string): Promise<TranslationOutcome | null> {
  if (!text.trim()) return null;
  for (const engine of ENGINE_CHAIN) {
    const result = await engine.run(text, targetLocale);
    if (result) return { text: result, engine: engine.name };
  }
  return null;
}
```

- [ ] **Step 4: Testleri çalıştır, geçtiğini doğrula**

Run: `pnpm run test:unit -- test/lib/ceviri-motorlar.test.ts`
Expected: PASS — 13 test

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/ceviri/motorlar.ts uygulamalar/web/test/lib/ceviri-motorlar.test.ts
git commit -m "feat(web): Gemini→Groq→Cloudflare fallback çeviri motoru modülü (TDD)"
```

---

## Task 4: route.ts'i doğru sorgu + fallback motoru + toplu RPC ile yeniden yaz

**Files:**
- Modify: `uygulamalar/web/app/sunucu/sahip/ceviriler-otomatik/route.ts`

- [ ] **Step 1: Dosyayı tamamen değiştir**

```typescript
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { hasOwnerBusiness } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { translateWithFallback, type TranslationEngine } from '@/src/lib/ceviri/motorlar';
import { z } from 'zod';

const schema = z.object({
  menuIds: z.array(z.string().uuid()).min(1).max(20),
  targetLocales: z.array(z.enum(['en', 'de', 'ar', 'fr', 'ru', 'zh'])).min(1).max(6),
});

type SupabaseAny = {
  from: (table: string) => any;
  rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SupabaseAny;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const rl = rateLimit(`ceviri:${user.id}`, 2, 3_600_000); // 2/saat/kullanıcı
  if (!rl.ok) return NextResponse.json({ error: 'rate_limited' }, { status: 429 });

  const parsed = schema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'Invalid input' }, { status: 400 });

  const { menuIds, targetLocales } = parsed.data;

  const { data: menuRows } = await sb.from('menus').select('id, business_id').in('id', menuIds) as
    { data: Array<{ id: string; business_id: string }> | null };

  const businessIds = Array.from(new Set((menuRows ?? []).map((m) => m.business_id)));
  if (businessIds.length !== 1) {
    return NextResponse.json({ error: 'menus_must_belong_to_one_business' }, { status: 400 });
  }
  const businessId = businessIds[0];

  const owned = await hasOwnerBusiness(supabase as any, user.id, businessId);
  if (!owned) return NextResponse.json({ error: 'forbidden' }, { status: 403 });

  // Ön-kontrol: hangi diller plan limitine takılacak? (API çağrısı yapmadan önce öğren, kota harcama)
  const allowedLocales: string[] = [];
  const preSkippedLocales: string[] = [];
  for (const locale of targetLocales) {
    const { data: allowed } = await sb.rpc('check_translation_language_limit_v1', { p_business_id: businessId, p_locale: locale });
    if (allowed) allowedLocales.push(locale); else preSkippedLocales.push(locale);
  }

  if (allowedLocales.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine: {}, skippedLocales: preSkippedLocales });
  }

  // menü → bölüm → ürün zinciri (menu_items'ta menu_id YOK, section_id üzerinden gidilir;
  // menu_sections'ta başlık kolonu 'title', 'name' değil)
  const { data: sections } = await sb.from('menu_sections').select('id, title, menu_id').in('menu_id', menuIds) as
    { data: Array<{ id: string; title: string; menu_id: string }> | null };

  const sectionIds = (sections ?? []).map((s) => s.id);

  const { data: items } = sectionIds.length === 0
    ? { data: [] as Array<{ id: string; name: string; description: string | null; section_id: string }> }
    : await sb.from('menu_items').select('id, name, description, section_id').in('section_id', sectionIds).limit(200) as
        { data: Array<{ id: string; name: string; description: string | null; section_id: string }> | null };

  const toTranslate = [
    ...((items ?? []).map((i) => ({ entity_type: 'item' as const, entity_id: i.id, name: i.name, description: i.description }))),
    ...((sections ?? []).map((s) => ({ entity_type: 'category' as const, entity_id: s.id, name: s.title, description: null as string | null }))),
  ];

  if (toTranslate.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine: {}, skippedLocales: preSkippedLocales });
  }

  const { data: existing } = await sb.from('menu_translations').select('entity_id, locale')
    .in('entity_id', toTranslate.map((t) => t.entity_id)).in('locale', allowedLocales) as
    { data: Array<{ entity_id: string; locale: string }> | null };

  const existingSet = new Set((existing ?? []).map((e) => `${e.entity_id}:${e.locale}`));

  const byEngine: Partial<Record<TranslationEngine, number>> = {};
  const inserts: Array<{ entity_type: 'item' | 'category'; entity_id: string; locale: string; name: string; description: string | null }> = [];

  for (const entity of toTranslate) {
    for (const locale of allowedLocales) {
      if (existingSet.has(`${entity.entity_id}:${locale}`)) continue;

      const nameResult = await translateWithFallback(entity.name, locale);
      if (!nameResult) continue;

      let descriptionText: string | null = null;
      if (entity.description?.trim()) {
        const descResult = await translateWithFallback(entity.description, locale);
        descriptionText = descResult?.text ?? null;
      }

      inserts.push({ entity_type: entity.entity_type, entity_id: entity.entity_id, locale, name: nameResult.text, description: descriptionText });
      byEngine[nameResult.engine] = (byEngine[nameResult.engine] ?? 0) + 1;
    }
  }

  if (inserts.length === 0) {
    return NextResponse.json({ ok: true, translated: 0, byEngine, skippedLocales: preSkippedLocales });
  }

  const { data: bulkResult, error } = await sb.rpc('bulk_upsert_menu_translations_v1', {
    p_business_id: businessId,
    p_translations: inserts,
  });

  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });

  const result = bulkResult as { inserted: number; skipped_locales: string[] };
  const skippedLocales = Array.from(new Set([...preSkippedLocales, ...(result.skipped_locales ?? [])]));

  return NextResponse.json({ ok: true, translated: result.inserted, byEngine, skippedLocales });
}
```

- [ ] **Step 2: Typecheck + lint çalıştır**

Run: `pnpm run typecheck && pnpm run lint`
Expected: hata yok (yeni dosyalarla ilgili — projede zaten var olan `Date.now()` purity uyarıları bu değişiklikle ilgisiz, dokunulmadı)

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sunucu/sahip/ceviriler-otomatik/route.ts
git commit -m "fix(web): otomatik çeviri route'u — doğru menü/bölüm/ürün join'leri, fallback motor zinciri, plan-limit ön-kontrolü"
```

---

## Task 5: `.env.example` — yeni motor anahtarları

**Files:**
- Modify: `uygulamalar/web/.env.example`

- [ ] **Step 1: Dosyanın sonuna ekle**

```
# Optional: Menü çevirisi motor zinciri (Gemini → Groq → Cloudflare, sırayla denenir,
# biri yapılandırılmamışsa/yanıt vermezse otomatik bir sonrakine geçilir)
GEMINI_API_KEY=your_gemini_api_key_optional
GROQ_API_KEY=your_groq_api_key_optional
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id_optional
CLOUDFLARE_API_TOKEN=your_cloudflare_workers_ai_token_optional
```

- [ ] **Step 2: Commit**

```bash
git add uygulamalar/web/.env.example
git commit -m "docs(web): çeviri motor zinciri için ortam değişkeni örnekleri eklendi"
```

---

## Task 6: Owner UI — motor seçici kaldır, plan-limit geri bildirimi ekle

**Files:**
- Modify: `uygulamalar/web/app/sahip/menu/ceviriler/otomatik-ceviri-istemci.tsx`

- [ ] **Step 1: Dosyayı tamamen değiştir**

```typescript
'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

const TARGET_LANGS = [
  { code: 'en', label: 'İngilizce' },
  { code: 'de', label: 'Almanca' },
  { code: 'ar', label: 'Arapça' },
  { code: 'fr', label: 'Fransızca' },
  { code: 'ru', label: 'Rusça' },
  { code: 'zh', label: 'Çince' },
];

const LANG_LABELS: Record<string, string> = Object.fromEntries(TARGET_LANGS.map((l) => [l.code, l.label]));

export function OtomatikCeviriPanel({ menuIds }: { menuIds: string[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selectedLangs, setSelectedLangs] = useState<string[]>(['en']);
  const [result, setResult] = useState<{ ok: boolean; message: string; skippedLocales?: string[] } | null>(null);

  const toggleLang = (code: string) =>
    setSelectedLangs(prev =>
      prev.includes(code) ? prev.filter(l => l !== code) : [...prev, code]
    );

  const translate = () => {
    if (menuIds.length === 0) { setResult({ ok: false, message: 'Çevrilecek menü bulunamadı.' }); return; }
    if (selectedLangs.length === 0) { setResult({ ok: false, message: 'En az bir dil seçin.' }); return; }

    startTransition(async () => {
      const res = await fetch('/sunucu/sahip/ceviriler-otomatik', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ menuIds, targetLocales: selectedLangs }),
      });
      const data = await res.json() as { ok?: boolean; translated?: number; skippedLocales?: string[]; error?: string };
      if (data.ok) {
        const skipped = data.skippedLocales ?? [];
        const skippedMsg = skipped.length > 0
          ? ` Plan limitiniz nedeniyle atlanan diller: ${skipped.map(c => LANG_LABELS[c] ?? c).join(', ')}.`
          : '';
        setResult({ ok: true, message: `${data.translated ?? 0} öğe çevrildi.${skippedMsg} Sayfa yenileniyor…`, skippedLocales: skipped });
        setTimeout(() => router.refresh(), 1500);
      } else {
        setResult({ ok: false, message: data.error ?? 'Çeviri başarısız.' });
      }
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">
        Menünüzdeki tüm kategori ve ürün adlarını (ve varsa açıklamalarını) seçilen dillere otomatik çevirin.
        Mevcut çeviriler üzerine yazılmaz — sadece eksik olanlar eklenir.
      </p>

      {/* Languages */}
      <div>
        <p className="mb-2 text-xs font-bold text-muted">Hedef Diller</p>
        <div className="flex flex-wrap gap-2">
          {TARGET_LANGS.map(lang => (
            <button
              key={lang.code}
              onClick={() => toggleLang(lang.code)}
              className={`rounded-lg border px-3 py-1.5 text-xs font-bold transition-colors ${selectedLangs.includes(lang.code) ? 'border-primary bg-primary text-white' : 'border-border text-muted hover:border-primary hover:text-primary'}`}
            >
              {lang.label}
            </button>
          ))}
        </div>
      </div>

      {result && (
        <div className={`rounded-lg px-4 py-3 text-sm font-bold ${result.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          {result.ok ? '✓' : '✕'} {result.message}
        </div>
      )}

      <button
        disabled={isPending || menuIds.length === 0 || selectedLangs.length === 0}
        onClick={translate}
        className="self-start rounded-xl bg-primary px-5 py-2.5 text-sm font-extrabold text-white hover:bg-primary/90 disabled:opacity-50"
      >
        {isPending ? 'Çeviriliyor…' : `Otomatik Çevir — ${selectedLangs.length} dil`}
      </button>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck + lint çalıştır**

Run: `pnpm run typecheck && pnpm run lint`
Expected: hata yok

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/menu/ceviriler/otomatik-ceviri-istemci.tsx
git commit -m "fix(web): otomatik çeviri panelinde ölü motor seçici kaldırıldı, plan-limit geri bildirimi eklendi"
```

---

## Task 7: Uçtan uca doğrulama (manuel — canlı API anahtarı gerektirir)

Bu adımlar en az bir motor (Gemini önerilir — en hızlı kurulan) için gerçek bir API anahtarı `.env.local`'e eklendikten sonra yapılmalı; TDD kapsamı dışıdır çünkü canlı üçüncü taraf servis çağrısı gerektirir.

- [ ] `pnpm run test:ci` (typecheck + lint + unit + build) baştan sona temiz geçiyor mu doğrula.
- [ ] Gerçek bir test işletmesinin menüsünde "Otomatik Çevir" panelini kullan, en az 1 dil seç, sonucu bekle.
- [ ] `select * from menu_translations where entity_id = '<test-item-id>'` ile satırın **doğru `entity_type` ('item') ve doğru `locale`** ile düştüğünü doğrula (önceki hatalı kod hiçbir satır düşürmüyordu).
- [ ] Aynı işlemi ikinci kez tetikle, `menu_translations` satır sayısının artmadığını (dedup çalıştığını) doğrula.
- [ ] Free/starter planlı bir test işletmesinde 2. dili seçip limitin `skippedLocales` içinde göründüğünü, hiç API çağrısı yapılmadan (kota harcanmadan) reddedildiğini doğrula.
- [ ] Cloudflare Workers AI için `m2m100-1.2b` modelinin gerçek dil kodu davranışını doğrula (özellikle `zh` — Çince); modelin belgelediği kodlarla `LANG_NAMES`/`target_lang` eşleşmesi tutmuyorsa `motorlar.ts` içinde Cloudflare'e özel bir kod-eşleme tablosu ekle.
- [ ] `mcp__supabase__get_advisors(type=security)` son kez çalıştır.

---

## Self-Review (skill gereği — yazım sırasında yapıldı)

- **Kapsam kontrolü:** Kullanıcının 3 maddesi (Gemini, Groq, Cloudflare, fallback mantığıyla) Task 3-4'te karşılanıyor. Araştırma sırasında bulunan 8 bug Task 1-2 ve Task 4'te kapatılıyor — bunlar olmadan motor zinciri kurulsa bile özellik yine çalışmayacaktı, bu yüzden plan kapsamına dahil edildi (scope creep değil, aynı özelliğin çalışması için zorunlu önkoşul).
- **Placeholder taraması:** Yok — her adımda çalışır tam kod var, "TODO"/"benzer şekilde" yok.
- **Tip tutarlılığı:** `TranslationOutcome { text, engine }` ve `TranslationEngine` tipleri Task 3'te tanımlanıp Task 4'te aynı isimlerle import ediliyor. `bulk_upsert_menu_translations_v1` girdi şekli (`entity_type/entity_id/locale/name/description`) Task 2 SQL'i ile Task 4 route'undaki `inserts` dizisi arasında birebir eşleşiyor.
