-- P1: 'page:yoresel-mutfak' izin anahtari TS tarafinda (admin-izinler.ts)
-- tanimliydi ve /yonetici/yoresel-mutfak sayfasi + roller UI'i bunu
-- kullaniyordu, ama admin_permission_key DB enum'una hic eklenmemisti.
-- has_permission_v1('page:yoresel-mutfak') cast hatasi verip false donuyordu
-- (sayfa herkese kapali kaliyordu); bu izni iceren bir rol olusturma/
-- guncelleme cagrisi ise Postgres cast hatasiyla opak 500 veriyordu.
ALTER TYPE public.admin_permission_key ADD VALUE IF NOT EXISTS 'page:yoresel-mutfak';
