# Yeedoy API Security and Performance Audit

**Date:** 2026-05-23  
**Scope:** Full monorepo — Next.js route handlers, Supabase Edge Functions, RPC calls, direct table queries, cross-app contract consistency, write-flow hardening, performance patterns  
**Method:** Static code analysis via file reads and pattern searches. No code was modified, no migrations applied, no RLS or RPC signatures changed.

---

## 1. API Surface Discovery

### 1.1 Next.js Route Handlers

All route handlers are under `uygulamalar/web/app/`. Two parallel directory trees exist:

- `app/sunucu/` — Turkish-named route handlers (primary, actively maintained)
- `app/api/` — English-named route handlers (older or duplicate paths)

The `app/api/` subtree duplicates several routes that already exist under `app/sunucu/`. This is a maintenance risk; callers may hit either path depending on how they were wired.

| File Path | Purpose | Auth | Zod | Rate Limit | Risk |
|---|---|---|---|---|---|
| `app/sunucu/geri-bildirim/route.ts` | Anonymous + auth feedback on businesses | Optional | Yes | Yes (2 anon / 10 auth per min) | LOW |
| `app/sunucu/izleme/route.ts` | Analytics event tracking (log_event_v1 RPC) | None required | Yes | Yes (40/min IP+UA) | MEDIUM — no auth; spoofable events |
| `app/sunucu/sunum-ayarlari/route.ts` | QR Studio presentation settings upsert | Required | Yes | Yes (20/min) | LOW |
| `app/sunucu/hesap/sil/route.ts` | Account deletion (RPC + admin auth delete) | Required | No | Yes (3/day) | HIGH — see §9 |
| `app/sunucu/sahip/bildirim-gonder/route.ts` | Owner push campaign notifications | Required + ownership | Yes | Yes (3/day per identity) | MEDIUM — no rate limit by businessId |
| `app/sunucu/sahip/eposta-kampanya/route.ts` | Owner email campaign (simulated, marks sent) | Required + ownership | No — manual check only | Yes (3/hr per identity) | HIGH — see §9 |
| `app/sunucu/sahip/sms-kampanya/route.ts` | Owner SMS campaign creation | Required | Yes | None | HIGH — see §9 |
| `app/sunucu/sahip/isletmeler/route.ts` | Owner businesses list | Required | No | Yes (60/min) | LOW |
| `app/sunucu/sahip/isletmeler/[id]/route.ts` | Owner business PATCH | Required + ownership | Yes | Yes (20/min) | LOW |
| `app/sunucu/sahip/menuler/route.ts` | Owner menu list + create | Required + ownership | Yes | Yes (20–60/min) | LOW |
| `app/sunucu/sahip/menuler/[id]/route.ts` | Owner menu PATCH + DELETE | Required + ownership | Yes | Yes (10–30/min) | LOW |
| `app/sunucu/medya/yukleme/route.ts` | Media upload to Supabase Storage | Required + ownership | Yes | Yes (10/min) | LOW |
| `app/sunucu/sahip/yorumlar/yanit/route.ts` | Owner review reply CRUD | Required + ownership | Yes | Yes (10–20/min) | LOW |
| `app/sunucu/sahip/finansal-csv/route.ts` | Financial CSV export | Required | No (only owner check via helper) | None | MEDIUM — no rate limit on export |
| `app/sunucu/sahip/menu-csv/route.ts` | Menu CSV export | Required + ownership | No | None | MEDIUM — no rate limit |
| `app/sunucu/sahip/ceviriler-otomatik/route.ts` | Auto-translate menu items via OpenAI | Required | Yes | None | HIGH — see §9 |
| `app/sunucu/sahip/spesiyel/route.ts` | Set today's special | Required | Yes | Yes (30/min) | LOW |
| `app/sunucu/sahip/sadakat/route.ts` | Create loyalty program | Required | Yes | None | MEDIUM — no rate limit |
| `app/sunucu/sahip/envanter/route.ts` | Update menu item stock/availability | Required | Yes | None | HIGH — see §9 |
| `app/sunucu/sahip/siparis-listesi/route.ts` | Owner pending orders list | Required | No | None | MEDIUM |
| `app/sunucu/sahip/etkinlik/route.ts` | Owner event creation | Required | Yes | Yes | LOW |
| `app/sunucu/yonetici/moderasyon/route.ts` | Admin moderation actions | Required + is_admin | Yes | Yes (30/min) | LOW |
| `app/sunucu/yonetici/toplu-islemler/route.ts` | Admin bulk operations | Required + is_admin | Yes | None | HIGH — see §9 |
| `app/sunucu/yonetici/kullanici-rol/route.ts` | Admin role assignment | Required + is_admin | Yes | None | HIGH — see §9 |
| `app/sunucu/yonetici/feature-flags/route.ts` | Admin feature flag toggle/create | Required + is_admin | Partial | None | MEDIUM |
| `app/sunucu/yonetici/ab-test/route.ts` | Admin A/B test management | Required + is_admin | Yes | None | MEDIUM |
| `app/sunucu/yonetici/api-anahtarlari/route.ts` | Admin API key generation/revocation | Required + is_admin | Partial | None | HIGH — see §9 |
| `app/sunucu/yonetici/push-kampanyalari/route.ts` | Admin push campaign creation | Required + is_admin | Yes | None | MEDIUM |
| `app/sunucu/yonetici/raporlar-csv/route.ts` | Admin reports CSV export | Required + is_admin | No | None | HIGH — see §9 |
| `app/sunucu/yonetici/arama/route.ts` | Admin search | Required + is_admin | Yes | Yes (120/min) | LOW |
| `app/sunucu/yonetici/musteri-destek/route.ts` | Admin support tickets | Required + is_admin | Yes | None | MEDIUM |
| `app/sunucu/yonetici/fotograf-moderasyon/route.ts` | Admin photo moderation | Required + is_admin | Yes | None | LOW |
| `app/sunucu/yonetici/itirazlar/route.ts` | Admin claims list | Required + is_admin | No | Yes (60/min) | LOW |
| `app/sunucu/yonetici/dsar/route.ts` | Admin DSAR (privacy requests) | Required + is_admin | Yes | None | MEDIUM |
| `app/sunucu/b2b-export/[type]/route.ts` | B2B data export (CSV) | Required + role check | No | None | HIGH — see §9 |
| `app/sunucu/sahiplik-talebi/route.ts` | Business ownership claim submission | Required | No — manual check | None | HIGH — see §9 |
| `app/sunucu/sahiplik-kaniti-yukle/route.ts` | Ownership evidence file upload | Required | No — manual check | None | MEDIUM |
| `app/sunucu/makbuz-ocr/route.ts` | Receipt OCR (OpenAI/Replicate) | None required | No — manual check | Yes (5/min IP+UA) | HIGH — see §9 |
| `app/sunucu/masa-siparisi/route.ts` | Anonymous table order submission | None required | Yes | Yes (10/2min) | MEDIUM |
| `app/sunucu/masa-siparisi/durum/route.ts` | Update table order status | Required | Yes | None | MEDIUM |
| `app/sunucu/ortak-liste/oy/route.ts` | Collaborative list voting (IP-based) | None required | Yes | Yes (30/min) | MEDIUM — see §9 |
| `app/sunucu/koleksiyonlar/route.ts` | Create user collection | Required | Yes | Yes (10/min) | LOW |
| `app/sunucu/diyet-profili/route.ts` | Save diet profile | Required | Yes | Yes (20/min) | LOW |
| `app/sunucu/kimlik/giris/route.ts` | Login (email+password → cookie) | None (pre-auth) | Yes | Yes (8/min) | LOW |
| `app/sunucu/kimlik/rol-yonlendirme/route.ts` | Role-based redirect | Required | No | None | LOW |
| `app/sunucu/yeniden-dogrulama/route.ts` | Cache revalidation webhook | Secret-based | Yes | None | LOW |
| `app/sunucu/izleme/itme-acilisi/route.ts` | Push notification open tracking | None required | Yes | Yes | LOW |

**Duplicate/Legacy Route Handlers in `app/api/`:**  
The following paths in `app/api/` appear to mirror or partially duplicate `app/sunucu/` handlers. Their relationship to the primary handlers is unclear and they may be receiving traffic depending on how the frontend calls them:

- `app/api/admin/claims/route.ts`
- `app/api/admin/moderation/route.ts`
- `app/api/feedback/route.ts`
- `app/api/media/upload/route.ts`
- `app/api/owner/businesses/[id]/route.ts`
- `app/api/owner/businesses/route.ts`
- `app/api/owner/menus/[id]/route.ts`
- `app/api/owner/menus/route.ts`
- `app/api/presentation-settings/route.ts`
- `app/api/revalidate/route.ts`
- `app/api/track/push-open/route.ts`
- `app/api/track/route.ts`
- `app/auth/panel-handoff/route.ts`
- `app/auth/callback/route.ts`
- `app/forbidden/route.ts`
- `app/q/[code]/route.ts`
- `app/kod/[code]/route.ts`

These were not individually read. The audit treats `app/sunucu/` as the primary surface.

---

### 1.2 Supabase Edge Functions

| Function | Auth | Role Check | Input Validation | Rate Limit | Risk |
|---|---|---|---|---|---|
| `admin-api` | JWT required (Bearer) | admin or community_mod via app_metadata | RPC allowlist enforced | IP denylist checked | LOW — well-designed |
| `anti-spam-guard` | JWT required | None beyond user auth | action field validated vs RULES map | DB-backed per user+IP | LOW |
| `write-gatekeeper` | JWT required | allowed roles (user/owner/admin) | action validated; payloads validated per action | DB-backed per user+IP | LOW |
| `media-upload` | JWT required | is_admin RPC | MIME type, size, dimensions | None explicit | MEDIUM — no per-user rate limit |
| `media-upload-user` | JWT required | None (any authed user) | MIME, size, dimension, UUID check | DB + consume_rate_limit_v1 | LOW |
| `ai-menu-analyze` | JWT required | job owner_id === user.id | job_id present; job status checked | enforceRateLimit (5/user) | LOW |
| `ai-allergen-detect` | Not individually read | — | — | — | Unverified |
| `ai-ingredient-detect` | Not individually read | — | — | — | Unverified |
| `ai-nutrition-estimate` | Not individually read | — | — | — | Unverified |
| `ai-menu-image-gen` | Not individually read | — | — | — | Unverified |
| `get-exchange-rates` | None — open CORS | None | None | None | MEDIUM — unauthenticated |
| `import_places_json` | None — open CORS | None | file + fields | None | CRITICAL — see §9 |
| `push-dispatch` | JWT required | admin check for bulk; user scope enforced | ALLOWED_PUSH_TYPES allowlist | None | LOW |
| `send-push-campaign` | JWT required | business ownership or admin | campaign_id required | 1 campaign/business/day | LOW |
| `send-email-campaign` | JWT required | business ownership check | campaign_id required | 1/business/day | LOW |
| `verify-domain` | JWT required (Bearer check) | None beyond user auth | business_id + domain required | enforceRateLimit (10/hr) | LOW |
| `purge-temp-uploads` | None | None | limit field | None | HIGH — see §9 |

---

### 1.3 Supabase RPC Calls (Web)

RPCs called from `app/sunucu/` route handlers and `src/lib/`:

- `log_event_v1` — analytics tracking (izleme/route.ts)
- `delete_user_account_v1` — account deletion (hesap/sil/route.ts)
- `is_admin` — admin role check (used in ~14 route handlers)
- `submit_table_order_v1` — table order submission (masa-siparisi/route.ts)
- `update_table_order_status_v1` — order status update (masa-siparisi/durum/route.ts)
- `set_today_special_v1` — set menu item special (sahip/spesiyel/route.ts)
- `create_loyalty_program_v1` — create loyalty program (sahip/sadakat/route.ts)
- `create_collection_v1` — create user collection (koleksiyonlar/route.ts)
- `get_pending_table_orders_v1` — pending orders for owner (sahip/siparis-listesi/route.ts)
- `increment_push_campaign_open_v1` — push open tracking (izleme/itme-acilisi/route.ts)
- `estimate_campaign_segment_v1` — estimate push segment (yonetici/push-kampanyalari/route.ts)
- `get_business_hours_v1`, `get_menu_items_v1`, `get_menu_item_variants_v1`, `get_menu_item_photos_v1`, `get_menu_item_price_history_v1` — public menu reads (src/lib/)
- `can_manage_business_v1` / `can_access_business_v1` — ownership checks (src/lib/)
- `get_owner_analytics_v1`, `get_top_businesses_period_v1`, `get_business_reviews_v3` — analytics reads (src/lib/)
- `admin_get_queues_counts_v1` — admin queue dashboard (src/lib/)

RPCs called from Edge Functions:

- `is_admin`, `is_edge_ip_denied_v1` — admin-api, write-gatekeeper
- `admin_apply_user_safety_action_v1` — admin-api
- All RPCs in `ALLOWED_WRITE_RPCS` set — admin-api (33 RPCs)
- `consume_rate_limit_v1` — media-upload-user
- `record_user_risk_signal_v1`, `record_user_device_fingerprint_v1` — write-gatekeeper
- `owner_approve_price_suggestion_v1`, `owner_reject_price_suggestion_v1` — write-gatekeeper
- `dequeue_notification_dispatch_jobs_v1`, `complete_notification_dispatch_job_v1` — push-dispatch

---

### 1.4 Direct Table Queries (Web)

Notable direct `.from()` calls (not behind RPC):

- `menu_feedback` — geri-bildirim/route.ts (INSERT via service client)
- `businesses` — multiple owner/admin routes (UPDATE, SELECT)
- `menus` — sahip/menuler routes (INSERT, UPDATE, SELECT)
- `favorites` — sahip/bildirim-gonder and sahip/eposta-kampanya (SELECT followers)
- `email_campaigns` — sahip/eposta-kampanya (INSERT, UPDATE)
- `sms_campaigns` — sahip/sms-kampanya (INSERT)
- `notifications` — sahip/bildirim-gonder (INSERT)
- `reviews` — sahip/yorumlar/yanit (UPDATE)
- `business_media` — yonetici/fotograf-moderasyon and yonetici/moderasyon (UPDATE)
- `runtime_feature_flags` — yonetici/feature-flags and yonetici/ab-test (INSERT, UPDATE)
- `api_keys` — yonetici/api-anahtarlari (INSERT, UPDATE)
- `push_campaigns` — yonetici/push-kampanyalari (INSERT)
- `user_profiles` — yonetici/toplu-islemler (UPDATE)
- `owner_claims` — sahiplik-talebi (INSERT, SELECT), yonetici/itirazlar (SELECT)
- `reports` — yonetici/raporlar-csv (SELECT up to 5000)
- `user_roles` — b2b-export and send-push-campaign (SELECT for role check)
- `analytics_events` — b2b-export (SELECT up to 100,000)
- `menu_items` — sahip/ceviriler-otomatik, sahip/envanter (SELECT, UPDATE)
- `menu_sections`, `menu_translations` — sahip/ceviriler-otomatik (SELECT, INSERT)
- `user_diet_profiles` — diyet-profili (UPSERT)
- `support_tickets`, `support_ticket_messages` — yonetici/musteri-destek (SELECT, UPDATE, INSERT)
- `privacy_requests` — yonetici/dsar (UPDATE)
- `collab_list_votes` — ortak-liste/oy (DELETE, UPSERT)
- `table_order_items` — sahip/finansal-csv (SELECT)
- `bulk_op_logs` — yonetici/toplu-islemler (INSERT, fire-and-forget)

