# CRM v2 — Zincir-Çapında Birleşik Görünüm — Design Doc

## Bağlam

CRM v1'in "Kapsam Dışı" bölümünde bırakılan dört bağımsız alt-özellikten sonuncusu (bkz. `docs/superpowers/specs/2026-08-11-crm-musteri-profili-design.md` §Kapsam Dışı). Not/etiket ekleme (`docs/superpowers/specs/2026-08-11-crm-v2-not-etiket-design.md`) ve liste arama (`docs/superpowers/specs/2026-08-12-crm-v2-arama-filtre-design.md`) tamamlandı. Kalan iki alt-projeden biri bu: **zincir-çapında birleşik görünüm**.

Mevcut durum: `/sahip/musteriler` (liste + `[user_id]` detay/zaman çizelgesi) tamamen tek bir `business_id`'ye bağlı çalışıyor. `page.tsx`, owner'ın onaylı işletmelerinden `businessIds[0]`'ı kullanıyor — zincirli (çoklu şube) bir owner için bile şu an sadece **ilk işletmenin** müşterileri görünüyor, şubeler arası hiçbir birleştirme/seçici yok.

Sadakat özelliği (`docs/superpowers/specs/2026-08-10-sadakat-faz1-db.md`) zaten zincir-çapında paylaşılan bir modelle çalışıyor: `loyalty_programs.chain_id` (business_id ile XOR) + `_resolve_loyalty_program_v1(p_business_id)` helper'ı, verilen bir işletmenin `businesses.chain_id`'sine bakıp doluysa zincirin ortak programını, boşsa işletmenin kendi programını çözümlüyor. Bu spec aynı deseni CRM'e uyguluyor.

Çoklu Şube Yönetimi'nin (`docs/superpowers/specs/2026-08-06-coklu-sube-yonetimi-design.md`) V1 kısıtı hâlâ geçerli: bir zincirin tüm şubeleri **tek bir owner**'a ait (franchise/çoklu-owner senaryosu V2, henüz yok). Bu, yetkilendirmeyi basitleştiriyor — zincir-çapında birleştirme tetiklendiğinde farklı owner'ların verisi asla karışmıyor.

## Hedefler

- Zincirli bir owner, `/sahip/musteriler` listesinde **tüm şubelerindeki** müşterileri tek, birleşik bir listede görsün — aynı müşteri iki şubeye uğradıysa listede tek satır, sayaçları toplanmış olarak görünsün.
- Müşteri detay/zaman çizelgesi sayfası da tüm şubelerdeki olayları tek kronolojik akışta, her olayda hangi şubeden geldiğini gösteren bir etiketle sunsun.
- Zincirsiz (standalone) owner'lar için davranış birebir bugünküyle aynı kalsın (regresyon yok).

## Kapsam Dışı (YAGNI)

- **Şube seçici/toggle** — birleştirme manuel açılıp kapatılan bir seçenek değil, owner zincirdeyse otomatik ve şeffaf çalışır.
- **Listede şube kolonu/filtresi** — liste sayfası sadece birleşik satırlar gösterir, "hangi şube(ler)den" bilgisi liste seviyesinde yok (sadece zaman çizelgesinde, olay bazlı).
- **Not/etiket yazma davranışının değişmesi** — bir not/etiket hâlâ eklendiği `business_id`'ye kaydedilir (audit izi korunur). Sadece **okuma** tarafı zincir-çapında genişler.
- **Aynı metinli etiketlerin dedup'lanması** — iki farklı şubeden aynı etiket eklenirse listede iki ayrı rozet görünür; bu turun kapsamında dedup mantığı yazılmıyor (kozmetik, düşük öncelik).
- **Franchise/çoklu-owner zincirler** — Çoklu Şube V1 kısıtı gereği zaten mümkün değil, bu spec'in de varsayımı.
- **Genel işletme/zincir seçici (owner panelinin geneli için)** — `businessIds[0]` varsayımı CRM dışındaki tüm owner sayfalarında da var; bu, CRM'e özel olmayan, önceden var olan bir sınır. Bu spec sadece CRM'in kendi RPC'lerini zincir-farkında yapıyor, panel genelinde bir işletme/zincir seçici eklemiyor.
- **Genel tarayıcı doğrulaması** — yerelde onaylı bir zincirli owner test hesabı yoksa, bu adım otomatik testlere + kod incelemesine bırakılır (arama/filtre turunda karşılaşılan aynı kısıt).

