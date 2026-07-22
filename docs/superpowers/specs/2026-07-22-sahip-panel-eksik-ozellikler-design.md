# Sahip Paneli — Eksik Özellikler Tamamlama Design

## Bağlam

`feat/pmtiles-map-checkpoint` üzerinde daha önce iki bağımsız Türkçeleştirme fazı tamamlandı: owner→`/sahip` (bkz. `docs/superpowers/plans/2026-07-20-owner-turkification-tamamlama-plan.md`) ve admin→`/yonetici` (bkz. `docs/superpowers/plans/2026-07-22-admin-yonetici-tamamlama-plan.md`). Bu iki faz sırasında repo'da, hiç merge edilmemiş `worktree-owner-panel-turkification` adlı ayrı bir dal keşfedildi — 61 commit, 2026-02-26 ile 2026-07-16 arası, `/sahip`'e bağımsız bir göç + görsel yeniden tasarım denemesi. Bu dal olduğu gibi merge edilmeyecek (eski, hardcoded hex renkler kullanıyor, mevcut token sistemine aykırı) ama bir karşılaştırma denetimi bu dalda, **şu an canlı `/sahip`'te gerçekten eksik olan 4 özellik** olduğunu doğruladı. Beşinci bulgu (menü ürünü bölüm değiştirirken güncellemenin sessizce başarısız olması) ayrı, basit bir bug fix olarak zaten düzeltilip commit edildi (`3317921`).