---

## 2. Next.js Route Handler Security Audit

### 2.1 Routes Missing Rate Limiting (Write Operations)

The following write-capable routes have no rate limiting, creating abuse vectors:

- `app/sunucu/sahip/sms-kampanya/route.ts` — No rate limit at all. Any authenticated business owner can create unlimited SMS campaign records. The actual SMS sending is stubbed with a TODO, but the DB record creation is live.
- `app/sunucu/sahip/envanter/route.ts` — No rate limit on menu item stock/availability updates. An owner could flood the DB with updates.
- `app/sunucu/sahip/sadakat/route.ts` — No rate limit on loyalty program creation.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — No route-level rate limit. Each call triggers up to 200 * 6 = 1,200 OpenAI API calls (200 items × 6 target locales). A single authenticated user can exhaust the OpenAI budget rapidly. The internal `setTimeout(r, 500)` every 10 items provides only a soft throttle and does not block parallel requests.
- `app/sunucu/yonetici/toplu-islemler/route.ts` — No rate limit on bulk operations affecting up to 200 entities per call.
- `app/sunucu/yonetici/kullanici-rol/route.ts` — No rate limit on role assignment.
- `app/sunucu/yonetici/api-anahtarlari/route.ts` — No rate limit on API key generation.
- `app/sunucu/sahip/finansal-csv/route.ts` — No rate limit on data export.
- `app/sunucu/sahip/menu-csv/route.ts` — No rate limit on CSV export.
- `app/sunucu/sahip/siparis-listesi/route.ts` — No rate limit; calls a separate RPC per business in a loop.
- `app/sunucu/masa-siparisi/durum/route.ts` — No rate limit on order status update.
- `app/sunucu/yonetici/musteri-destek/route.ts` — No rate limit on support ticket operations.
- `app/sunucu/yonetici/dsar/route.ts` — No rate limit on DSAR resolution.

### 2.2 Routes Missing Zod Validation

The following routes accept external input without `zod.safeParse`:

- `app/sunucu/sahip/eposta-kampanya/route.ts` — Body typed inline as `{ businessId, subject, body }` with only manual null/empty checks. No schema, no field length constraints, no validation of UUID format for `businessId`.
- `app/sunucu/sahiplik-talebi/route.ts` — Manual destructuring from `request.json()` with only basic truthy checks. No schema.
- `app/sunucu/sahiplik-kaniti-yukle/route.ts` — Manual file validation only. No zod schema.
- `app/sunucu/makbuz-ocr/route.ts` — No zod schema; uses manual `instanceof Blob` and MIME string check.
- `app/sunucu/yonetici/raporlar-csv/route.ts` — Query params used directly with no validation (status, hedef strings).
- `app/sunucu/yonetici/feature-flags/route.ts` (PATCH handler) — Body cast as `{ id: string; enabled: boolean }` without safeParse.
- `app/sunucu/yonetici/api-anahtarlari/route.ts` — Both POST and DELETE cast body without safeParse. Only manual `!body.name?.trim()` check on POST.
- `app/sunucu/sahip/siparis-listesi/route.ts` — No request body validation at all.
- `app/sunucu/sahip/finansal-csv/route.ts` — Query params `ay` and `format` used without zod.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — Has zod for input schema but no ownership verification that the caller actually owns the businesses whose menus are being translated. The `menuIds` array is fetched directly from `menu_items` without confirming the authenticated user owns those menus.
- `app/sunucu/sahip/menu-csv/route.ts` — No zod; `menuId` taken directly from query params.

### 2.3 Missing Ownership Verification

These routes authenticate the user but do not verify the user owns the resource being modified:

- `app/sunucu/sahip/envanter/route.ts` — Updates `menu_items.is_available` and `stock_count` by `itemId` with no ownership check. Any authenticated user who knows a `menu_item.id` UUID can mark any item as unavailable or set its stock to zero.
- `app/sunucu/sahip/sadakat/route.ts` — Passes `businessId` directly to the RPC without verifying ownership. The RPC (`create_loyalty_program_v1`) does return `{ error: 'forbidden' }` from the DB side, but the route handler leaks the DB error message back to the client.
- `app/sunucu/sahip/sms-kampanya/route.ts` — The SMS campaign is inserted for `bizIds[0]` only. There is no per-business ownership check. A user can insert a campaign record for any `businessId` they provide, as long as they are authenticated. The only server-side defense is whatever RLS the `sms_campaigns` table has.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — Fetches `menu_items` by `menu_id IN (menuIds)` and inserts translations without verifying the caller owns those menus.
- `app/sunucu/sahip/finansal-csv/route.ts` — Uses `getOwnerBusinesses` for the business list (safe), but the `table_order_items` query uses `.in('business_id', businessIds)` which is correct. Risk is low but no rate limit makes it a data exfiltration vector.

### 2.4 In-Memory Rate Limiter Is Not Production-Safe

`src/lib/oran-siniri.ts` (the primary rate limiter used by all Next.js route handlers) uses a `Map` stored in process memory:

```typescript
const store = new Map<string, RateLimitRecord>();
```

This means:
- In a multi-instance or serverless deployment (Vercel, containers with multiple replicas), each instance has its own independent counter. Rate limits are not shared.
- On Vercel serverless, the function instance may be cold-started frequently, resetting all counters.
- An attacker can distribute requests across instances to bypass the limit entirely.
- The `store` Map grows unbounded; there is no eviction on expired keys beyond the check at read time.

This affects all 23 routes that rely on this rate limiter, including login (`giris`), media upload, feedback, analytics, and all owner/admin write routes.

### 2.5 Role Check Inconsistencies

Admin routes use different patterns to check the admin role:

- Most routes: `await supabase.rpc('is_admin')` — uses the row-level authenticated client.
- `app/sunucu/b2b-export/[type]/route.ts`: Queries `user_roles` table directly with `.in('role', ['admin', 'superadmin'])` — a different mechanism than `is_admin` RPC. This creates inconsistency; the RPC may enforce different logic than a direct table read.

### 2.6 Service Role Key Usage in Route Handlers

The following routes create an admin Supabase client with the service role key inside the request handler:

- `app/sunucu/hesap/sil/route.ts` — Creates a `createClient` with `SUPABASE_SERVICE_ROLE_KEY` inline to call `admin.deleteUser()`. The key is only read from `process.env`; it does not leak to the client. Risk is limited to the server side but the inline admin client creation pattern should use the centralized `createSupabaseServiceClient()` helper.
- `app/sunucu/medya/yukleme/route.ts` — Uses `createSupabaseServiceClient()` correctly.
- `app/sunucu/yonetici/kullanici-rol/route.ts` — Uses `createSupabaseServiceClient()` correctly.
- `app/sunucu/yonetici/moderasyon/route.ts` — Uses `createSupabaseServiceClient()` correctly.

### 2.7 Error Message Leakage

Several routes return raw database error messages to clients:

