-- CRM v2 — müşteri notu ve etiketleme. bkz. docs/superpowers/specs/2026-08-11-crm-v2-not-etiket-design.md
--
-- İki yeni tablo, RLS enabled + policy yok (tüm erişim SECURITY
-- DEFINER RPC üzerinden — client'a doğrudan hiçbir GRANT yok).
-- Yetkilendirme CRM v1'deki desenle aynı: has_business_permission_v1
-- (p_business_id, 'menu_write') — editor+, staff erişemez.

CREATE TABLE public.customer_notes (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  note        text not null,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);
CREATE INDEX idx_customer_notes_business_user ON public.customer_notes(business_id, user_id, created_at DESC);
ALTER TABLE public.customer_notes ENABLE ROW LEVEL SECURITY;
-- Supabase, public şemadaki her yeni tabloya anon+authenticated için varsayılan
-- olarak tam GRANT veriyor (bkz. pg_default_acl). Buradaki tek erişim yolu
-- SECURITY DEFINER RPC'ler olduğundan, bu varsayılan GRANT'ları açıkça kapatıyoruz.
REVOKE ALL ON public.customer_notes FROM anon, authenticated;

CREATE TABLE public.customer_tags (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  tag         text not null check (length(trim(tag)) > 0 and length(tag) <= 40),
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  unique (business_id, user_id, tag)
);
CREATE INDEX idx_customer_tags_business_user ON public.customer_tags(business_id, user_id);
ALTER TABLE public.customer_tags ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.customer_tags FROM anon, authenticated;

-- ── add_customer_note_v1 ─────────────────────────────────────────────────────
CREATE FUNCTION public.add_customer_note_v1(p_business_id uuid, p_user_id uuid, p_note text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_note_id uuid;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF trim(coalesce(p_note, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: not boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.customer_notes (business_id, user_id, note, created_by)
  VALUES (p_business_id, p_user_id, trim(p_note), auth.uid())
  RETURNING id INTO v_note_id;

  RETURN v_note_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.add_customer_note_v1 IS
  'Owner/yönetici (menu_write, editor+): müşteriye zaman damgalı not ekler. Called by: app/sahip/musteriler/[user_id] (not ekleme formu).';

-- ── add_customer_tag_v1 ──────────────────────────────────────────────────────
CREATE FUNCTION public.add_customer_tag_v1(p_business_id uuid, p_user_id uuid, p_tag text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag_id uuid;
  v_tag    text;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tag := trim(coalesce(p_tag, ''));
  IF v_tag = '' OR length(v_tag) > 40 THEN
    RAISE EXCEPTION 'validation_error: etiket 1-40 karakter olmalı' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.customer_tags (business_id, user_id, tag, created_by)
  VALUES (p_business_id, p_user_id, v_tag, auth.uid())
  ON CONFLICT (business_id, user_id, tag) DO NOTHING
  RETURNING id INTO v_tag_id;

  IF v_tag_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: bu etiket zaten ekli' USING ERRCODE = 'P0003';
  END IF;

  RETURN v_tag_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.add_customer_tag_v1 IS
  'Owner/yönetici (menu_write, editor+): müşteriye serbest metin etiket ekler. Aynı etiket tekrar eklenemez. Called by: app/sahip/musteriler/[user_id] (etiket ekleme formu).';

-- ── remove_customer_tag_v1 ───────────────────────────────────────────────────
CREATE FUNCTION public.remove_customer_tag_v1(p_tag_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
BEGIN
  SELECT business_id INTO v_business_id FROM public.customer_tags WHERE id = p_tag_id;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found: etiket bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF NOT public.has_business_permission_v1(v_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.customer_tags WHERE id = p_tag_id;
END;
$$;

REVOKE ALL ON FUNCTION public.remove_customer_tag_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_customer_tag_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.remove_customer_tag_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.remove_customer_tag_v1 IS
  'Owner/yönetici (menu_write, editor+): bir müşteri etiketini siler. Called by: app/sahip/musteriler/[user_id] (etiket rozeti üzerindeki x ikonu).';

-- ── get_business_customers_v1 (genişletildi: tags alanı eklendi) ────────────
CREATE OR REPLACE FUNCTION public.get_business_customers_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id       uuid;
  v_reward_threshold int;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  IF v_program_id IS NOT NULL THEN
    SELECT reward_threshold INTO v_reward_threshold FROM public.loyalty_programs WHERE id = v_program_id;
  END IF;

  RETURN COALESCE(
    (
      WITH customer_ids AS (
        SELECT user_id FROM public.reviews
          WHERE business_id = p_business_id AND user_id IS NOT NULL AND status = 'approved'
        UNION
        SELECT user_id FROM public.reservations
          WHERE business_id = p_business_id AND user_id IS NOT NULL
        UNION
        SELECT user_id FROM public.business_follows
          WHERE business_id = p_business_id
        UNION
        SELECT lm.user_id FROM public.loyalty_members lm
          WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id
      ),
      summary AS (
        SELECT
          ci.user_id,
          (SELECT count(*) FROM public.reviews r
             WHERE r.business_id = p_business_id AND r.user_id = ci.user_id AND r.status = 'approved') AS review_count,
          (SELECT count(*) FROM public.reservations rs
             WHERE rs.business_id = p_business_id AND rs.user_id = ci.user_id) AS reservation_count,
          (SELECT lm.progress FROM public.loyalty_members lm
             WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = ci.user_id) AS loyalty_progress,
          (SELECT coalesce(jsonb_agg(jsonb_build_object('id', ct.id, 'tag', ct.tag) ORDER BY ct.created_at), '[]'::jsonb)
             FROM public.customer_tags ct
             WHERE ct.business_id = p_business_id AND ct.user_id = ci.user_id) AS tags,
          GREATEST(
            COALESCE((SELECT max(r.created_at) FROM public.reviews r
               WHERE r.business_id = p_business_id AND r.user_id = ci.user_id AND r.status = 'approved'), 'epoch'::timestamptz),
            COALESCE((SELECT max(rs.created_at) FROM public.reservations rs
               WHERE rs.business_id = p_business_id AND rs.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(bf.created_at) FROM public.business_follows bf
               WHERE bf.business_id = p_business_id AND bf.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(le.created_at) FROM public.loyalty_events le
               JOIN public.loyalty_members lm2 ON lm2.id = le.member_id
               WHERE v_program_id IS NOT NULL AND lm2.program_id = v_program_id AND lm2.user_id = ci.user_id), 'epoch'::timestamptz)
          ) AS last_interaction_at
        FROM customer_ids ci
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', s.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'avatar_url', up.avatar_url,
          'last_interaction_at', s.last_interaction_at,
          'review_count', s.review_count,
          'reservation_count', s.reservation_count,
          'loyalty_progress', s.loyalty_progress,
          'loyalty_reward_threshold', v_reward_threshold,
          'tags', s.tags
        )
        ORDER BY s.last_interaction_at DESC
      )
      FROM summary s
      LEFT JOIN public.user_profiles up ON up.user_id = s.user_id
    ),
    '[]'::jsonb
  );
END;
$$;

-- ── get_customer_timeline_v1 (genişletildi: 'note' olay tipi eklendi) ───────
CREATE OR REPLACE FUNCTION public.get_customer_timeline_v1(p_business_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  RETURN COALESCE(
    (
      SELECT jsonb_agg(evt ORDER BY (evt->>'occurred_at')::timestamptz DESC)
      FROM (
        SELECT jsonb_build_object(
          'event_type', 'review',
          'occurred_at', r.created_at,
          'summary', r.rating || ' yıldız' || CASE WHEN r.title IS NOT NULL AND trim(r.title) <> '' THEN ' — "' || r.title || '"' ELSE '' END
        ) AS evt
        FROM public.reviews r
        WHERE r.business_id = p_business_id AND r.user_id = p_user_id AND r.status = 'approved'

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'reservation',
          'occurred_at', rs.created_at,
          'summary', rs.party_size || ' kişi, ' || to_char(rs.reservation_date, 'DD.MM.YYYY') || ' ' || to_char(rs.reservation_time, 'HH24:MI')
        )
        FROM public.reservations rs
        WHERE rs.business_id = p_business_id AND rs.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', CASE WHEN le.source = 'redeem' THEN 'loyalty_redeem' ELSE 'loyalty_scan' END,
          'occurred_at', le.created_at,
          'summary', CASE WHEN le.source = 'redeem' THEN 'Ödül kullanıldı' ELSE '+' || le.amount || ' ilerleme' END
        )
        FROM public.loyalty_events le
        JOIN public.loyalty_members lm ON lm.id = le.member_id
        WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'follow',
          'occurred_at', bf.created_at,
          'summary', 'İşletmeyi takip etmeye başladı'
        )
        FROM public.business_follows bf
        WHERE bf.business_id = p_business_id AND bf.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'note',
          'occurred_at', cn.created_at,
          'summary', cn.note
        )
        FROM public.customer_notes cn
        WHERE cn.business_id = p_business_id AND cn.user_id = p_user_id
      ) sub
    ),
    '[]'::jsonb
  );
END;
$$;
