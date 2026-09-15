-- Canlı Supabase Güvenlik & Bütünlük Denetimi P3 grubu. Zaten düzeltilmiş
-- olanlar (admin_kpi_summary_v1 PUBLIC grant'i, purge_rate_limit_buckets_v1,
-- mark_expired_temp_uploads_v1, OSM boundary batch ailesi, rls_auto_enable —
-- event trigger, PostgREST'ten hiç çağrılamaz, artifact'ın kendisi de "aksiyon
-- gerekmiyor" diyor) canlıdan doğrulanıp atlandı.

-- ── refresh_businesses_with_stats_mv: parametresiz, pahalı REFRESH
-- MATERIALIZED VIEW CONCURRENTLY tetikleyici, hiçbir cron.job'da yok —
-- anon-çağrılabilir kalması yalnızca kaynak tüketimi riski.
revoke execute on function public.refresh_businesses_with_stats_mv() from anon, authenticated, public;

-- ── scheduled_menu_activation: parametresiz, hiçbir cron.job'da/çağıran
-- kodda yok (muhtemelen zamanlaması hiç kurulmamış — ayrı bir ürün/ops
-- takibi gerekiyor, bu denetimin kapsamı dışında). Güvenlik açısından:
-- anon'un tetikleyebilmesi gereksiz bir yazma yüzeyi.
revoke execute on function public.scheduled_menu_activation() from anon, authenticated, public;

-- ── submit_receipt_submission_v1 / vote_business_fee_v1: gövde içi kontrol
-- zaten doğru (auth.uid() kontrolü + rate limit) — yalnızca gereksiz
-- anon grant'i kapatılıyor, davranış değişmiyor.
revoke execute on function public.submit_receipt_submission_v1(uuid, text, jsonb) from anon, public;
revoke execute on function public.vote_business_fee_v1(uuid, text, boolean, text) from anon, public;

-- ── submit_review_v1: v2/v3'ün küfür-strike zincirine hiç bağlı değil,
-- uygulama v3 kullanıyor (mobil menu_repository fallback zinciri
-- v5→v3→v2) — v1 hiçbir üretim çağrı noktasından kullanılmıyor.
revoke execute on function public.submit_review_v1(uuid, integer, text, text) from anon, authenticated, public;

-- ── is_edge_ip_denied_v1: write-gatekeeper edge function service_role ile
-- çağırıyor — service_role grant'i korunuyor, yalnızca anon/authenticated
-- kapatılıyor.
revoke execute on function public.is_edge_ip_denied_v1(text) from anon, authenticated, public;

-- ── get_moderation_templates_v1: admin moderasyon şablonlarının metnini
-- (hangi ihlalde ne yazıldığını) anon'a sızdırıyordu — kötü niyetli
-- kullanıcıların moderasyon dilini/kalıplarını öğrenip atlatmasına yol açar.
revoke execute on function public.get_moderation_templates_v1(text) from anon, public;

-- ── get_owner_reviews_v1: sahiplik kontrolü hiç yoktu VE 'pending'
-- (henüz moderasyondan geçmemiş) yorumları da döndürüyordu — herhangi bir
-- business_id ile henüz yayınlanmamış yorum içeriği sızdırılabiliyordu.
create or replace function public.get_owner_reviews_v1(p_business_id uuid, p_sort text default 'newest'::text, p_limit integer default 20, p_offset integer default 0)
returns table(id uuid, rating integer, title text, content text, helpful_count integer, quality_score numeric, created_at timestamptz, status text, reply_id uuid, reply_content text, reply_at timestamptz)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'business_read')) then
    raise exception 'forbidden' using errcode = 'P0002';
  end if;

  return query
    select
      r.id, r.rating, r.title, r.content,
      coalesce(r.helpful_count, 0) as helpful_count,
      coalesce(r.helpful_count, 0)::numeric as quality_score,
      r.created_at, r.status,
      rr.id as reply_id, rr.content as reply_content, rr.created_at as reply_at
    from public.reviews r
    left join public.review_replies rr on rr.review_id = r.id
    where r.business_id = p_business_id
      and r.status in ('approved', 'pending')
    order by
      case when p_sort = 'helpful' then r.helpful_count end desc nulls last,
      case when p_sort = 'newest'  then r.created_at    end desc nulls last
    limit p_limit
    offset p_offset;
end;
$function$;
revoke execute on function public.get_owner_reviews_v1(uuid, text, integer, integer) from anon, public;

-- ── bump_collection_engagement_v1: auth kontrolü yoktu, p_delta sınırsızdı
-- (rastgele collection_key'e büyük pozitif/negatif değer yazılabiliyordu).
create or replace function public.bump_collection_engagement_v1(p_collection_key text, p_delta integer default 1)
returns table(engagement_count integer)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_delta int := greatest(least(coalesce(p_delta, 1), 1), -1);
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  insert into public.collection_social_stats(collection_key)
  values (p_collection_key)
  on conflict (collection_key) do nothing;

  update public.collection_social_stats
    set engagement_count = greatest(engagement_count + v_delta, 0),
        updated_at = now()
  where collection_key = p_collection_key;

  return query
    select engagement_count
    from public.collection_social_stats
    where collection_key = p_collection_key;
end;
$function$;
revoke execute on function public.bump_collection_engagement_v1(text, integer) from anon, public;

-- ── increment_push_campaign_open_v1: hiçbir call-site'ta kullanılmıyor
-- (yalnızca type tanımı), auth kontrolü yok, keyfi campaign_id ile sayaç
-- manipüle edilebiliyordu — şu an ölü, gereksiz anon/authenticated grant'i
-- kapatıldı.
revoke execute on function public.increment_push_campaign_open_v1(uuid) from anon, authenticated, public;

-- ── menu_media_public_read / menu_media_read_all: birebir duplicate SELECT
-- politikası — biri düşürüldü.
drop policy if exists menu_media_read_all on storage.objects;

-- ── business_fee_votes: user_id/note (kimin ne yazdığı) herkese açık
-- okunuyordu — toplam oy sonucu zaten business_fee_flags üzerinden public;
-- ham satırlarda kullanıcı bazlı veri kolon düzeyinde kapatıldı.
revoke select (user_id, note) on public.business_fee_votes from anon, authenticated;

-- ── collection_shares: created_by herkese açık okunuyordu — kolon düzeyinde
-- kapatıldı. NOT: "unlisted link" semantiğinin asıl kırığı (herkesin tüm
-- share kayıtlarını slug bilmeden LISTELEYEBILMESİ, yalnızca kendi slug'ını
-- sorgulayamaması) RLS ile düzeltilemez — slug-bazlı erişimi bir RPC'ye
-- taşımak gerekir (iki platformda da client değişikliği ister); bilinçli
-- olarak ayrı bir işe ertelendi.
revoke select (created_by) on public.collection_shares from anon, authenticated;
