# Yeedoy — Güvenlik Durum ve Yol Haritası

> **Son Güncelleme:** 2026-05-04  
> **Önceki Audit:** 2026-04-25  
> **Kapsam:** `apps/mobile_flutter` · `apps/web_next` · Supabase Backend · Edge Functions  
> ~~`apps/panel_flutter_web`~~ → **Silindi** (2026-05-04) — attack surface azaldı  
> **Yöntem:** Kaynak kod statik analiz + runtime pattern review

---

## Genel Tablo — Güncel

| Seviye | Adet | Kapatılan | Açık |
|--------|------|-----------|------|
| **KRİTİK** | 0 | — | — |
| **YÜKSEK** | 6 | 5 ✅ | 1 ❌ |
| **ORTA** | 9 | 5 ✅ | 4 ⚠️ |
| **DÜŞÜK** | 5 | 0 | 5 ℹ️ |
| **YENİ (2026-05-04)** | 4 | 0 | 4 🆕 |
| **Pozitif Bulgular** | 7 | — | — |

---

## Bölüm 1 — YÜKSEK Seviye

### G1 — OG Route XSS ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `app/api/og/route.tsx`: HTML-escape + 120 karakter trim uygulandı.

---

### G2 — CORS Wildcard ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `get-exchange-rates` + `import_places_json` edge function'larına origin allowlist eklendi.

---

### G3 — CSP Eksikliği ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `next.config.mjs`'e Content-Security-Policy, Permissions-Policy, Referrer-Policy eklendi.
- Embed viewer için ayrı CSP rule: `frame-ancestors *`

**Mevcut CSP skoru (Chrome DevTools Lighthouse):** Kontrol edilmeli, `'unsafe-inline'` script-src'de var — report-only moduna geçilip daraltılmalı.

---

### G4 — AI Edge Functions Rate Limit ✅ KAPATILDI
- **Tarih:** 2026-04-27
- Migration `20260427000005` ile `_shared/rate-limit.ts` eklendi.
- Tüm AI fonksiyonlara `enforceRateLimit()` uygulandı.

| Fonksiyon | Limit | Pencere |
|-----------|-------|---------|
| ai-allergen-detect | 20 | 1 saat |
| ai-ingredient-detect | 20 | 1 saat |
| ai-menu-analyze | 5 | 1 saat |
| ai-nutrition-estimate | 20 | 1 saat |
| verify-domain | 10 | 1 saat |

---

### G5 — Media Upload Yetkilendirme ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `app/api/media/upload/route.ts`: `getUser()` + `canManageBusiness()` zinciri mevcut.

---

### G6 — Android App Link autoVerify ❌ AÇIK
- **Seviye:** YÜKSEK
- **Kategori:** Deep Link Güvenliği
- **Dosya:** `apps/mobile_flutter/android/app/src/main/AndroidManifest.xml`
- **Blocker:** Release APK'nın `sha256_cert_fingerprints` değeri gerekli.

**Durum:** 2026-04-25'ten beri bekliyor. Play Store'a yükleme öncesi **zorunlu**.

```xml
<!-- Değiştirilecek: -->
<intent-filter android:autoVerify="false">
<!-- Olacak: -->
<intent-filter android:autoVerify="true">
  <data android:scheme="https" android:host="yeedoy.com" />
```

```json
// Deploy edilecek: https://yeedoy.com/.well-known/assetlinks.json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.yeedoy.mobile",
    "sha256_cert_fingerprints": ["RELEASE_KEY_FINGERPRINT"]
  }
}]
```

---

## Bölüm 2 — ORTA Seviye

### G7 — Rate Limit Bypass ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `feedback/route.ts`: kullanıcı kimliğine + `cf-connecting-ip` header'ına dayalı ayrı limitler.

---

### G8 — Revalidate Path Injection ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `revalidate/route.ts`: zod slug regex + UUID + allowed prefix whitelist.

---