## Mimari & Veri Modeli

Yeni tablo yok. Tek yeni parça, `_resolve_loyalty_program_v1` ile aynı desende bir helper:

```sql
CREATE FUNCTION public._resolve_chain_business_ids_v1(p_business_id uuid, p_include_siblings boolean)
RETURNS uuid[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN NOT p_include_siblings THEN ARRAY[p_business_id]
    ELSE COALESCE(
      (SELECT array_agg(b2.id) FROM public.businesses b1
         JOIN public.businesses b2 ON b2.chain_id = b1.chain_id
         WHERE b1.id = p_business_id AND b1.chain_id IS NOT NULL),
      ARRAY[p_business_id]
    )
  END;
$$;
```

`p_include_siblings`, çağıran RPC'nin caller'ın zincirdeki **tüm şubelerde** yetkisi olup olmadığını önceden çözümleyip geçtiği bir parametre (aşağıdaki Güvenlik bölümüne bakınız) — helper'ın kendisi yetkilendirme yapmaz, sadece id çözümler.

## RPC Yüzeyi (mevcut `_v1`'ler genişliyor, imza/dönüş şekli aynı kalıyor)

CLAUDE.md kuralı gereği: bir dönüş alanını **kaldırmak** breaking change sayılır, **eklemek** sayılmaz. Aşağıdaki değişikliklerin hiçbiri parametre/dönüş alanı kaldırmıyor — `_v2` açmaya gerek yok.

- **`get_business_customers_v1(p_business_id)`** — iç sorgudaki `business_id = p_business_id` filtreleri `business_id = ANY(chain_ids)` olur (`chain_ids := _resolve_chain_business_ids_v1(p_business_id, v_is_owner)`). Yorum/rezervasyon sayaçları tüm şubelerden toplanır, `last_interaction_at` en son olan şubeden, etiketler (`tags`) tüm şubelerden birleşir. Sadakat ilerlemesi zaten `_resolve_loyalty_program_v1` ile chain-wide, dokunulmuyor.
- **`get_customer_timeline_v1(p_business_id, p_user_id)`** — aynı `ANY(chain_ids)` genişlemesi. Her olay nesnesine **yeni bir alan** eklenir: `branch_label` (o olayın ait olduğu işletmenin adı/şube etiketi — `businesses.branch_label` doluysa o, yoksa `businesses.name`).

## Güvenlik

Araştırma sırasında önemli bir bulgu: owner'lar ekip üyelerini `business_team_memberships` üzerinden ya **"sadece bu şube"** (`business_id` set) ya da **"tüm şubeler"** (`chain_id` set, `v_scope = 'all_branches'`) kapsamında davet edebiliyor — bu canlı, kullanılan bir özellik (`get_business_role_v1`, `business_team_memberships.chain_id` join'i). Dolayısıyla "sadece gerçek owner" gibi bir kural yanlış olurdu: owner'ın bilerek "tüm şubeler" yetkisi verdiği bir manager'ı da haksız yere kısıtlar. Doğru kural, çağıranın **zincirdeki her şubede ayrı ayrı yetkili olup olmadığını** kontrol etmek:

1. Her iki RPC'de de mevcut `has_business_permission_v1(p_business_id, 'menu_write')` kontrolü **aynen kalır** (giriş kontrolü — owner veya herhangi bir kapsamda manager geçer, değişmiyor).
2. Ardından işletmenin `chain_id`'si çözümlenir (`businesses.chain_id`). Doluysa, çağıranın zincirdeki **her bir kardeş şube için ayrı ayrı** `has_business_permission_v1(sibling_id, 'menu_write')` geçip geçmediği kontrol edilir (`v_all_branches_authorized := NOT EXISTS (sibling zincirde ama izin yok)`).
3. `chain_ids := public._resolve_chain_business_ids_v1(p_business_id, v_all_branches_authorized)` çağrılır.
   - Çağıran zincirdeki **her** şubede yetkiliyse (gerçek owner — chain V1 kısıtı gereği zaten her zaman böyledir — veya "tüm şubeler" kapsamlı manager) → `chain_ids` zincirdeki tüm şubeleri içerir, birleşik görünüm devreye girer.
   - Çağıran zincirdeki **bazı** şubelerde yetkili değilse (örn. "sadece bu şube" kapsamlı manager) → `chain_ids = [p_business_id]`, mevcut tek-şube davranışı çalışır. Kardeş şubelere sızıntı olmaz.
4. Personel (staff, rank 200) zaten `menu_write`'tan geçemiyor — değişmiyor.
5. Üçlü REVOKE deseni (`REVOKE ALL ... FROM PUBLIC` + `REVOKE EXECUTE ... FROM anon` + `GRANT EXECUTE ... TO authenticated`) yeni `_resolve_chain_business_ids_v1` helper'ına da uygulanır, `has_function_privilege()` ile production'da doğrudan doğrulanır (advisor cache'ine güvenilmez — sadakat/CRM v1'deki kritik ders).

## UI

**Liste sayfası** (`/sahip/musteriler`): Tablo yapısı değişmiyor (`musteri-listesi.tsx`'e dokunulmuyor). `page.tsx`, çözümlediği `businessId` üzerinden işletmenin `chain_id`'sini (ve doluysa `chains.name`'i) ayrıca sorgular; zincirdeyse `PanelSayfaBasligi`'nin `description`'ına "Zincir çapında • {chain adı}" ibaresi eklenir. Zincirsizse mevcut açıklama metni aynen kalır.

**Detay/zaman çizelgesi sayfası** (`/sahip/musteriler/[user_id]`): `zaman-cizelgesi.tsx`, her olay satırının yanına `branch_label`'ı küçük bir rozet olarak gösterir — **ama sadece owner zincirdeyse** (tek şubeli owner'lar için rozet render edilmez, gereksiz gürültü olmasın; `page.tsx` zaten zincir bilgisini biliyor, prop olarak geçer).

## Test Stratejisi

- **DB (local `supabase db reset` + rol bazlı SQL, sadakat/çoklu-şube'deki yöntemin aynısı):**
  - Zincirli owner → `get_business_customers_v1` tüm şubelerin birleşik listesini döner, sayaçlar doğru toplanmış, aynı müşteri tek satır.
  - "Tüm şubeler" kapsamlı davet edilmiş manager (`business_team_memberships.chain_id`) → owner ile aynı şekilde zincir-çapında birleşik veri görür.
  - "Sadece bu şube" kapsamlı manager (`business_team_memberships.business_id`) → sadece o şubenin verisini görür (kardeş şubelere sızıntı yok) — bu turun en kritik güvenlik testi.
  - Zincirsiz owner → davranış bugünküyle birebir aynı (regresyon testi).
  - `get_customer_timeline_v1` → olaylar tüm şubelerden kronolojik birleşir, her olayda doğru `branch_label`.
  - `_resolve_chain_business_ids_v1` için doğrudan birim testi (zincirli/zincirsiz/`p_include_siblings=false` senaryoları).
- **Web:** `pnpm run typecheck && pnpm run lint`, `pnpm run test:ci`. Zincir açıklama metni / rozet gösterme koşulu gibi çıkarılabilir saf mantık varsa (`filtrelenmisMusteriler` deseninde) birim testi.
- **Manuel doğrulama:** Yerelde onaylı bir zincirli owner test hesabı yoksa (arama/filtre turunda karşılaşılan kısıt), bu adım atlanır, otomatik testler + kod incelemesi yeterli kabul edilir.