Bu spec, kalan 4 özelliği kapsar. Referans kaynak: `worktree-owner-panel-turkification` dalı (kod olduğu gibi kopyalanmayacak, mevcut CLAUDE.md konvansiyonlarına — design token'lar, RPC şablonu, response şekli — uyacak şekilde yeniden yazılacak).

## Kapsam dışı bırakılanlar

Denetimde incelenip **eşdeğer veya daha gelişmiş** bulunduğu için bu spec'e alınmadı: QR kod hub (canlıda ayrı, daha olgun bir `/karekod/[businessId]` Studio zaten var), fiyat raporu (canlıda zaten tam karşılaştırma tablosu var), dashboard (fonksiyonel fark bulunamadı). `worktree-owner-analitik-tasarim` dalı tamamen süperset edilmiş durumda, hiçbir şey taşınmayacak.

---

## Bölüm 1 — Ekip e-posta daveti + hesap oluşturma

**Neden:** Canlı `app/sahip/ekip/ekip-islemleri.ts` sadece `upsert_team_member_v1` RPC'sini çağırıyor — hiçbir zaman e-posta gönderilmiyor. Davet edilen bir üyelik `invite_email` dolu, `user_id` boş halde DB'de bekliyor ama bunu "active" hale getirecek hiçbir mekanizma yok (kişi kendi kayıt olsa bile otomatik bağlanmıyor). Ayrıca sayfada asla aktif olmayacak sahte bir "Vardiya Planı (Bu Hafta)" placeholder kartı var.

### Yeni dosyalar

- **`uygulamalar/web/src/lib/eposta.ts`** — `sendEmail({ to, subject, html }): Promise<boolean>`. Resend client'ı `appConfig.resendApiKey()` tanımlıysa kurulur; tanımlı değilse veya Resend hata dönerse `logger.warn`/`logger.error` ile loglayıp `false` döner — **çağıran tarafı asla bloklamaz**. `RESEND_API_KEY` bu turda env'e eklenmeyecek, kod hazır-ama-bekliyor halde kalacak (SMS altyapısı ile aynı desen).
- **`uygulamalar/web/app/sahip/ekip/ekip-sabitleri.ts`** — `ROLE_LABELS` (rol → `{label, className}` haritası, mevcut sayfadaki rol metinleriyle birebir aynı olacak, sadece tek yere çıkarılıyor).

### `ayarlar.ts` genişletme

`appConfig` nesnesine iki yeni getter: `emailFrom: () => process.env.EMAIL_FROM?.trim() || 'Yeedoy <bildirim@yeedoy.com>'` ve `resendApiKey: () => process.env.RESEND_API_KEY?.trim() || null`. Mevcut `requireEnv` desenine dokunulmuyor (bunlar zorunlu değil, optional-with-default).

### Yeni migration — `claim_pending_team_invites_v1`

`supabase/migrations/` altına CLAUDE.md RPC şablonuna uygun yeni bir dosya: `auth.uid()` ile giriş yapan kullanıcının e-postasına (`auth.users.email`, case-insensitive) eşleşen, `revoked_at IS NULL AND user_id IS NULL` olan tüm `business_team_memberships` satırlarını bulur, her biri için `user_id = auth.uid()`, `accepted_at = now()` günceller. `auth.uid() IS NULL` ise `P0002 unauthorized`. Dönüş: `jsonb` — kaç üyeliğin bağlandığı (`{ok: true, linked_count: n}`). `GRANT EXECUTE ... TO authenticated`.

### `ekip-islemleri.ts` genişletme

`addTeamMember` imzası `FormData` yerine tipli bir input alacak şekilde değişiyor: `{ businessId, email, fullName, password, role }`. `password` boşsa mevcut davranış (sadece `upsert_team_member_v1` çağrısı — davet). `password` doluysa (min 8 karakter, sunucu tarafı validasyon):

1. `createSupabaseServiceClient()` (zaten var, `src/lib/taban/hizmet.ts`) ile `auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { full_name } })`.
2. Hata "already registered" ise (regex kontrolü) — **mevcut hesabın şifresine dokunma**, sessizce "linked" moduna düş, sadece ekibe bağla.
3. Başarılıysa `user_profiles` tablosuna `display_name` satırı ekle (best-effort, başarısız olsa da hesap oluşturmayı engellemez).
4. Her durumda `upsert_team_member_v1` çağrısı yapılır (email artık `auth.users`'ta olduğu için `user_id` otomatik dolar).
5. Moda göre (`created`/`invited`/`linked`) 3 farklı e-posta içeriği `sendEmail` ile gönderilir (`void sendEmail(...)` — sonucu beklenmez, ana akışı bloklamaz).

Ayrıca iki yeni action: `changeTeamMemberRole(businessId, email, role)` ve `removeTeamMember(businessId, membershipId)` — `revoke_team_member_v1` RPC'si zaten DB'de var ve kullanılmıyordu, sadece client tarafı ekleniyor.

`serviceRoleKey` tanımlı değilse (`createSupabaseServiceClient()` null dönerse) ve şifre girildiyse: `{ error: 'Sunucu yapılandırması eksik (SUPABASE_SERVICE_ROLE_KEY tanımlı değil) — şifresiz davet gönderebilirsiniz.' }`.

### `app/sunucu/kimlik/giris/route.ts`

`signInWithPassword` başarılı olduktan hemen sonra, rol yönlendirmesinden **önce**: `try { await supabase.rpc('claim_pending_team_invites_v1'); } catch {}` — best-effort, giriş akışını asla engellemez.

### `ekip/page.tsx` UI

- Yeni üye formuna opsiyonel şifre alanı (`type="password"`, min 8 karakter client-side hint).
- Her üye satırına rol değiştirme (select + `changeTeamMemberRole`) ve kaldır (`removeTeamMember`, `confirm()` ile onay) aksiyonları.
- **"Vardiya Planı (Bu Hafta)" kartı ve ilgili "Not: Vardiya kayıt entegrasyonu yakında aktif olacak" metni tamamen kaldırılıyor.**

---

## Bölüm 2 — Menü kategori yönetimi sayfası

**Neden:** Menü düzenleyicide bölüm (section) oluşturma/düzenleme/silme zaten var ama gömülü ve dağınık. Ayrı, odaklı bir liste sayfası yok.

- **Yeni:** `app/sahip/menuler/[menuId]/kategoriler/page.tsx` (server component, `getOwnedMenuContext` ile aynı yetkilendirme deseni) + `kategoriler-istemcisi.tsx` (client component).
- Mevcut `createSection`/`updateSection`/`deleteSection` action'ları (`duzenle/menu-islemleri.ts`, **değişmeyecek**) yeniden kullanılır.
- Her bölüm satırında: başlık (inline düzenlenebilir), ürün sayısı (`itemCounts`), sil butonu (ürün sayısı > 0 ise onay iste).
- İkon/renk yardımcı fonksiyonları (rozet rengi, kalem/çöp ikonu) mevcut büyük `menu-duzenleyici-istemcisi.tsx` dosyasından export edilmek yerine yeni sayfada **yerel olarak** tanımlanır — mevcut 792 satırlık dosyaya dokunulmaz.
- Menü düzenleyici sayfasına (`duzenle/page.tsx` veya client'ı) "Kategoriler" linkine giden bir buton eklenir.

---

## Bölüm 3 — Başlangıç Rehberi gerçek tamamlanma takibi

**Neden:** `app/sahip/baslangic/page.tsx`'te 4 adımdan 3'ü (menü/QR/ekip) `done: false` sabit — kullanıcı gerçekten tamamlasa bile rehber hiçbir zaman "tamamlandı" göstermiyor.

- **Adım 2 (İlk Menünüzü Oluşturun):** `menus` tablosunda bu işletmeye ait `status = 'published'` kaydı var mı.
- **Adım 3 (QR Kodunuzu Alın):** `business_qr_codes` tablosunda kayıt var mı.
- **Adım 4 (Ekibinizi Davet Edin):** `business_team_memberships`'te `revoked_at IS NULL` olan (adım 1'i tamamlayan kullanıcı hariç, en az bir) üyelik var mı.
- İlerleme çubuğu eklenir (X/4 tamamlandı).
- Tüm adımlar tamamlanınca tebrik banner'ı gösterilir.
- **`src/ui/kabuk/sahip-kabuk-istemcisi.tsx`:** yeni `useOnboardingComplete()` hook'u aynı 4 kontrolü client tarafında (bir API route veya server action üzerinden) yapar; sonuç `true` olduğunda sidebar'daki "Başlangıç Rehberi" linki otomatik kalkar. Kontrol sonucu gelene kadar (yükleniyor/null durumu) öğe görünür kalır — erken kaybolmaz.

---

## Bölüm 4 — Yorumlarda profil fotoğrafı

**Neden:** `app/sahip/yorumlar/page.tsx` sorgusu `user_profiles.avatar_url`'i hiç çekmiyor, `yorum-satiri.tsx` bu alanı hiç göstermiyor.

- `yorumlar/page.tsx` sorgusuna `user_profiles.avatar_url` join edilir.
- `yorumlar-istemcisi.tsx` üzerinden `yorum-satiri.tsx`'e `avatarUrl` prop olarak iletilir.
- `yorum-satiri.tsx`: `avatarUrl` doluysa `<img>`, boşsa isim baş harfli renkli daire fallback — **dashboard'daki mevcut `ReviewerAvatar` bileşeniyle aynı görsel desen** (yeni bir tasarım icat edilmeyecek, var olan pattern'e referans verilecek).

---

## Doğrulama gereksinimleri (her bölüm için)

CLAUDE.md minimum validasyon tablosuna göre: `npm run typecheck` + `npm run lint` (Next.js/web değişikliği). Yeni migration için `supabase db reset` ile yerelde uygulanabilirlik kontrolü. Mutasyon içeren yeni server action'lar (`addTeamMember`, `changeTeamMemberRole`, `removeTeamMember`) zaten auth kontrolü (`hasOwnerBusiness`) içeriyor; CLAUDE.md'nin route handler kuralı (zod+auth+rate-limit) server actions için değil route handler'lar için zorunlu olduğundan, burada mevcut server-action deseni (sayfa içi auth kontrolü) korunur.