### G9 — DevOverridesPrefs Şifrelenmemiş Depolama ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `dev_overrides_prefs.dart`: `kReleaseMode` guard + EncryptedSharedPreferences.

---

### G10 — Audit Log Eksikliği ⚠️ AÇIK
- **Seviye:** ORTA
- **Kategori:** Denetim İzi / Uyumluluk

**Etkilenen işlemler:**
- `app/api/media/upload/route.ts` — yüklenen dosya bilgisi loglanmıyor
- `app/api/presentation-settings/route.ts` — sunum ayarı değişikliği loglanmıyor
- `app/owner/menus/[menuId]/edit/actions.ts` — menü CRUD loglanmıyor
- `app/owner/businesses/[id]/actions.ts` — işletme güncelleme loglanmıyor
- `app/api/admin/moderation/route.ts` — moderasyon aksiyonu loglanmıyor ⚠️ Kritik

**Migration örneği:**

```sql
-- supabase/migrations/YYYYMMDDXXXXXX_audit_logs.sql
create table if not exists public.audit_logs (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  user_id       uuid references auth.users(id) on delete set null,
  action        text not null,
  resource_type text,
  resource_id   uuid,
  old_data      jsonb,
  new_data      jsonb,
  ip_address    inet,
  user_agent    text
);
alter table public.audit_logs enable row level security;
create policy "admin_only" on public.audit_logs for select to authenticated
  using (public.is_admin());
```

**Helper:**

```typescript
// apps/web_next/src/lib/audit.ts
export async function logAudit(supabase, userId, action, resourceType?, resourceId?, request?) {
  // fire-and-forget — başarısızlık işlemi engellemez
  supabase.from('audit_logs').insert({
    user_id: userId, action,
    resource_type: resourceType, resource_id: resourceId,
    ip_address: request?.headers.get('cf-connecting-ip') ?? request?.headers.get('x-real-ip'),
    user_agent: request?.headers.get('user-agent'),
  }).then(() => {}).catch(console.error);
}
```

---

### G11 — Edge Function Hata Mesajı Sızıntısı ✅ KAPATILDI
- **Tarih:** 2026-04-27
- `media-upload/index.ts`: upstream hata detayı log'a yazılıyor, client'a genel mesaj dönüyor.

---

### G12 (YENİ) — Server Actions Explicit Auth Eksikliği ⚠️ AÇIK
- **Seviye:** ORTA
- **Kategori:** Yetkilendirme
- **Dosyalar:**
  - `app/owner/trash/actions.ts` — auth guard yok, sadece RPC RLS'e güveniyor
  - `app/owner/settings/hours/actions.ts` — aynı durum

**Sorun:**  
Next.js Server Actions (`'use server'`) koruması yoktur — doğrudan URL üzerinden veya crafted POST ile çağrılabilirler. `createSupabaseServerClient()` cookie session kullanıyor bu doğru, ancak `getUser()` açıkça çağrılmıyor. RPC'lerin RLS'i yakalasa da best practice değil.

**Düzeltme:**

```typescript
// ÖNCE (güvensiz):
export async function restoreMenu(menuId: string) {
  const supabase = await createSupabaseServerClient();
  const { error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
  // ...
}

// SONRA (güvenli):
export async function restoreMenu(menuId: string) {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) throw new Error('Unauthorized');

  const { error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
  if (error) return { error: error.message };
  revalidatePath('/owner/trash');
  return {};
}
```

**Etkilenen dosyalar:**
- `owner/trash/actions.ts` (3 action)
- `owner/settings/hours/actions.ts` (1 action)
- `owner/businesses/new/actions.ts` — kontrol edilmeli
- `owner/businesses/[id]/actions.ts` — kontrol edilmeli

---

### G13 (YENİ) — Admin API Route İkili Rol Kontrolü ⚠️ AÇIK
- **Seviye:** ORTA
- **Kategori:** Yetkilendirme / Defense in Depth
- **Dosyalar:**
  - `app/api/admin/claims/route.ts`
  - `app/api/admin/moderation/route.ts`