- `app/sunucu/sahip/bildirim-gonder/route.ts` line 64: `NextResponse.json({ error: insertError.message }, { status: 500 })` — leaks Supabase error text.
- `app/sunucu/sahip/eposta-kampanya/route.ts` line 50: `NextResponse.json({ ok: false, error: kampanyaError.message }, { status: 500 })`.
- `app/sunucu/sahip/sadakat/route.ts` line 28: `NextResponse.json({ error: error.message }, { status: 500 })`.
- `app/sunucu/masa-siparisi/durum/route.ts` line 22: `NextResponse.json({ error: error.message }, { status: 500 })`.
- `app/sunucu/sahip/sms-kampanya/route.ts` line 52: `NextResponse.json({ error: error.message }, { status: 500 })`.
- `app/sunucu/yonetici/musteri-destek/route.ts` lines 40, 56, 77: `NextResponse.json({ error: error.message }, ...)`.

These expose internal DB error strings (table names, constraint names, column names) to callers.

### 2.8 Revalidation Endpoint

`app/sunucu/yeniden-dogrulama/route.ts` — Uses a shared secret from `appConfig.revalidateSecret()`. If the secret is not set, the endpoint returns 503 (good). The secret comparison is a plain string equality check with no timing-safe comparison. For a cache invalidation endpoint this is acceptable risk, but worth noting.

---

## 3. Edge Function Security Audit

### 3.1 `import_places_json` — Missing Authentication (CRITICAL)

**File:** `supabase/functions/import_places_json/index.ts`

This function uses the Supabase `SERVICE_ROLE_KEY` to upsert rows into the `businesses` table in bulk, but there is no authentication check. The function is invoked via an HTTP request; CORS is restricted to `yeedoy.com`, `panel.yeedoy.com`, and localhost, but:

- CORS headers only prevent browser-based cross-origin requests. Any non-browser client (curl, Python, Deno script) can call this endpoint from any origin by omitting or spoofing the `Origin` header.
- There is no `Authorization` header check and no JWT validation.
- A caller who can reach the function URL can insert/upsert unlimited business records into the production database using the service role key.
- The function does not use a Supabase authenticated user client at any point.

This is the single highest-severity finding in the audit. The service role key is available to the function as an environment variable; if the function URL is known or discoverable, unauthenticated callers can corrupt the business dataset.

### 3.2 `purge-temp-uploads` — Missing Authentication

**File:** `supabase/functions/purge-temp-uploads/index.ts`

No `Authorization` header check. Any unauthenticated POST request can trigger the purge job. This would allow an attacker to process and mark storage deletion queue items as processed without authorization, potentially causing premature file deletion. The `limit` parameter is capped at 200 and validated.

### 3.3 `get-exchange-rates` — Unauthenticated but Low Risk

**File:** `supabase/functions/get-exchange-rates/index.ts`

No authentication. The function only reads the `exchange_rates` table (via service client) and fetches from TCMB; it performs an upsert if rates are stale. An unauthenticated caller can trigger TCMB fetches and rate cache writes on demand. The data written is public currency rates, so the impact is low. However, the upsert means a caller can indirectly write to the DB without auth.

### 3.4 `send-push-campaign` — Ownership Check Uses Wrong Table

**File:** `supabase/functions/send-push-campaign/index.ts`

Ownership is verified by querying `business_claims` (lines 56–64). The rest of the codebase uses `owner_claims` for ownership verification (e.g., `sahiplik-talebi/route.ts` inserts into `owner_claims`; `kimlik/rol-yonlendirme/route.ts` queries `owner_claims`). This inconsistency means the campaign function may use a different or stale claims table, and an owner whose claim is in `owner_claims` (the primary table) may not pass the check in this function.

### 3.5 `send-email-campaign` — Simulates When RESEND_API_KEY Missing

**File:** `supabase/functions/send-email-campaign/index.ts`

When `RESEND_API_KEY` is not set, the function logs a warning and marks the campaign as sent with `sent_count = emails.length`. This is correct behavior for dev/staging but the code path could be triggered in production if the secret is accidentally unset or not deployed, resulting in campaigns being marked "sent" without actual delivery.

### 3.6 `media-upload` — No Explicit Rate Limit

**File:** `supabase/functions/media-upload/index.ts`

The function checks `is_admin` but has no per-user rate limit. An admin user could upload unlimited files. The WordPress API layer is described in the README as a "legacy compatibility layer" that is intentionally retained.

### 3.7 CORS Wildcard Concerns in Edge Functions

`get-exchange-rates` and `import_places_json` both define CORS with an allowed origins list and fall back to `ALLOWED_ORIGINS[0]` for unknown origins — meaning a request from a disallowed origin still receives a CORS header pointing to `yeedoy.com`. This does not create an actual cross-origin vulnerability for browsers, but the fallback behavior is misleading. A cleaner implementation would return no `Access-Control-Allow-Origin` header (or a `403`) for disallowed origins.

### 3.8 Default EDGE_RATE_LIMIT_SALT

Both `admin-api` and `write-gatekeeper` fall back to the hardcoded string `"yeedoy_default_salt"` if `EDGE_RATE_LIMIT_SALT` is not set:

```typescript
const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "yeedoy_default_salt";
```

If `EDGE_RATE_LIMIT_SALT` is missing in production, the IP hash used for rate limiting and denylist lookups becomes predictable to anyone who can read the source code, potentially allowing hash precomputation to bypass IP checks.

---

## 4. Supabase RPC / Database Contract Audit

### 4.1 `supabase as any` Pattern Is Widespread

The majority of route handlers and data fetchers cast the Supabase client to `any` before calling `.from()` or `.rpc()`. This defeats TypeScript's type safety. Fields returned from queries are also typed as `any`, meaning field-name mismatches and missing fields are not caught at compile time.

Files with the most pervasive use of `supabase as any`:
- `app/sunucu/sahip/eposta-kampanya/route.ts` — all queries
- `app/sunucu/sahip/bildirim-gonder/route.ts` — all queries
- `app/sunucu/sahip/sms-kampanya/route.ts` — all queries
- `app/sunucu/yonetici/toplu-islemler/route.ts` — all queries
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — all queries
- `app/sunucu/sahip/siparis-listesi/route.ts` — all queries

### 4.2 N+1 Pattern in `sahip/siparis-listesi`

`app/sunucu/sahip/siparis-listesi/route.ts` calls `get_pending_table_orders_v1` once per business in a sequential loop:

```typescript
for (const biz of businesses) {
  const { data } = await (supabase as any).rpc('get_pending_table_orders_v1', { p_business_id: biz.id, p_limit: 30 });
```

If an owner has 10 businesses, this is 10 sequential RPC calls. The results are then sorted in-memory. This should be replaced with a single RPC that accepts an array of business IDs or an owner ID.

### 4.3 Unbounded Export Queries

- `app/sunucu/yonetici/raporlar-csv/route.ts` — `.limit(5000)` on `reports` table. A single request can fetch 5000 rows. No pagination, no streaming. This will be slow and memory-intensive for large datasets.
- `app/sunucu/b2b-export/[type]/route.ts` — The `analytics` type fetches up to 100,000 rows in a single query with `.limit(100000)`. This is an extremely large payload that will likely timeout or OOM in a serverless environment.
- `app/sunucu/sahip/eposta-kampanya/route.ts` — `.limit(1000)` on `favorites` table for email collection. If a popular business has >1000 followers, emails are silently truncated.

### 4.4 Missing Pagination on Owner Orders List

`app/sunucu/sahip/siparis-listesi/route.ts` fetches `p_limit: 30` per business with no pagination controls. The route handler has no page/cursor parameter.

### 4.5 Hardcoded Limit Silently Truncates Email Recipients

`app/sunucu/sahip/eposta-kampanya/route.ts` line 54 uses `.limit(1000)`. If a business has more than 1,000 followers, the extra emails are silently skipped with no warning in the response. The `send-email-campaign` Edge Function handles pagination correctly (paging 1000 at a time) but the route handler equivalent does not.

