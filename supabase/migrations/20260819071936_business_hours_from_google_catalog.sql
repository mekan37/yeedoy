create or replace function public.insert_business_hours_from_google_catalog_v1()
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare v_count int;
begin
  set local statement_timeout = '0';

  with matches as (
    select es.business_id, cat.opening_hours,
           row_number() over (partition by es.business_id order by cat.last_seen_at desc) as rn
    from public.business_external_sources es
    join private.google_maps_places_catalog cat
      on cat.provider = es.provider and cat.source_key = es.source_key
    where es.provider = 'google_maps' and cat.opening_hours is not null
  ),
  best as (select business_id, opening_hours from matches where rn = 1),
  day_map(day_name, dow) as (
    values ('Pazar',0),('Pazartesi',1),('Salı',2),('Çarşamba',3),('Perşembe',4),('Cuma',5),('Cumartesi',6)
  ),
  day_entries as (
    select b.business_id, dm.dow, b.opening_hours->dm.day_name as periods
    from best b
    cross join day_map dm
    where b.opening_hours ? dm.day_name
  ),
  parsed as (
    select
      business_id, dow,
      jsonb_array_length(periods) as period_count,
      case when jsonb_array_length(periods) = 1 and periods->>0 = 'Kapalı' then true else false end as is_closed,
      case
        when jsonb_array_length(periods) = 1 and periods->>0 = '24 saat açık' then '00:00'::time
        when jsonb_array_length(periods) = 1 and (periods->>0) ~ '^[0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2}$'
          then split_part(periods->>0, '–', 1)::time
        else null
      end as open_time,
      case
        when jsonb_array_length(periods) = 1 and periods->>0 = '24 saat açık' then '23:59'::time
        when jsonb_array_length(periods) = 1 and (periods->>0) ~ '^[0-9]{2}:[0-9]{2}–[0-9]{2}:[0-9]{2}$'
          then split_part(periods->>0, '–', 2)::time
        else null
      end as close_time
    from day_entries
  ),
  insertable as (
    select business_id, dow,
           coalesce(open_time, '09:00'::time) as open_time,
           coalesce(close_time, '22:00'::time) as close_time,
           is_closed
    from parsed
    where is_closed = true
       or (period_count = 1 and open_time is not null and close_time is not null)
    -- period_count 0/2/3+ (çoklu açılış periyodu) veya tanınmayan metin: atlanır, tahmin yapılmaz.
    -- Ne business_weekly_hours ne de legacy business_hours günde birden fazla periyodu destekliyor.
  )
  insert into public.business_weekly_hours (business_id, day_of_week, open_time, close_time, is_closed)
  select business_id, dow, open_time, close_time, is_closed
  from insertable
  on conflict (business_id, day_of_week) do nothing;
  -- DO NOTHING (DO UPDATE değil): o gün için zaten bir satır varsa (owner/kullanıcı girişi ya da
  -- daha önceki bir Google import'u) Google verisiyle asla ezilmez.

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.insert_business_hours_from_google_catalog_v1() from public, anon, authenticated;
grant execute on function public.insert_business_hours_from_google_catalog_v1() to service_role;

comment on function public.insert_business_hours_from_google_catalog_v1 is
  'business_external_sources(provider=google_maps) ile ilişkili işletmeler için Google opening_hours JSONB''ını public.business_weekly_hours''a normalize eder. businesses.opening_hours diye bir JSONB kolonu oluşturulmaz/kullanılmaz. ON CONFLICT(business_id,day_of_week) DO NOTHING: mevcut (owner/kullanıcı girişli veya önceki) bir gün satırı asla overwrite edilmez. Bir günde 2+ açılış periyodu varsa (ne business_weekly_hours ne legacy business_hours bunu destekliyor) o gün atlanır, tahmin yapılmaz. "24 saat açık"→00:00-23:59, "Kapalı"→is_closed=true.';
