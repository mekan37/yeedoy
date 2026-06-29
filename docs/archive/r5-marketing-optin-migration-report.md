# R-5 Pazarlama E-posta İzni — Migration Özet Raporu

**Tarih:** 2026-06-20
**Hazırlayan:** postgres-pro
**Kapsam:** Yalnızca DB migration katmanı. Flutter UI, Next.js web ve edge function kapsam dışıdır.

---

## Oluşturulan Dosyalar

| Dosya | Konum |
|---|---|
| `20260620000001_user_profiles_marketing_email_opt_in.sql` | `supabase/migrations/` |
| `20260620000002_r5_marketing_email_rpcs.sql` | `supabase/migrations/` |

Sıralama kesindir: 20260620000001 önce, 20260620000002 sonra uygulanmalıdır.

---

## Degisen Tablolar

### public.user_profiles

Eklenen sütunlar:

| Sütun | Tip | Default | Nullable |
|---|---|---|---|
| `marketing_email_opt_in` | `boolean NOT NULL` | `false` | hayır |
| `marketing_email_opted_in_at` | `timestamptz` | `NULL` | evet |

`ADD COLUMN IF NOT EXISTS` kullanildi — idempotent, tekrar uygulanabilir.

Mevcut kullanicilar otomatik opt-in yapilmaz; DEFAULT false ile opt-out baslarlar.

Mevcut `profiles_update_own` policy yeni sutunlari otomatik kapsar. Ek RLS policy gerekmez.

### public.business_follows

Eklenen RLS policy (guvenlick acigi kapatma):

```sql
CREATE POLICY "business_follows_update_own"
  ON public.business_follows
  FOR UPDATE TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

Tabloda mevcut SELECT / INSERT / DELETE policy'leri korundu. Hicbir policy silmedi.

---

## Eklenen RPC'ler

### 1. get_my_notification_preferences_v1

```sql
CREATE OR REPLACE FUNCTION public.get_my_notification_preferences_v1()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
```

- `auth.uid() IS NULL` → P0002 unauthorized
- `user_profiles` kaydı yoksa `{marketing_email_opt_in: false, marketing_email_opted_in_at: null}` doner
- GRANT: `authenticated`

### 2. update_my_marketing_email_opt_in_v1

```sql
CREATE OR REPLACE FUNCTION public.update_my_marketing_email_opt_in_v1(
  p_value boolean
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

- `auth.uid() IS NULL` → P0002 unauthorized
- `p_value = NULL` → P0003 validation_error
- `p_value = true` → `marketing_email_opt_in = true`, `marketing_email_opted_in_at = now()`
- `p_value = false` → `marketing_email_opt_in = false`, `marketing_email_opted_in_at = NULL`
- `business_follows` tablosuna DOKUNMAZ
- GRANT: `authenticated`

### 3. update_business_follow_email_subscription_v1

```sql
CREATE OR REPLACE FUNCTION public.update_business_follow_email_subscription_v1(
  p_business_id uuid,
  p_subscribed  boolean
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

- `auth.uid() IS NULL` → P0002 unauthorized
- Parametreler NULL ise → P0003 validation_error
- Takip iliskisi yoksa → P0001 not_found
- `business_follows.is_subscribed_email` gunceller
- `user_profiles.marketing_email_opt_in` alanina DOKUNMAZ
- GRANT: `authenticated`

---

## Eklenen RLS Policy

| Tablo | Policy Adi | Komut | Kosul |
|---|---|---|---|
| `public.business_follows` | `business_follows_update_own` | `FOR UPDATE TO authenticated` | `USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())` |

Bu policy mevcut INSERT / SELECT / DELETE policy'leri etkilemez.

---

## Rollback Plani

Migration geri alinmasi gerekirse asagidaki adimlari yeni bir migration dosyasi olarak uygula:

```sql
-- 1. RPC'leri kaldir
DROP FUNCTION IF EXISTS public.get_my_notification_preferences_v1();
DROP FUNCTION IF EXISTS public.update_my_marketing_email_opt_in_v1(boolean);
DROP FUNCTION IF EXISTS public.update_business_follow_email_subscription_v1(uuid, boolean);

-- 2. business_follows UPDATE policy'yi kaldir
DROP POLICY IF EXISTS "business_follows_update_own" ON public.business_follows;

-- 3. Opt-in veriyi yedekle (sutun drop oncesi)
CREATE TABLE public._backup_marketing_email_opt_in AS
  SELECT user_id, marketing_email_opt_in, marketing_email_opted_in_at
  FROM public.user_profiles WHERE marketing_email_opt_in = true;

-- 4. user_profiles sutunlarini kaldir (UYARI: veri kaybi)
ALTER TABLE public.user_profiles
  DROP COLUMN IF EXISTS marketing_email_opted_in_at,
  DROP COLUMN IF EXISTS marketing_email_opt_in;
```

Adim 3 (veri yedegi) sutun drop'undan ONCE calistirilmalidir.

---

## Flutter ve Web Handoff Notu

Bu migration dosyalari yalnizca veritabani katmanini olusturur. Olusan RPC'ler asagidaki agentlar tarafindan kullanilacaktir:

**flutter-expert:** Kullanilacak dosyalar:
- `uygulamalar/mobil/lib/features/legal/legal_repository.dart` — `update_my_marketing_email_opt_in_v1` ve `get_my_notification_preferences_v1`
- `uygulamalar/mobil/lib/features/legal/ui/legal_acceptance_page.dart` — opt-in toggle kaydi
- `uygulamalar/mobil/lib/features/notifications/ui/notification_preferences_page.dart` — tercih ekrani
- `uygulamalar/mobil/lib/features/business/data/business_profile_repository.dart` — `update_business_follow_email_subscription_v1`

**nextjs-developer:** Kullanilacak RPC:
- `update_business_follow_email_subscription_v1` — web unsubscribe endpoint (`/api/unsubscribe/route.ts`)
- `get_my_notification_preferences_v1` — tercih sayfasi API route handler

Detayli RPC cagri ornekleri ve Flutter entegrasyon adimlarinin tamami:
`docs/legal/r5-marketing-optin-db-implementation-report.md` — Bolum 12

---

*Detayli guvenlick analizi, risk degerlendirmesi ve production oncesi dogrulama sorgulari icin:*
`docs/legal/r5-marketing-optin-db-implementation-report.md`