### 4.6 Stale Ownership Check Mechanism in send-push-campaign

As noted in §3.4, `send-push-campaign` queries `business_claims` while the rest of the system uses `owner_claims`. Both appear to exist in the schema; if `business_claims` is a legacy table, this function may fail silently for all new owners.

### 4.7 `collab_list_votes` Uses Raw IP Hash as Voter Identifier

`app/sunucu/ortak-liste/oy/route.ts` stores the raw `identity` string (IP:UA) as `voter_ip` in the `collab_list_votes` table. The `identity` string includes the full User-Agent, making it long and inconsistently formed. It is not hashed before storage, meaning PII (IP addresses combined with UA) is stored in plaintext. This may conflict with GDPR obligations.

---

## 5. Cross-App API Contract Consistency

### 5.1 Duplicate Data Fetchers

`src/lib/db/menu-read.ts` and `src/lib/veri/menu-okuma.ts` appear to be two copies of the same module (Turkish vs. English naming). Both contain identical RPC calls (`get_business_hours_v1`, `get_menu_items_v1`, `get_menu_item_variants_v1`, `get_menu_item_photos_v1`, `get_menu_item_price_history_v1`). Similarly:

- `src/lib/db/owner/owner-analytics.ts` and `src/lib/veri/owner/sahip-analitik.ts`
- `src/lib/db/admin/admin-queue.ts` and `src/lib/veri/admin/yonetici-kuyruku.ts`

This violates the DRY principle and creates a maintenance risk where one copy is updated but not the other.

### 5.2 `canManageBusiness` vs `can_manage_business_v1` Inconsistency

`src/lib/karekod-erisimi.ts` and `src/lib/qr-access.ts` both define the same helper (`canManageBusiness`) and call the same RPC (`can_manage_business_v1`). These are Turkish and English copies of the same file. The English version (`qr-access.ts`) may have been introduced without checking if the Turkish version existed.

### 5.3 Old Branding Reference

`supabase/seed/migrate_users.sql` contains a reference to `menubak` or `Menubak` (old branding). This is in a seed/migration file and poses no runtime security risk, but indicates a leftover from a rebrand.

### 5.4 `@ts-expect-error` Suppression Hiding Missing Types

- `app/sunucu/geri-bildirim/route.ts` line 59: `// @ts-expect-error menu_feedback not yet in generated types`
- `app/sunucu/diyet-profili/route.ts` line 43: `// @ts-expect-error user_diet_profiles may not be in generated types yet`

These suppressions indicate the Supabase generated types are out of sync with the actual schema. Any query to these tables is untyped and field mismatches will be runtime errors.

---

## 6. Performance Audit

### 6.1 In-Memory Rate Limiter Leaks Memory

`src/lib/oran-siniri.ts` stores all rate limit records in a `Map` without any TTL-based eviction beyond read-time expiry. In long-lived Node.js processes (local dev, self-hosted), this map grows without bound as new `key` values accumulate. Each unique IP+UA combination adds an entry. On a serverless deployment with ephemeral functions, this is not an issue; on a long-lived server it is a memory leak.

### 6.2 Sequential RPC Calls in Owner Orders Route

Already documented in §4.2. On a busy owner account with many businesses, this creates cascading latency.

### 6.3 Auto-Translation Route Can Trigger 1,200 OpenAI Calls

`app/sunucu/sahip/ceviriler-otomatik/route.ts` iterates over up to 200 menu items × 6 target locales sequentially, calling OpenAI per item. No parallelism, no batch API, no per-route rate limit. A single POST can take minutes and cost significant API credits.

### 6.4 B2B Analytics Export (100,000 Rows)

`app/sunucu/b2b-export/[type]/route.ts` fetches up to 100,000 rows of `analytics_events` in one query. This payload will be several megabytes. The route builds the CSV in memory before returning. No streaming, no chunked response, no async export queue.

### 6.5 Push Campaign Segment Estimation Not Committed

`app/sunucu/yonetici/push-kampanyalari/route.ts` calls `estimate_campaign_segment_v1` and stores the result as `sent_count` in `push_campaigns`, but the actual campaign sending is marked as a TODO. The stored `sent_count` is the estimated count at creation time, not the actual delivered count. When the real FCM integration is added, this field will be overwritten — but there is a window where the data is misleading.

### 6.6 Analytics Tracking Route: No User ID in Event

`app/sunucu/izleme/route.ts` does not check for user authentication before logging the analytics event. The event is attributed to `businessId` and `clientId` but not to a user session. This is intentional for anonymous public menu views but means no de-duplication by user is possible at the DB level.

---

## 7. Write Flow Hardening

### 7.1 SMS Campaign Submission Without Ownership Verification

**File:** `app/sunucu/sahip/sms-kampanya/route.ts`

The authenticated user can submit a campaign for any `bizIds[0]`. The only server-side defense is RLS on the `sms_campaigns` table. No call to `hasOwnerBusiness` or equivalent. No rate limit.

**Evidence:**
```typescript
const { bizIds, segment, message, scheduledAt } = parsed.data;
// No ownership check before insert:
const { error } = await (supabase as any)
  .from('sms_campaigns')
  .insert({ business_id: bizIds[0], ... });
```

### 7.2 Inventory Update Without Ownership

**File:** `app/sunucu/sahip/envanter/route.ts`

Any authenticated user can PATCH any `menu_item` by UUID. The route handler has auth but no resource ownership check. This allows a competitor or malicious user to mark rivals' menu items as unavailable.

**Evidence:**
```typescript
const { error } = await (supabase as any)
  .from('menu_items')
  .update(update)
  .eq('id', itemId);
```

No check that `itemId` belongs to a business owned by `user.id`.

### 7.3 Email Campaign Body Not Sanitized

**File:** `app/sunucu/sahip/eposta-kampanya/route.ts`

The `body` field from the request is inserted into `email_campaigns.body` as-is. The `send-email-campaign` Edge Function appends this field as `html_body` directly into the email HTML:

```typescript
const fullHtml = campaign.html_body + unsubscribeNote;
```

If an owner can insert arbitrary HTML into `email_campaigns.body`, they can inject HTML/JavaScript into emails sent to followers — stored XSS via campaign body. The route handler's only check is `!body.body?.trim()`.

### 7.4 Claim Evidence Upload Path Is User-Controlled in Filename Extension

**File:** `app/sunucu/sahiplik-kaniti-yukle/route.ts`

```typescript
const ext = file.name.split('.').pop()?.toLowerCase() ?? 'bin';
const path = `${user.id}/${Date.now()}-kanit.${ext}`;
```

The file extension is derived from the original filename (user-supplied) rather than the MIME type. A user could upload a file with `file.type = 'image/jpeg'` but `file.name = 'evil.php'` causing the stored path to end in `.php`. Since Supabase Storage serves files from a CDN and does not execute server-side scripts, the immediate risk is low — but using the user-supplied extension is an anti-pattern.

### 7.5 Account Deletion: Admin Client Created Inline

**File:** `app/sunucu/hesap/sil/route.ts`

```typescript
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (serviceKey) {
  const { createClient } = await import('@supabase/supabase-js');
  const admin = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, serviceKey, ...);
  await admin.auth.admin.deleteUser(user.id);
}
```

If `SUPABASE_SERVICE_ROLE_KEY` is not set, `admin.auth.admin.deleteUser` is silently skipped, leaving the auth record intact while the application data is deleted. The user's account would be in a broken half-deleted state. There is no error returned in this case.

### 7.6 Collab List Vote Writes Are Anonymous

