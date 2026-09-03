# Admin İşletme Zincirleme Tasarımı

## Sorun

`/yonetici/isletmeler` sayfasındaki işletme listesinde satır başlarında checkbox var, ama şu an sadece "Toplu Aktif Et / Toplu Pasif Et" için kullanılıyor. Projede zaten bir zincir (chain/çoklu şube) altyapısı var — `chains` tablosu, `businesses.chain_id`/`branch_label`/`chain_sort_order` kolonları, `/yonetici/zincirler` listeleme+detay sayfaları — ama **admin tarafında bir işletmeyi bir zincire atayacak hiçbir RPC veya UI yok**. Owner tarafında `owner_create_chain_v1`/`owner_add_business_to_chain_v1` var, fakat bunlar yalnızca çağıranın *onaylı sahip* olduğu işletmeler için çalışıyor (`_is_approved_owner_of_business`) — admin panelindeki işletmelerin çoğu sahiplenilmemiş/onaysız olabilir, o yüzden owner RPC'leri admin akışında kullanılamaz. `/yonetici/zincirler/[id]` detay sayfası da şu an tamamen salt-okunur (şube listesi var, ekleme/çıkarma yok).

Amaç: admin, işletme listesinde checkbox ile birden fazla işletme seçip bunları var olan bir zincire ekleyebilsin veya seçilenlerden sıfırdan yeni bir zincir kurabilsin.

## Kapsam dışı (bilinçli olarak)

- Zincirden çıkarma (unlink) admin tarafında eklenmiyor — owner'da zaten var, admin tarafı ayrı bir iş.
- Şube etiketi (`branch_label`) girme UI'ı bu işe dahil değil — yeni eklenen işletmelerde bu alan `NULL` kalır, düzenleme akışı sonraki bir işte eklenebilir.
- Zincirler arası taşıma (bir işletmeyi başka zincire geçirme) desteklenmiyor — çakışma durumunda işlem tamamen reddedilir.

## Backend

### Yeni RPC: `admin_add_businesses_to_chain_v1`

```sql
CREATE OR REPLACE FUNCTION public.admin_add_businesses_to_chain_v1(
  p_chain_id      uuid,
  p_business_ids  uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conflict_text  text;
  v_next_sort      integer;
  v_id             uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_ids IS NULL OR array_length(p_business_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'validation_error: en az bir işletme seçilmeli' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
    RAISE EXCEPTION 'not_found: zincir bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  -- Çakışma kontrolü: seçilenlerden biri zaten FARKLI bir zincirdeyse tüm işlem reddedilir
  SELECT string_agg(format('%s (%s)', b.name, c.name), ', ')
    INTO v_conflict_text
  FROM public.businesses b
  JOIN public.chains c ON c.id = b.chain_id
  WHERE b.id = ANY(p_business_ids)
    AND b.chain_id IS NOT NULL
    AND b.chain_id != p_chain_id;

  IF v_conflict_text IS NOT NULL THEN
    RAISE EXCEPTION 'validation_error: şu işletmeler zaten başka bir zincirde: %', v_conflict_text
      USING ERRCODE = 'P0003';
  END IF;

  SELECT COALESCE(MAX(chain_sort_order), -1) INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  FOREACH v_id IN ARRAY p_business_ids LOOP
    v_next_sort := v_next_sort + 1;
    UPDATE public.businesses
    SET chain_id = p_chain_id, chain_sort_order = v_next_sort
    WHERE id = v_id AND (chain_id IS NULL OR chain_id = p_chain_id);
  END LOOP;

  RETURN jsonb_build_object('ok', true, 'added_count', array_length(p_business_ids, 1));
END;
$$;

REVOKE ALL ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM anon;
COMMENT ON FUNCTION public.admin_add_businesses_to_chain_v1 IS
  'Admin: seçilen işletmeleri bir zincire ekler (farklı bir zincirdeyse reddeder). Called by: app/yonetici/isletmeler/isletme-zincir-islemleri.ts.';
```

Çakışma kontrolü ile atama aynı fonksiyon çağrısı/transaction içinde olduğu için, hata fırlatılırsa hiçbir `UPDATE` kalıcı olmaz (plpgsql fonksiyon içindeki exception, o ana kadarki değişiklikleri geri alır) — kısmi uygulama riski yok.

**Yeni zincir kurma akışı** ayrı bir RPC gerektirmiyor — mevcut `admin_create_chain_v1` (2026-07-09'dan beri var) önce çağrılıp `chain_id` alınır, sonra yukarıdaki RPC aynı id ile çağrılır. İki ayrı sunucu-aksiyonu çağrısı, tek bir istemci fonksiyonunda ardışık yapılır.

## Frontend

### Yeni dosya: `app/yonetici/isletmeler/isletme-zincir-islemleri.ts`

Sunucu aksiyonları (mevcut `isletme-duzenle-islemleri.ts`'teki `isletmeAraBirlestirmeIcin` deseniyle aynı yapı):
- `zincirAra(query: string)` — `chains` tablosunda isme göre `ilike` arama (tablo zaten `anon`'a bile açık `SELECT` politikasına sahip, yeni RPC gerekmiyor), en fazla 10 sonuç.
- `isletmeleriZincireBagla(chainId: string, businessIds: string[])` — `admin_add_businesses_to_chain_v1` RPC'sini çağırır, `{ok:true}` veya `{ok:false, error}` döner.
- `yeniZincirKurVeBagla(name: string, businessIds: string[])` — önce `admin_create_chain_v1`, başarılıysa dönen `chain_id` ile `isletmeleriZincireBagla`'yı çağırır.

### Yeni dosya: `app/yonetici/isletmeler/isletme-zincire-bagla-modal.tsx`

`isletme-birlestir-bolumu.tsx` ile aynı görsel dil (semantic token'lar, `PanelActionButton`). İki sekme:
- **Var olan zincire ekle** — isim arama kutusu (debounce'lu, `zincirAra` ile), sonuçlardan birine tıklayınca seçilir, "Bağla" ile onaylanır.
- **Yeni zincir kur** — tek bir isim inputu, "Kur ve Bağla" ile `yeniZincirKurVeBagla` çağrılır.

Prop olarak seçili işletmelerin `{id, name}[]` listesini alır (üstte "N işletme: A, B, C" özeti gösterir), başarı/hata durumunu kendi içinde yönetir, `onDone: () => void` callback'iyle üst bileşene (modalı kapat + `router.refresh()`) haber verir.

### Değişiklik: `isletmeler-tablosu.tsx`

Toplu işlem çubuğuna ("N işletme seçildi" barındaki `PanelActionButton` grubuna) üçüncü buton: **"Zincire Bağla"** (`variant="secondary"`). Tıklanınca yeni modal `selected` set'inden türetilen `{id,name}` listesiyle açılır. Modal `onDone` çağırınca `setSelected(new Set())` + `router.refresh()`.

## Hata durumları

- RPC'den dönen `validation_error` mesajı (çakışan işletme+zincir isimleri dahil) doğrudan modalda gösterilir — merge akışındaki `error` state deseniyle aynı.
- Zincir bulunamadı / yetkisiz gibi durumlar da aynı şekilde yüzeye çıkar.

## Doğrulama

`pnpm run typecheck` + `pnpm run lint` (proje kuralı: Next.js değişikliği için bu ikisi yeterli, ayrı test dosyası zorunlu değil). Migration `mcp__supabase__apply_migration` ile uygulanıp `get_advisors` ile RLS/güvenlik taraması yapılacak (özellikle `admin_*` anon-revoke kuralı — CLAUDE.md kök kural).
