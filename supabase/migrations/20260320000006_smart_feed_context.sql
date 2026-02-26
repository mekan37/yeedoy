create or replace function public.get_smart_feed_v2(
  p_limit integer,
  p_offset integer,
  p_city text default null,
  p_districts text[] default null,
  p_categories text[] default null,
  p_bundles text[] default null,
  p_price_max_cents integer default null,
  p_weather_hint text default null,
  p_time_label text default null,
  p_day_label text default null
)
returns table (
  event_id uuid,
  event_type text,
  business_id uuid,
  business_name text,
  created_at timestamptz,
  ref_type text,
  ref_id uuid,
  payload jsonb
)
language plpgsql
security definer
as $$
begin
  if to_regprocedure(
       'public.get_smart_feed_v1(integer,integer,text,text[],text[],text[],integer)'
     ) is not null then
    return query execute
      'select
         event_id,
         event_type,
         business_id,
         business_name,
         created_at,
         ref_type,
         ref_id,
         coalesce(payload, ''{}''::jsonb)
           || jsonb_strip_nulls(
                jsonb_build_object(
                  ''weather_hint'', $8,
                  ''time_label'', $9,
                  ''day_label'', $10
                )
              ) as payload
       from public.get_smart_feed_v1($1,$2,$3,$4,$5,$6,$7)'
      using
        p_limit,
        p_offset,
        p_city,
        p_districts,
        p_categories,
        p_bundles,
        p_price_max_cents,
        p_weather_hint,
        p_time_label,
        p_day_label;
  else
    return query
      select
        null::uuid,
        null::text,
        null::uuid,
        null::text,
        null::timestamptz,
        null::text,
        null::uuid,
        '{}'::jsonb
      where false;
  end if;
end;
$$;