**File:** `app/sunucu/ortak-liste/oy/route.ts`

The route allows voting with no authentication. The `voter_ip` identity is used as the unique key. IP-sharing environments (NAT, corporate proxy, Cloudflare tunnel) mean multiple real users share one "voter identity," resulting in one user's vote silently overwriting another's.

### 7.7 Duplicate Translations Without Idempotency Guard

**File:** `app/sunucu/sahip/ceviriler-otomatik/route.ts`

The route checks `existingSet` to avoid re-translating items that already have a translation. However, if two concurrent requests for the same menus arrive simultaneously, both may pass the check and both may attempt to insert the same translation rows, causing a unique constraint violation (or duplicate data if no constraint exists).

---

## 8. Reliability and Error Handling

### 8.1 Fire-and-Forget Audit Log in Bulk Operations

**File:** `app/sunucu/yonetici/toplu-islemler/route.ts`

```typescript
await (supabase as any)
  .from('bulk_op_logs')
  .insert({ ... })
  .then(() => null)
  .catch(() => null);
```

The audit log insert is explicitly fire-and-forget. A failed insert is silently swallowed. This means bulk operations may not be auditable in case of DB issues.

### 8.2 No Retry on Email Campaign Send Failure

**File:** `supabase/functions/send-email-campaign/index.ts`

If a Resend batch fails (`resp.ok` is false), the function logs the error but continues to the next batch. No retry, no partial success tracking per batch. The final `sent_count` may undercount actual deliveries.

### 8.3 Push Dispatch Error Leaks FCM Response Details to API Caller

**File:** `supabase/functions/push-dispatch/index.ts`

FCM error responses are returned in the `skipped` array:

```typescript
skipped.push({
  id: n.id,
  device_id: d.id,
  reason: "fcm_send_failed",
  status: res.status,
  detail: text.slice(0, 300),
});
```

This response is returned to the caller of the `push-dispatch` function. The FCM error detail (up to 300 chars) is exposed. For admin-triggered batch dispatch this is acceptable; for user-triggered single-notification dispatch (non-admin), the caller can see FCM error messages for their own notification (limited impact).

### 8.4 OCR Route Returns Error from External API

**File:** `app/sunucu/makbuz-ocr/route.ts`

```typescript
const message = err instanceof Error ? err.message : 'OCR işlemi başarısız';
return NextResponse.json({ error: message }, { status: 502 });
```

OpenAI and Replicate error messages may contain internal path or model information. These are returned to the client verbatim.

---

## 9. Security Findings

### CRITICAL

**CRIT-001: `import_places_json` Edge Function Has No Authentication**

- File: `supabase/functions/import_places_json/index.ts`
- Problem: The function uses the service role key to upsert bulk business records but performs no JWT or API key validation.
- Evidence: No `Authorization` header check; no `auth.getUser()` call. The function uses `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` for DB writes directly.
- Impacted app: All apps (corrupted business dataset)
- Exploit: Any attacker who discovers the function URL (via JS source, network logs, or guessing) can POST arbitrary JSON and insert or overwrite business records in production.
- Suggested fix: Add `Authorization: Bearer <jwt>` check and `is_admin` RPC validation before processing. Use `Deno.env.get("SUPABASE_ANON_KEY")` client to validate the JWT; only allow admin or trusted service accounts.
- Safe to auto-fix: No (requires testing the existing panel flow that calls this function)
- Requires DB/RPC/RLS change: No

---

### HIGH

**HIGH-001: Inventory Update Route Has No Ownership Check**

- File: `app/sunucu/sahip/envanter/route.ts`
- Problem: Any authenticated user can mark any menu item unavailable by providing a UUID.
- Evidence: No `hasOwnerBusiness` call; only `supabase.auth.getUser()` authentication check.
- Impacted app: Web (owner panel, but exploitable by any authenticated user)
- Exploit: Authenticated mobile app user submits a PATCH to `/sunucu/sahip/envanter` with a competitor's `menu_item.id` to disable their items.
- Suggested fix: Lookup the menu item's `business_id`, then call `hasOwnerBusiness(supabase, user.id, business_id)`.
- Safe to auto-fix: Yes (additive check only)
- Requires DB/RPC/RLS change: No

**HIGH-002: SMS Campaign Route Has No Ownership Check or Rate Limit**

- File: `app/sunucu/sahip/sms-kampanya/route.ts`
- Problem: Any authenticated user can insert an SMS campaign record for any business UUID.
- Evidence: `bizIds[0]` inserted without ownership verification. No rate limit import.
- Impacted app: Web (sahip panel, but auth is the only guard)
- Exploit: Authenticated user creates spam SMS campaign records for any business.
- Suggested fix: Add `hasOwnerBusiness` check for `bizIds[0]`, add rate limit (e.g., 3/hr per user).
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No (RLS on `sms_campaigns` would also help)

**HIGH-003: Email Campaign Body Allows Stored HTML Injection**

- File: `app/sunucu/sahip/eposta-kampanya/route.ts` + `supabase/functions/send-email-campaign/index.ts`
- Problem: The `body` field from the campaign request is stored and then rendered as raw HTML in outgoing emails with no sanitization.
- Evidence: Route inserts `body: body.body.trim()` directly; Edge Function appends `campaign.html_body` to email HTML without escaping.
- Impacted app: Email recipients (follower users)
- Exploit: Malicious owner crafts an email body containing phishing HTML or tracking pixels. These are sent to all business followers.
- Suggested fix: Either strip HTML at insert time (allow only plain text) or add a server-side HTML sanitization step using a library like `sanitize-html` before storing and sending. Also add zod schema validation to the route handler.
- Safe to auto-fix: No (changes email rendering behavior; needs product decision on HTML vs plain text)
- Requires DB/RPC/RLS change: No

**HIGH-004: `purge-temp-uploads` Edge Function Has No Authentication**

- File: `supabase/functions/purge-temp-uploads/index.ts`
- Problem: No JWT or secret validation. Any HTTP POST triggers the purge job.
- Evidence: No `Authorization` header check.
- Impacted app: Storage (potential premature file deletion)
- Exploit: An attacker can trigger the purge cron repeatedly, processing deletion queue entries faster than intended, or causing race conditions.
- Suggested fix: Add Bearer JWT check + `is_admin` validation, or accept a shared secret from a Supabase cron job header.
- Safe to auto-fix: No (must coordinate with the cron trigger configuration)
- Requires DB/RPC/RLS change: No

**HIGH-005: Auto-Translation Route Has No Ownership Check and No Rate Limit**

- File: `app/sunucu/sahip/ceviriler-otomatik/route.ts`
- Problem: Any authenticated user can translate any menu IDs and accumulate OpenAI API charges. No ownership check.
- Evidence: `menuIds` passed directly to `menu_items` query without verifying the caller owns those menus. No rate limit.
- Impacted app: Web owner panel; API budget
- Exploit: Authenticated user passes 20 `menuIds` for menus they do not own and triggers 1,200 OpenAI API calls.
- Suggested fix: For each `menuId`, verify the corresponding `business_id` is owned by the caller. Add a rate limit of 1–2 requests per user per hour.
- Safe to auto-fix: No (ownership lookup changes the DB query pattern)
- Requires DB/RPC/RLS change: No

**HIGH-006: `yonetici/raporlar-csv` Has No Admin Role Check**

