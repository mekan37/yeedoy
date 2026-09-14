-- Sahip Paneli Güvenlik Denetimi P3: Çöp kutusu RPC'lerinde açık anon
-- revoke eksikti (CLAUDE.md kuralı). Hepsi auth.uid() IS NULL
-- kontrolüyle fail-closed olduğu için şu an sömürülebilir değil, ama
-- proje konvansiyonu + gelecekteki bir body değişikliğine karşı defense
-- in depth için anon EXECUTE açıkça kaldırıldı.
revoke execute on function public.owner_permanently_delete_menu_v1(uuid) from anon;
revoke execute on function public.owner_permanently_delete_menu_item_v1(uuid) from anon;
revoke execute on function public.owner_permanently_delete_menu_item_photo_v1(uuid) from anon;
revoke execute on function public.owner_empty_trash_v1(uuid) from anon;
revoke execute on function public.owner_restore_menu_item_v1(uuid) from anon;
revoke execute on function public.owner_restore_menu_item_photo_v1(uuid) from anon;
revoke execute on function public.owner_soft_delete_menu_item_photo_v1(uuid) from anon;
