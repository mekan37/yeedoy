REVOKE EXECUTE ON FUNCTION public.owner_list_reservations_v1(
  UUID, TEXT, DATE, DATE, INT, INT
) FROM anon;

REVOKE EXECUTE ON FUNCTION public.owner_update_reservation_status_v1(
  UUID, UUID, TEXT, TEXT
) FROM anon;

DROP POLICY IF EXISTS "reservations_select_policy" ON public.reservations;
DROP POLICY IF EXISTS "reservations_owner_all_policy" ON public.reservations;

CREATE POLICY "reservations_select_policy"
  ON public.reservations
  FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );

CREATE POLICY "reservations_owner_insert_policy"
  ON public.reservations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );

CREATE POLICY "reservations_owner_update_policy"
  ON public.reservations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );

CREATE POLICY "reservations_owner_delete_policy"
  ON public.reservations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = reservations.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );
