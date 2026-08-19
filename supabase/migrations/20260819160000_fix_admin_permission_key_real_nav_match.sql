-- Önceki migration'daki izin kataloğu, bu worktree/main'de gerçekte var olmayan
-- (uncommitted, sadece ana checkout'ta yaşayan) bir kenar çubuğu versiyonuna göre
-- yazılmıştı. Gerçek admin nav'ı (yonetici-kabuk-istemcisi.tsx, committed) ile
-- eşleştiriliyor: 'page:kuyruklar' → 'page:kuyruk' olarak yeniden adlandırılıyor,
-- 4 eksik sayfa ekleniyor (arama, itirazlar/claims, denetim-kaydi, toplu-islemler).

ALTER TYPE public.admin_permission_key RENAME VALUE 'page:kuyruklar' TO 'page:kuyruk';
ALTER TYPE public.admin_permission_key ADD VALUE 'page:arama';
ALTER TYPE public.admin_permission_key ADD VALUE 'page:itirazlar-claims';
ALTER TYPE public.admin_permission_key ADD VALUE 'page:denetim-kaydi';
ALTER TYPE public.admin_permission_key ADD VALUE 'page:toplu-islemler';