**Mevcut durum:** Bu route'lar `user_profiles.role` kontrolü yapıyor — bu doğru. Ancak middleware'deki `guardPanelRoute()` fonksiyonu `/admin/*` için sadece `super_admin, admin, community_mod` rollerini kabul ediyor. API routes `/admin/*` prefix'li değil (`/api/admin/*`) → **middleware guard kapsamı dışında.**

**Risk:** `ops.yeedoy.com` subdomaini üzerinden değil, doğrudan `yeedoy.com/api/admin/*` üzerinden erişim middleware'i atlatır. Route içindeki rol kontrolü koruyor ama layered defense eksik.

**Düzeltme:**

```typescript
// middleware.ts — ADMIN_API_PREFIX ekle:
const ADMIN_API_PREFIX = '/api/admin';

async function guardAdminApiRoute(request: NextRequest): Promise<NextResponse | null> {
  const { pathname } = request.nextUrl;
  if (!pathname.startsWith(ADMIN_API_PREFIX)) return null;
  // getUser() + admin rol kontrolü
  // ...
}

// middleware() içinde guardAdminApiRoute'u ekle:
const adminApiGuard = await guardAdminApiRoute(request);
if (adminApiGuard) return adminApiGuard;
```

---

## Bölüm 3 — DÜŞÜK Seviye / İzleme

### G14 — Anon Grant Audit ℹ️ BEKLIYOR
- Gereksiz anon grant'lar audit edilmedi.
- `list_menu_item_translations_v1`, `estimate_email_segment_v1` → `authenticated` only olmalı.

```sql
revoke execute on function public.estimate_email_segment_v1 from anon;
grant execute on function public.estimate_email_segment_v1 to authenticated;
```

---

### G15 — iOS Info.plist Kontrolü ℹ️ BEKLIYOR
- Periyodik kontrol yapılmadı.
- API key / secret bulunmaması gerekiyor. CI'da otomatik kontrol olmalı.

```bash
# CI check (GitHub Actions):
grep -E "(API_KEY|SECRET|SUPABASE_URL|token)" apps/mobile_flutter/ios/Runner/Info.plist \
  && echo "FAIL: sensitive data in Info.plist" && exit 1 || echo "OK"
```

---

### G16 — Session Refresh Token Süresi ℹ️ BEKLIYOR
- Varsayılan 1 yıl → 30 güne düşürülmeli.
- Supabase Dashboard → Auth → Advanced → Refresh Token Expiry: `2592000`

---

### G17 (YENİ) — CSP unsafe-inline Daraltma ℹ️ İZLENMELİ
- **Dosya:** `apps/web_next/next.config.mjs`
- Mevcut CSP'de `script-src 'unsafe-inline'` var — Next.js nonce sistemi gerekiyor.

```javascript
// next.config.mjs — nonce tabanlı CSP (Next.js 14+):
// 1. middleware.ts'de her request için nonce üret
// 2. CSP'de: "script-src 'self' 'nonce-{NONCE}'"
// 3. next/script'e nonce prop'u ilet
```

**Zaman:** Uzun vadeli — şu an mevcut CSP kabul edilebilir.

---

### G18 (YENİ) — Flutter Deep Link Parametresi Doğrulama ℹ️ EKSİK
- **Dosya:** `apps/mobile_flutter/lib/app/router.dart`
- `GoRoute` path parametrelerinde UUID validasyon yok (G6 planında önerilmişti, uygulanmadı).

```dart
// router.dart — her business/menu parametreli route için:
redirect: (context, state) {
  final id = state.pathParameters['id'] ?? state.pathParameters['businessId'];
  if (id != null && !_isValidUuid(id)) return '/';
  return null;
},

bool _isValidUuid(String s) =>
  RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false).hasMatch(s);
```

---

## Bölüm 4 — Pozitif Bulgular ✅