- File: `app/sunucu/yonetici/raporlar-csv/route.ts`
- Problem: The route checks that a user is authenticated but does NOT check `is_admin`. Any authenticated user can download the full reports CSV (up to 5,000 rows of moderation data).
- Evidence: 
```typescript
const { data: { user } } = await supabase.auth.getUser();
if (!user) return new Response('Unauthorized', { status: 401 });
// No is_admin check follows
let query = (supabase as any).from('reports').select(...)
```
- Impacted app: Web admin panel; all users
- Exploit: Any logged-in user (including ordinary mobile app users) calls GET `/sunucu/yonetici/raporlar-csv` and receives a CSV of all moderation reports with target types, reasons, details, and timestamps.
- Suggested fix: Add `const { data: isAdmin } = await supabase.rpc('is_admin'); if (!isAdmin) return new Response('Forbidden', { status: 403 });` before the query.
- Safe to auto-fix: Yes (additive check only)
- Requires DB/RPC/RLS change: No

**HIGH-007: Admin Role Check Uses Inconsistent Mechanism in `b2b-export`**

- File: `app/sunucu/b2b-export/[type]/route.ts`
- Problem: Queries `user_roles` table directly instead of the `is_admin` RPC. The `user_roles` table may not be the authoritative source for admin role (the rest of the system uses `is_admin` RPC backed by `app_metadata`).
- Evidence:
```typescript
const isAdmin = await (supabase as any)
  .from('user_roles')
  .select('role')
  .eq('user_id', user.id)
  .in('role', ['admin', 'superadmin'])
  .maybeSingle();
if (!isAdmin.data) return NextResponse.json({ error: 'Yetkisiz' }, { status: 403 });
```
- Impacted app: Web admin panel; B2B data consumers
- Exploit: If a user's `app_metadata.role = 'admin'` (used everywhere else) but they have no row in `user_roles`, they are locked out of B2B export. Conversely, if a stale `user_roles` row exists for a demoted user, they retain B2B export access.
- Suggested fix: Replace the `user_roles` query with `await supabase.rpc('is_admin')`.
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

---

### MEDIUM

**MED-001: In-Memory Rate Limiter Is Not Multi-Instance Safe**

- File: `src/lib/oran-siniri.ts`
- Problem: `Map`-based in-process rate limiter; rate limits are per-instance, not global.
- Impacted app: All Next.js route handlers using `rateLimit()`
- Suggested fix: Replace with Redis-backed or Upstash Redis rate limiter for production. For Vercel deployments, use Upstash with the `@upstash/ratelimit` library.
- Safe to auto-fix: No (requires infrastructure change)
- Requires DB/RPC/RLS change: No

**MED-002: Raw DB Error Messages Exposed to Clients**

- Files: Multiple (listed in §2.7)
- Problem: `error.message` from Supabase returned directly in JSON responses.
- Suggested fix: Replace `{ error: error.message }` with `{ error: 'internal_error' }` in all 500 responses. Log the actual message server-side.
- Safe to auto-fix: Yes (additive logging + response sanitization)
- Requires DB/RPC/RLS change: No

**MED-003: Account Deletion Silently Skips Auth Deletion**

- File: `app/sunucu/hesap/sil/route.ts`
- Problem: If `SUPABASE_SERVICE_ROLE_KEY` is absent, the auth user record is not deleted but no error is returned.
- Suggested fix: Return an error response if `serviceKey` is missing, or use the centralized service client helper which already handles env absence.
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

**MED-004: `voter_ip` Stores Raw IP+UA in Plaintext**

- File: `app/sunucu/ortak-liste/oy/route.ts`
- Problem: `voter_ip` column stores the unmasked identity string.
- Suggested fix: Hash the identity string with SHA-256 before storing.
- Safe to auto-fix: Yes (if `collab_list_votes.voter_ip` column type allows the hash length)
- Requires DB/RPC/RLS change: Possibly (column type/length check needed)

**MED-005: Claim Evidence Extension Derived from Filename**

- File: `app/sunucu/sahiplik-kaniti-yukle/route.ts`
- Problem: File extension taken from `file.name` (user-supplied) rather than MIME type.
- Suggested fix: Derive extension from `file.type` using a whitelist map (same as `extensionFromMimeType` in `medya/yukleme/route.ts`).
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

**MED-006: `get-exchange-rates` Unauthenticated Write to DB**

- File: `supabase/functions/get-exchange-rates/index.ts`
- Problem: Unauthenticated callers can trigger `exchange_rates` upsert.
- Suggested fix: Either add JWT auth check, or accept a shared cron secret, or make the upsert path only reachable via a Supabase cron job trigger header.
- Safe to auto-fix: No (requires coordinating cron trigger)
- Requires DB/RPC/RLS change: Possibly (RLS on `exchange_rates` could limit service role writes)

**MED-007: `send-push-campaign` Uses Wrong Claims Table**

- File: `supabase/functions/send-push-campaign/index.ts`
- Problem: Queries `business_claims` for ownership check; primary system uses `owner_claims`.
- Suggested fix: Align with the rest of the system — query `owner_claims` instead.
- Safe to auto-fix: No (requires verifying which table is authoritative)
- Requires DB/RPC/RLS change: Possibly

**MED-008: Followers Email Collection Silently Truncated at 1,000**

- File: `app/sunucu/sahip/eposta-kampanya/route.ts`
- Problem: `.limit(1000)` on follower fetch with no warning if truncated.
- Suggested fix: Check if `takipciler.length === 1000` and add a `truncated: true` flag in the response, or use pagination in a loop (as the Edge Function does).
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

**MED-009: `supabase as any` Throughout Critical Paths**

- Files: ~20 route handlers
- Problem: Type safety is disabled; field name bugs are not caught at compile time.
- Suggested fix: Run `supabase gen types typescript` and update `veri-tanimlari.ts`; remove `@ts-expect-error` suppressions; remove `as any` casts.
- Safe to auto-fix: No (requires schema sync and incremental typing work)
- Requires DB/RPC/RLS change: No

---

### LOW

**LOW-001: `console.log` in `purge-temp-uploads`**

- File: `supabase/functions/purge-temp-uploads/index.ts` line 126
- Problem: Operational log to stdout. Acceptable in Edge Function context (captured by Supabase logs) but verbose.
- Suggested fix: Keep as-is or add a structured logging helper. Not a security issue.
- Safe to auto-fix: Yes

**LOW-002: Default EDGE_RATE_LIMIT_SALT Hardcoded Fallback**

- Files: `supabase/functions/admin-api/index.ts`, `supabase/functions/write-gatekeeper/index.ts`
- Problem: Falls back to `"yeedoy_default_salt"` if env var is unset.
- Suggested fix: Remove the fallback and return a 500 error if the env var is missing, forcing the operator to set it.
- Safe to auto-fix: No (may affect local dev workflows)
- Requires DB/RPC/RLS change: No

**LOW-003: Revalidation Endpoint Uses Non-Constant-Time String Comparison**

- File: `app/sunucu/yeniden-dogrulama/route.ts`
- Problem: `parsed.data.secret !== expectedSecret` is not timing-safe.
- Impact: Timing oracle for the revalidation secret (very low practical risk for a cache invalidation endpoint).
- Suggested fix: Use `crypto.timingSafeEqual` via `Buffer.from` comparison.
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

**LOW-004: Old Branding Reference in Seed File**

- File: `supabase/seed/migrate_users.sql`
- Problem: Contains a reference to `menubak` / `Menubak` (old brand name).
- Impact: None at runtime; cosmetic.
- Suggested fix: Clean up the reference in the SQL file.
- Safe to auto-fix: Yes
- Requires DB/RPC/RLS change: No

**LOW-005: Duplicate Data Fetcher Modules**

