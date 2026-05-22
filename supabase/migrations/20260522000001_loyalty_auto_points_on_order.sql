-- P-21: Sadakat otomatik puan — sipariş tamamlanınca
-- Trigger: table_orders status 'done' olunca müşteriye otomatik puan ekle

create or replace function public.trg_award_loyalty_on_order_done()
returns trigger
language plpgsql
security definer
as $$
declare
  v_pts int := 5; -- Tamamlanan her sipariş için 5 puan
  v_user_id uuid;
begin
  -- Sadece 'done' durumuna geçişte tetikle (önceki durum farklıysa)
  if NEW.status = 'done' and (OLD.status is null or OLD.status <> 'done') then
    -- Sipariş müşteri ID'sini bul
    v_user_id := NEW.customer_user_id;

    -- customer_user_id yoksa user_id'yi dene
    if v_user_id is null then
      v_user_id := NEW.user_id;
    end if;

    if v_user_id is not null and NEW.business_id is not null then
      begin
        perform public.award_loyalty_points_v1(
          NEW.business_id,
          v_user_id,
          v_pts
        );
      exception when others then
        -- award_loyalty_points_v1 yoksa veya hata varsa sessizce geç
        null;
      end;
    end if;
  end if;

  return NEW;
end;
$$;

-- Trigger varsa kaldır, yeniden oluştur
drop trigger if exists trg_award_loyalty_on_order_done on public.table_orders;

create trigger trg_award_loyalty_on_order_done
  after update of status on public.table_orders
  for each row
  execute procedure public.trg_award_loyalty_on_order_done();

comment on function public.trg_award_loyalty_on_order_done() is
  'P-21: Sipariş tamamlandığında (status=done) müşteriye otomatik sadakat puanı ekler.';