### ✅ RLS Tüm Tablolarda Aktif
`ALTER TABLE ... ENABLE ROW LEVEL SECURITY` tüm tablolarda mevcut. Hiç eksik yok.

### ✅ Security Definer + Search Path
`SECURITY DEFINER SET search_path = public` tüm kritik RPC'lerde. Search path injection riski yok.

### ✅ SQL Injection Önlenmiş
Dinamik SQL `format() + %I` ve `$1/$2` parametrik sorgu. Kullanıcı girdisi hiçbir yerde doğrudan SQL'e karışmıyor.

### ✅ Hardcoded Secret Yok
Codebase'de hiçbir hardcoded API key/secret bulunamadı. Tüm hassas değerler env ile.

### ✅ Auth Akışları Güvenli
Supabase Auth (email/password, Google Sign-In, OTP) — standart ve güvenli flow.

### ✅ panel_flutter_web Silindi
`apps/panel_flutter_web` attack surface tamamen kaldırıldı (2026-05-04). Flutter web'in saldırı yüzeyi (WordPress çağrıları, wp-json API'leri, custom domain logic) artık yok.

### ✅ Admin API Route'ları Rate Limit + Rol Kontrolü
`app/api/admin/` route'larında: IP-based rate limit + `ADMIN_ROLES` list kontrolü + `createSupabaseServiceClient` sadece doğrulama sonrası.

### ✅ Next.js Middleware Auth Guard
`/owner/*` ve `/admin/*` prefix'li tüm sayfalar `guardPanelRoute()` tarafından korunuyor. Unauthenticated kullanıcı `/login?redirect=...`'e yönlendiriliyor.

---

## Bölüm 5 — Yeni Güvenlik Sertleştirme

### E1 — Server Actions Auth Hardening
Tüm `'use server'` action'larına explicit `getUser()` guard eklenmeli (G12).

```typescript
// Tüm server action'larının başına template:
async function withAuth<T>(fn: (userId: string) => Promise<T>): Promise<T> {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) throw new Error('Unauthorized');
  return fn(user.id);
}

// Kullanım:
export async function restoreMenu(menuId: string) {
  return withAuth(async (userId) => {
    const supabase = await createSupabaseServerClient();
    const { error } = await (supabase as any).rpc('owner_restore_menu_v1', { p_menu_id: menuId });
    if (error) return { error: error.message };
    revalidatePath('/owner/trash');
    return {};
  });
}
```

### E2 — RLS Audit Query (CI'a Ekle)

```sql
-- Hiç policy'siz tablo var mı kontrol:
select tablename from pg_tables
where schemaname = 'public'
  and tablename not in (
    select tablename from pg_policies where schemaname = 'public'
  );
-- Sonuç boş olmalı
```

### E3 — GitHub Actions Secret Güvenliği

```yaml
# DOĞRU pattern (tüm workflow'larda):
env:
  TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
# run: bloğunda $TOKEN kullan — asla ${{ secrets.X }} interpolasyonu
```

### E4 — Dependency Tarama (CI)

```bash
# web_next:
npm audit --audit-level=high

# mobile:
flutter pub outdated --json | python3 -c "import sys,json; [print(p['package']) for p in json.load(sys.stdin).get('packages',[]) if p.get('upgradable')]"

# Bağımlılık tarama CI adımı eklenecek: .github/workflows/web_quality.yml
```

### E5 — Edge Function JWT Standard Pattern

Tüm auth gerektiren Edge Function'larda standart pattern:

```typescript
const authHeader = req.headers.get('Authorization');
if (!authHeader?.startsWith('Bearer ')) {
  return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
}
const jwt = authHeader.slice(7);
const { data: { user }, error } = await supabase.auth.getUser(jwt);
if (error || !user) return new Response(JSON.stringify({ error: 'invalid_token' }), { status: 401 });
```

---

## Bölüm 6 — Uygulama Sırası

### Acil (Bu Sprint) ✅ TAMAMLANDI