- Files: `src/lib/db/menu-read.ts` vs `src/lib/veri/menu-okuma.ts`; `src/lib/db/owner/owner-analytics.ts` vs `src/lib/veri/owner/sahip-analitik.ts`; `src/lib/db/admin/admin-queue.ts` vs `src/lib/veri/admin/yonetici-kuyruku.ts`; `src/lib/karekod-erisimi.ts` vs `src/lib/qr-access.ts`
- Problem: DRY violation; two copies of the same logic create update divergence risk.
- Suggested fix: Keep the Turkish-named versions (consistent with codebase convention), deprecate and remove the English-named copies after verifying no callers remain.
- Safe to auto-fix: No (requires caller audit before deletion)
- Requires DB/RPC/RLS change: No

---

## 10. Safe Fix Plan (No Approval Required)

The following changes are additive or non-breaking and can be applied without architecture review:

1. **HIGH-006 — Add `is_admin` check to `yonetici/raporlar-csv/route.ts`**  
   Insert `const { data: isAdmin } = await supabase.rpc('is_admin'); if (!isAdmin) return ...` before the `reports` query. No downstream callers are affected by tightening access.

2. **HIGH-007 — Replace `user_roles` query with `is_admin` RPC in `b2b-export/[type]/route.ts`**  
   Direct substitution; the RPC is already used consistently across all other admin routes.

3. **HIGH-001 — Add ownership check to `sahip/envanter/route.ts`**  
   Lookup `menu_items.business_id` for the given `itemId`, then call `hasOwnerBusiness`. Both helpers are already imported elsewhere in the same codebase.

4. **HIGH-002 — Add ownership check + rate limit to `sahip/sms-kampanya/route.ts`**  
   Call `hasOwnerBusiness` for `bizIds[0]`; import and call `rateLimit`.

5. **MED-003 — Return error when service key is missing in `hesap/sil/route.ts`**  
   Change the `if (serviceKey)` block to `if (!serviceKey) return NextResponse.json({ error: 'service_unavailable' }, { status: 500 });`.

6. **MED-005 — Use MIME-based extension in `sahiplik-kaniti-yukle/route.ts`**  
   Replace `file.name.split('.').pop()` with a `extensionFromMimeType` whitelist.

7. **LOW-001 — Accept or clean `console.log` in `purge-temp-uploads/index.ts`**  
   Acceptable operational log; no action required unless log verbosity is a concern.

8. **LOW-003 — Timing-safe secret compare in `yeniden-dogrulama/route.ts`**  
   Replace `!==` with `crypto.timingSafeEqual`.

9. **LOW-004 — Remove `menubak` reference from `supabase/seed/migrate_users.sql`**  
   Cosmetic cleanup.

10. **MED-002 — Sanitize error messages in all 500 responses**  
    Replace raw `error.message` returns with `'internal_error'` and log to server logger.

11. **MED-008 — Add truncation warning in email campaign follower fetch**  
    Add a `truncated` flag check after the `.limit(1000)` query.

---

## 11. Risky Fix Plan (Requires Approval)

The following changes touch contracts, schemas, auth flows, or external integrations:

1. **CRIT-001 — Add authentication to `import_places_json`**  
   Requires deciding: admin-only or shared-secret-only. Must not break the panel flow that currently calls this function. Existing callers: the panel import UI (not individually audited in this pass).

2. **HIGH-004 — Add authentication to `purge-temp-uploads`**  
   Requires coordinating with the Supabase cron trigger or the deployment pipeline that invokes this function.

3. **HIGH-003 — HTML sanitization for email campaign body**  
   Requires product decision on whether owners can use HTML formatting or only plain text. Changes the stored data format and email rendering in `send-email-campaign`.

4. **HIGH-005 — Ownership check in `sahip/ceviriler-otomatik/route.ts`**  
   Requires a lookup path from `menu_id` → `business_id` → ownership check. May add a DB query per menu ID in the batch.

5. **MED-001 — Replace in-memory rate limiter with Redis/Upstash**  
   Requires infrastructure decision (Upstash account, Vercel KV, or equivalent). All 23 rate-limited routes must be tested after migration.

6. **MED-007 — Align `send-push-campaign` to use `owner_claims` instead of `business_claims`**  
   Requires verifying which table is the authoritative ownership record. If `business_claims` is legacy, migration of ownership records may be needed.

7. **MED-009 — Full Supabase type generation and `as any` removal**  
   Requires `supabase gen types typescript` against the live schema, integration of the generated file, and incremental removal of `as any` casts across ~20 files.

8. **MED-004 — Hash `voter_ip` before storage**  
   Requires a migration to alter the `collab_list_votes.voter_ip` column type/length if it currently stores short IP strings rather than 64-char SHA-256 hashes. Existing votes would need to be backfilled or invalidated.

---

## 12. Prioritized Implementation Plan

**Phase 1 — Audit (this document)**  
Complete. Establishes the baseline.

**Phase 2 — Critical and High-Risk Security Fixes (1–2 days)**

Priority order:
1. CRIT-001: Auth on `import_places_json`
2. HIGH-006: Admin check on reports CSV
3. HIGH-001: Ownership check on inventory update
4. HIGH-002: Ownership check + rate limit on SMS campaign
5. HIGH-004: Auth on purge-temp-uploads
6. MED-003: Service key absence error in account deletion
7. HIGH-007: Consistent admin check in b2b-export

**Phase 3 — Validation and Rate-Limit Hardening (2–3 days)**

1. Add zod schemas to all routes lacking them (§2.2)
2. Add rate limits to all write routes lacking them (§2.1)
3. Sanitize error messages (MED-002)
4. MED-005: MIME-based extension for claim evidence uploads
5. LOW-003: Timing-safe secret compare

**Phase 4 — Email/Campaign Security (1 day, requires approval)**

1. HIGH-003: HTML sanitization for email campaign body
2. MED-008: Truncation warning in email follower fetch
3. MED-007: Align push campaign ownership check to `owner_claims`

**Phase 5 — Query and RPC Performance (2–3 days)**

1. Replace N+1 in `sahip/siparis-listesi` with a single multi-business RPC
2. Add streaming or async export queue for b2b analytics export (100K rows)
3. Add pagination to reports CSV (5K rows per page)
4. Add ownership check + rate limit to auto-translation route

**Phase 6 — Contract Cleanup and Type Safety (1 week)**

1. Run `supabase gen types typescript` and update generated types
2. Remove `@ts-expect-error` suppressions (geri-bildirim, diyet-profili)
3. Remove duplicate data fetcher modules after caller audit
4. Remove `as any` casts incrementally
5. Align `karekod-erisimi.ts` / `qr-access.ts` to single source
6. Low-branding cleanup in seed file

**Phase 7 — Infrastructure (requires decision)**

1. MED-001: Migrate in-memory rate limiter to Upstash Redis or equivalent
2. MED-004: Hash `voter_ip` in collab list votes

---

## 13. Validation Commands

The following commands should be run before and after each phase:

**Web surface (Next.js):**

```bash
cd uygulamalar/web
npm run typecheck   # catches TypeScript errors including new as-any removals
npm run lint        # ESLint; catches unused imports, rule violations
npm run test:unit   # unit tests
npm run build       # full production build; catches import resolution errors
```

**Flutter mobile:**

```bash
cd uygulamalar/mobil
flutter analyze     # static analysis
flutter test test   # unit tests
```

**Flutter personel:**

```bash
cd uygulamalar/personel
flutter analyze
```

**L10n consistency:**

```bash
npm run l10n:audit  # from repo root
```

**Validation commands skipped in this audit (read-only audit):**
- `npm run test:unit` and Playwright E2E were not run (read-only audit scope)
- `supabase db push --local` was not run
- `flutter test` was not run

No code was modified during this audit. All findings are based on static file reads performed on 2026-05-23.
