-- Destek Sistemi (Owner) — support_tickets'a business_id + owner-facing RLS + touch RPC.
-- Admin tarafı (support_tickets/support_ticket_messages, 20260520000001) değişmiyor,
-- sadece owner'ın kendi taleplerine eriştiği yeni policy'ler ekleniyor.

ALTER TABLE public.support_tickets
  ADD COLUMN IF NOT EXISTS business_id uuid REFERENCES public.businesses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_support_tickets_business_id ON public.support_tickets(business_id);

DROP POLICY IF EXISTS support_tickets_owner_select ON public.support_tickets;
CREATE POLICY support_tickets_owner_select ON public.support_tickets
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS support_tickets_owner_insert ON public.support_tickets;
CREATE POLICY support_tickets_owner_insert ON public.support_tickets
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid()
    AND status = 'open'
    AND priority = 'medium'
    AND assigned_to IS NULL
    AND (
      business_id IS NULL
      OR public.is_owner_of_business(business_id)
    )
  );

DROP POLICY IF EXISTS support_ticket_messages_owner_select ON public.support_ticket_messages;
CREATE POLICY support_ticket_messages_owner_select ON public.support_ticket_messages
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

DROP POLICY IF EXISTS support_ticket_messages_owner_insert ON public.support_ticket_messages;
CREATE POLICY support_ticket_messages_owner_insert ON public.support_ticket_messages
  FOR INSERT TO authenticated WITH CHECK (
    sender = 'user'
    AND EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Owner kendi ticket'ının updated_at'ini güncelleyemez (support_tickets_admin_all
-- FOR ALL policy'si sadece admin'e UPDATE izni veriyor) — mesaj gönderdiğinde
-- sıralamanın güncel kalması için dar kapsamlı bir SECURITY DEFINER RPC.
CREATE OR REPLACE FUNCTION public.touch_support_ticket_v1(p_ticket_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.support_tickets
  SET updated_at = now()
  WHERE id = p_ticket_id AND user_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.touch_support_ticket_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.touch_support_ticket_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.touch_support_ticket_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.touch_support_ticket_v1 IS
  'Owner: kendi destek talebinin updated_at alanını günceller (yeni mesaj sonrası). Called by: app/sahip/destek/destek-islemleri.ts.';
