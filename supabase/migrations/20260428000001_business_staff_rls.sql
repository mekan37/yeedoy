-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: business_staff_rls
-- Purpose:   Extend menu + analytics RLS to allow business team members
--            (manager / editor) to manage menus and sections alongside owners.
--
-- Role hierarchy (from business_team_memberships.role):
--   owner    → full access (already handled by is_owner_of_business())
--   manager  → menu CRUD + analytics read + review responses
--   editor   → menu content edit only (no delete, no analytics)
--   staff    → read-only (no mutations)
--   viewer   → read-only (same as staff)
--
-- Strategy: add a helper function `is_business_team_member(p_business_id, roles)`
-- and add new permissive policies. Existing owner/admin policies are untouched.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Helper: is the current user a member with one of the given roles? ─────────

CREATE OR REPLACE FUNCTION public.is_business_team_member(
  p_business_id uuid,
  p_roles       text[]
)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM   public.business_team_memberships btm
    WHERE  btm.business_id  = p_business_id
      AND  btm.user_id      = auth.uid()
      AND  btm.role         = ANY(p_roles)
      AND  btm.revoked_at   IS NULL
      AND  btm.accepted_at  IS NOT NULL
  );
$$;

-- ── menus ─────────────────────────────────────────────────────────────────────

-- manager: full CRUD on menus
CREATE POLICY "menus_manager_insert"
  ON public.menus
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['manager']));

CREATE POLICY "menus_manager_update"
  ON public.menus
  FOR UPDATE
  TO authenticated
  USING  (public.is_business_team_member(business_id, ARRAY['manager']))
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['manager']));

CREATE POLICY "menus_manager_delete"
  ON public.menus
  FOR DELETE
  TO authenticated
  USING (public.is_business_team_member(business_id, ARRAY['manager']));

-- manager + editor: read all menus (including drafts)
CREATE POLICY "menus_staff_read_all"
  ON public.menus
  FOR SELECT
  TO authenticated
  USING (public.is_business_team_member(business_id, ARRAY['manager', 'editor', 'staff', 'viewer']));

-- editor: update only (name, description, content — no status transitions)
CREATE POLICY "menus_editor_update"
  ON public.menus
  FOR UPDATE
  TO authenticated
  USING  (public.is_business_team_member(business_id, ARRAY['editor']))
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['editor']));

-- ── menu_sections ─────────────────────────────────────────────────────────────

-- manager: full CRUD
CREATE POLICY "menu_sections_manager_insert"
  ON public.menu_sections
  FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['manager'])
  ));

CREATE POLICY "menu_sections_manager_update"
  ON public.menu_sections
  FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['manager'])
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['manager'])
  ));

CREATE POLICY "menu_sections_manager_delete"
  ON public.menu_sections
  FOR DELETE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['manager'])
  ));

-- editor: insert + update (no delete)
CREATE POLICY "menu_sections_editor_insert"
  ON public.menu_sections
  FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['editor'])
  ));

CREATE POLICY "menu_sections_editor_update"
  ON public.menu_sections
  FOR UPDATE
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['editor'])
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['editor'])
  ));

-- staff/viewer: already covered by public read policy on published menus;
-- allow them to read all sections via menus
CREATE POLICY "menu_sections_staff_read"
  ON public.menu_sections
  FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.menus m
    WHERE  m.id = menu_id
      AND  public.is_business_team_member(m.business_id, ARRAY['manager', 'editor', 'staff', 'viewer'])
  ));

-- ── menu_items ────────────────────────────────────────────────────────────────

-- manager: full CRUD
CREATE POLICY "menu_items_manager_insert"
  ON public.menu_items
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['manager']));

CREATE POLICY "menu_items_manager_update"
  ON public.menu_items
  FOR UPDATE
  TO authenticated
  USING  (public.is_business_team_member(business_id, ARRAY['manager']))
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['manager']));

CREATE POLICY "menu_items_manager_delete"
  ON public.menu_items
  FOR DELETE
  TO authenticated
  USING (public.is_business_team_member(business_id, ARRAY['manager']));

-- editor: insert + update (no delete)
CREATE POLICY "menu_items_editor_insert"
  ON public.menu_items
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['editor']));

CREATE POLICY "menu_items_editor_update"
  ON public.menu_items
  FOR UPDATE
  TO authenticated
  USING  (public.is_business_team_member(business_id, ARRAY['editor']))
  WITH CHECK (public.is_business_team_member(business_id, ARRAY['editor']));

-- staff/viewer: read all items (incl. unavailable) for their business
CREATE POLICY "menu_items_staff_read"
  ON public.menu_items
  FOR SELECT
  TO authenticated
  USING (public.is_business_team_member(business_id, ARRAY['manager', 'editor', 'staff', 'viewer']));

-- ── menu_item_translations ────────────────────────────────────────────────────
-- 2026-07-23 fix: public.menu_item_translations was never created (the app
-- ended up using the generic public.menu_translations entity_type/entity_id
-- table instead — see 20260427000001_menu_section_translation_rpc.sql). This
-- block is guarded so a fresh `supabase db reset` doesn't fail on a table
-- that doesn't exist; if the table exists in some environment, behavior is
-- unchanged.

DO $$
BEGIN
  IF to_regclass('public.menu_item_translations') IS NOT NULL THEN
    -- manager + editor can upsert translations
    EXECUTE $policy$
      CREATE POLICY "menu_item_translations_staff_insert"
        ON public.menu_item_translations
        FOR INSERT
        TO authenticated
        WITH CHECK (EXISTS (
          SELECT 1 FROM public.menu_items mi
          WHERE  mi.id = menu_item_id
            AND  public.is_business_team_member(mi.business_id, ARRAY['manager', 'editor'])
        ))
    $policy$;

    EXECUTE $policy$
      CREATE POLICY "menu_item_translations_staff_update"
        ON public.menu_item_translations
        FOR UPDATE
        TO authenticated
        USING (EXISTS (
          SELECT 1 FROM public.menu_items mi
          WHERE  mi.id = menu_item_id
            AND  public.is_business_team_member(mi.business_id, ARRAY['manager', 'editor'])
        ))
        WITH CHECK (EXISTS (
          SELECT 1 FROM public.menu_items mi
          WHERE  mi.id = menu_item_id
            AND  public.is_business_team_member(mi.business_id, ARRAY['manager', 'editor'])
        ))
    $policy$;
  END IF;
END
$$;
