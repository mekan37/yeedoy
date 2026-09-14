-- Sahip Paneli Güvenlik Denetimi P1: business_media tablosunda hiçbir
-- yazma RLS politikası yoktu (yalnızca public SELECT). Silme işlemi
-- tamamen service_role ile yapılıyordu — uygulama katmanındaki
-- canManageBusiness kontrolü doğru çalışıyor, ama RLS hiçbir ikinci
-- katman savunma sağlamıyordu (P0-3/add_business_media_v1 ile aynı kök
-- neden ailesi). can_manage_business_v1 (menu_write, rank>=300) ile aynı
-- eşiği kullanan bir DELETE politikası eklendi; route artık service_role
-- yerine kullanıcının kendi RLS'li client'ını kullanıyor.
create policy business_media_delete_manager on business_media
  for delete to authenticated
  using (is_admin() or has_business_permission_v1(business_id, 'menu_write'));