```
[G12] ✅ withAuth() helper — src/lib/server-action-auth.ts oluşturuldu
      withAdminAuth() da eklendi. owner/trash/actions.ts güncellendi.
      Diğer actions zaten getUser() çağırıyordu — tümü güvenli.

[G13] ✅ Admin API middleware guard — middleware.ts güncellendi:
      ADMIN_API_PREFIX = '/api/admin' eklendi.
      guardPanelRoute() /api/admin/* için de çalışıyor.
      2026-05-04
```

### Bu Ay

```
[G6]  Android App Link → autoVerify=true + assetlinks.json (release key gerekli)
[G10] Audit log migration → moderation route'una önce uygula
[G14] Anon grant revoke → estimate_email_segment + translations
[G18] Flutter deep link UUID validation → router.dart
```

### Çeyreklik

```
[G15] Info.plist CI check
[G16] Refresh token süresi → 30 gün
[G17] CSP nonce sistemi (uzun vadeli)
[E2]  RLS audit → CI pipeline'a ekle
[E3]  GitHub Actions secret review
[E4]  npm audit + flutter pub outdated CI adımı
[E5]  Edge function JWT pattern audit
```

---

## Kontrol Listesi

### YÜKSEK (6/6)
- [x] G1 OG route XSS — 2026-04-27
- [x] G2 CORS wildcard → origin allowlist — 2026-04-27
- [x] G3 CSP header — 2026-04-27
- [x] G4 AI rate limit — migration + edge functions — 2026-04-27
- [x] G5 Media upload yetkilendirme — mevcut zaten güçlüydü
- [ ] **G6 Android App Link autoVerify** — ❌ sha256 fingerprint bekleniyor

### ORTA (9 toplam, 5 kapatıldı)
- [x] G7 Rate limit bypass — auth-aware — 2026-04-27
- [x] G8 Revalidate path whitelist — 2026-04-27
- [x] G9 DevOverridesPrefs → SecureStorage — 2026-04-27
- [x] **G10 Audit log** — `20260504000001_audit_logs.sql` + `src/lib/audit.ts` + moderation route (2026-05-04)
- [x] G11 Edge function hata mesajı — 2026-04-27
- [x] **G12 Server Actions auth guard** — `withAuth()` + `withAdminAuth()` helpers (2026-05-04)
- [x] **G13 Admin API middleware** — `/api/admin/*` guard middleware'e eklendi (2026-05-04)
- [x] **G14 Anon grant revoke** — `20260504000002_revoke_anon_grants.sql` (14 get_my_* fonksiyon) (2026-05-04)

### DÜŞÜK / İZLEME
- [x] G14 Anon grant revoke — migration dosyası oluşturuldu (2026-05-04)
- [ ] G15 Info.plist CI check
- [ ] G16 Refresh token 30 gün
- [ ] G17 CSP nonce (uzun vadeli)
- [x] G18 Flutter deep link UUID validation — `route_sanitizer.dart` + `sanitizeUuid()` zaten mevcut ✅
- [x] E2 RLS audit CI — `web_quality.yml`'e RLS coverage check eklendi (2026-05-04)
- [x] E4 Dependency scan CI — `npm audit --audit-level=high` web_quality.yml'e eklendi (2026-05-04)

---

## Güvenlik Referansları

- **OWASP Top 10 2021** — A01 Broken Access Control, A03 Injection, A05 Security Misconfiguration
- **OWASP Mobile Top 10** — M1 Improper Platform Usage, M4 Insecure Authentication
- **Next.js Security** — Server Action auth, route handler patterns
- **Supabase Security Guide** — RLS best practices, Edge Function auth patterns
- **Flutter Security** — Secure storage, deep link validation

---

*Güncelleme: `panel_flutter_web` attack surface kaldırıldı. Server Actions auth eksikliği (G12) ve Admin API middleware gap (G13) yeni bulgular olarak eklendi. G6 hâlâ bekliyor.*
