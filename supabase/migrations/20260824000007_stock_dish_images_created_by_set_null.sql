-- Code-quality review'da bulundu: stock_dish_images.created_by FK'si ON DELETE
-- SET NULL kullanmıyordu — bu sprintte eklenen her created_by/updated_by
-- attribution kolonu (admin_roller_izin_sistemi, admin_alert_rules,
-- legal_documents, chain_menu_system) bu deseni kullanıyor. Eksik olursa,
-- görsel ekleyen admin auth.users'tan silindiğinde (KVKK/GDPR silme akışı)
-- FK ihlaliyle silme başarısız olurdu.
ALTER TABLE public.stock_dish_images DROP CONSTRAINT stock_dish_images_created_by_fkey;
ALTER TABLE public.stock_dish_images
  ADD CONSTRAINT stock_dish_images_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
