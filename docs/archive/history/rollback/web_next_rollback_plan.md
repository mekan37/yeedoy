# web_next Rollback Plani

## Rollback Ne Zaman Gerekir?

Asagidaki durumlardan biri production'da gozlenirse rollback degerlendirilmelidir:

- Panel -> `Dijital Menu & QR` owner akisi acilmiyorsa
- `/qr/:businessId` yetkili kullanicilar icin sistematik hata veriyorsa
- `/m/:publicSlugOrId` public menu sayfalari genis capli hataya dusuyorsa
- `/api/track` hata orani veya `invalid_event` orani kabul edilemez seviyeye cikiyorsa
- upload zinciri logo/background/cover save akislarini bozuyorsa
- deploy sonrasi kritik SEO/perf regresyonu olusuyorsa

## 1. Web Rollback

Ilk tercih uygulama rollback'tir.

Adimlar:

1. Hosting saglayicisinda bir onceki saglikli `apps/web_next` release artifact'ine revert et.
2. Environment degiskenlerinin degismedigini teyit et.
3. Revert sonrasi asagidaki yuzeyleri hizli smoke et:
   - `/m/:publicSlugOrId`
   - `/qr/:businessId`
   - `/login?redirect=...`
   - `/q/:shortCode`

Beklenen sonuc:

- Public menu yeniden acilmis olmali.
- Owner QR Studio onceki stabil surume donmus olmali.
- Panel butonlari ayni production host'a gitmeye devam etmeli.

## 2. DB Rollback Stratejisi

### Function Patch Rollback

`20260325000002_fix_recompute_user_achievements_enum_cast.sql` rollback'i gerekiyorsa:

1. Deploy oncesi alinmis fonksiyon DDL yedeklerini kullan.
2. Su fonksiyonlari eski haline restore et:
   - `public.recompute_user_achievements_v1(uuid)`
   - `public.get_user_reputation_score_v2(uuid)`

DDL yedek alma komutlari:

```sql
select pg_get_functiondef('public.recompute_user_achievements_v1(uuid)'::regprocedure);
select pg_get_functiondef('public.get_user_reputation_score_v2(uuid)'::regprocedure);
```

Not:

- Bu rollback, analytics zincirini tekrar eski davranisa dondurebilir; yalnizca fonksiyon patch'i kaynakli bir sorun kanitlanirsa uygulanmali.

### Presentation Settings Tablosu

`20260302000001_business_menu_presentation_settings.sql` ile gelen tablo genellikle yerinde birakilmalidir.

Sebep:

- Tablo owner branding verisini tutar.
- App rollback durumunda tabloyu silmek veri kaybi riski dogurur.
- Eski app surumu tabloyu kullanmasa bile tablo varligi tek basina risk yaratmaz.

Bu nedenle varsayilan strateji:

- tabloyu koru
- once app rollback yap
- veritabani rollback'i yalnizca zorunluysa ayri karar olarak ele al

## 3. Minimum Restore Checklist

- [ ] Son saglikli web release'e donuldu
- [ ] `/m/:publicSlugOrId` public menu aciliyor
- [ ] `/qr/:businessId` owner akisi aciliyor
- [ ] Panel `Dijital Menu & QR` butonu dogru host'a gidiyor
- [ ] `/api/track` hata orani normale dondu
- [ ] Upload veya save zincirinde kritik hata kalmadi
- [ ] `docs/web_next_perf.md` veya deploy izleme panellerinde yeni kritik alarm yok

## 4. Rollback Sonrasi Izleme

Rollback sonrasi en az su metrikler izlenmeli:

- `/api/track` hata orani
- `401` / `403` dagilimi
- storage upload fail orani
- `qr_scanned` hacmi
- public menu `5xx` oranlari

Rollback tamam sayilmasi icin:

- owner QR Studio akisi tekrar calisir olmali
- public menu ana yuzeyi stabil olmali
- analytics zinciri sessiz hata uretmemeli
