-- KVKK/GDPR admin sayfası "Politikalar & Belgeler" için: public /yasal ve
-- /yasal/[slug] sayfaları legal_documents tablosunu zaten opsiyonel olarak
-- okuyordu (42P01 hata kodunda STATIC_CONTENT'e fallback ediyordu) ama tablo
-- hiç oluşturulmamıştı. Bu migration tabloyu gerçekten kurar ve mevcut 3
-- statik belgeyi (privacy/terms/cookies — app/(genel)/yasal/[slug]/page.tsx
-- STATIC_CONTENT'inden birebir) satır olarak taşır, böylece admin panelden
-- düzenleme gerçek etkiye sahip olur. yorum-politikasi ayrı, kendi sabit
-- route'una sahip olduğu için bu tabloya dahil edilmedi.

CREATE TABLE public.legal_documents (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title        text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 120),
  description  text,
  content      text NOT NULL CHECK (char_length(btrim(content)) > 0),
  is_published boolean NOT NULL DEFAULT false,
  sort_order   integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "legal_documents_public_select_published"
  ON public.legal_documents
  FOR SELECT
  TO anon, authenticated
  USING (is_published = true);

CREATE POLICY "legal_documents_admin_select_all"
  ON public.legal_documents
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

GRANT SELECT ON public.legal_documents TO anon, authenticated;

CREATE OR REPLACE FUNCTION private.tg_legal_documents_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_legal_documents_set_updated_at
  BEFORE UPDATE ON public.legal_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_legal_documents_set_updated_at();

-- ── RPC'ler ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_upsert_legal_document_v1(
  p_id          uuid,
  p_slug        text,
  p_title       text,
  p_description text,
  p_content     text,
  p_is_published boolean,
  p_sort_order  integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized: KVKK / GDPR izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF btrim(coalesce(p_slug, '')) = '' OR btrim(coalesce(p_title, '')) = '' OR btrim(coalesce(p_content, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: slug, başlık ve içerik zorunlu' USING ERRCODE = 'P0003';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.legal_documents (slug, title, description, content, is_published, sort_order, updated_by)
    VALUES (btrim(p_slug), btrim(p_title), nullif(btrim(coalesce(p_description, '')), ''), p_content, p_is_published, coalesce(p_sort_order, 0), auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.legal_documents
    SET slug = btrim(p_slug), title = btrim(p_title), description = nullif(btrim(coalesce(p_description, '')), ''),
        content = p_content, is_published = p_is_published, sort_order = coalesce(p_sort_order, 0), updated_by = auth.uid()
    WHERE id = p_id
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found: Belge bulunamadı' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_legal_document_v1(uuid, text, text, text, text, boolean, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_legal_document_v1(uuid, text, text, text, text, boolean, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_legal_document_v1(uuid, text, text, text, text, boolean, integer) FROM anon;
COMMENT ON FUNCTION public.admin_upsert_legal_document_v1 IS 'Yasal belge oluşturur/günceller (p_id null ise oluşturur). page:kvkk-gdpr izni gerektirir. Called by: app/sunucu/yonetici/kvkk-gdpr/route.ts (POST).';


CREATE OR REPLACE FUNCTION public.admin_delete_legal_document_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_permission_v1('page:kvkk-gdpr') THEN
    RAISE EXCEPTION 'unauthorized: KVKK / GDPR izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.legal_documents WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Belge bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_legal_document_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_legal_document_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_legal_document_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_delete_legal_document_v1 IS 'Yasal belgeyi siler. page:kvkk-gdpr izni gerektirir. Called by: app/sunucu/yonetici/kvkk-gdpr/route.ts (DELETE).';

-- ── Mevcut statik içeriğin taşınması (app/(genel)/yasal/[slug]/page.tsx STATIC_CONTENT ile birebir) ──

INSERT INTO public.legal_documents (slug, title, description, content, is_published, sort_order) VALUES
('privacy', 'Gizlilik Politikası', 'Kişisel verilerinizin nasıl işlendiği', $doc$## 1. Topladığımız Veriler

Ad, e-posta, konum (isteğe bağlı), kullanım verileri ve cihaz bilgisi toplanmaktadır.

## 2. Verilerin Kullanımı

Veriler; hizmet sunumu, kişiselleştirme, iletişim ve yasal yükümlülükler için kullanılır.

## 3. Veri Paylaşımı

Verileriniz üçüncü taraflara satılmaz. Hizmet sağlayıcılarla ve yasal zorunluluk halinde yetkililere paylaşılabilir.

## 4. KVKK / GDPR

6698 sayılı KVKK ve GDPR kapsamında haklarınız: erişim, düzeltme, silme, itiraz ve veri taşınabilirliği.

## 5. Çerezler

Teknik çerezler zorunludur; pazarlama çerezleri için onayınız alınır.

## 6. Veri Güvenliği

Verileriniz şifreleme ve erişim kontrolü ile korunmaktadır.

## 7. Veri Talebi

kvkk@yeedoy.com adresinden veri erişim, düzeltme veya silme talebinde bulunabilirsiniz.$doc$, true, 1),
('terms', 'Kullanım Şartları', 'Hizmet kullanım koşulları', $doc$## 1. Kabul

Yeedoy hizmetlerini kullanarak bu şartları kabul etmiş sayılırsınız.

## 2. Hizmet Tanımı

Yeedoy, restoran menülerini dijitalleştiren, fiyat katkısı ve yorum platformu ile işletme paneli sunan bir hizmettir.

## 3. Kullanıcı Hesapları

Hesap açmak için 18 yaşında veya üzeri olmanız gerekmektedir. Hesap güvenliğinden siz sorumlusunuz.

## 4. Kabul Edilemez Kullanım

Sistemi kötüye kullanmak, spam göndermek, başkalarını taklit etmek veya zararlı içerik paylaşmak yasaktır.

## 5. Fikri Mülkiyet

Yeedoy markası, logosu ve orijinal içerikler telif hakkıyla korunmaktadır.

## 6. Sorumluluk Sınırlaması

Yeedoy, kullanıcı tarafından oluşturulan içeriklerden doğan zararlardan sorumlu tutulamaz.

## 7. Değişiklikler

Şartları önceden haber vererek değiştirme hakkımızı saklı tutarız. Güncel şartlar daima bu sayfada yayımlanır.

## 8. İletişim

Sorularınız için: hukuk@yeedoy.com$doc$, true, 2),
('cookies', 'Çerez Politikası', 'Çerez kullanımı hakkında bilgi', $doc$## Çerez Nedir?

Çerezler, tarayıcınıza yerleştirilen küçük metin dosyalarıdır.

## Kullandığımız Çerezler

**Zorunlu Çerezler:** Giriş oturumu, güvenlik tokeni gibi teknik işlevler için gereklidir.

**Analitik Çerezler:** Kullanım istatistikleri için anonimleştirilmiş veri toplanır (isteğe bağlı onay).

**Tercih Çerezleri:** Tema, dil ve konum tercihleri için kullanılır.

## Çerez Yönetimi

Tarayıcı ayarlarından çerezleri yönetebilirsiniz. Zorunlu çerezleri devre dışı bırakmak hizmetin çalışmasını engelleyebilir.

## İletişim

cerez@yeedoy.com$doc$, true, 3);
