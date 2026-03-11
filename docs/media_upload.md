# Panel Media Upload

Bu dokuman `apps/panel_flutter_web` icindeki medya yukleme adapter katmaninin tek kaynak aciklamasidir.

Bu dokuman yalnizca upload adapter ve backend kontratini aciklar.

Su konular burada tutulmaz:

- moderasyon queue davranisi
- audit gorunurlugu
- owner/admin operasyon ekranlari

Bu konularin tek kaynaklari:

- `docs/moderation_queue.md`
- `docs/audit.md`

## Kapsam

Panel tarafinda medya yukleme katmani `core/media` altinda toplanmistir.

## Eski Kontrat

- Backend endpoint ayni kalir: `/functions/v1/wp-upload`
- Payload ayni kalir:
  - `file`
  - `title`
  - `business_id`
  - `menu_item_id`
  - `critical`

Bu refactor sadece panel ici isimlendirme ve adapter sinirini degistirir.

## Yeni Giris Noktasi

- `MediaUploadClient`
- `MediaUploadRepository`

Feature ve UI katmani artik `wp_upload` yerine bu API'yi kullanmalidir. Eski `features/menus/data/wp_upload.dart` dosyalari yalnizca backward compatibility wrapper'i olarak degerlendirilir ve aktif call site icermemelidir.

## Storage Migration Notu

Gelecekte Supabase Storage dogrudan kullanilacaksa degisim noktasi tek yerdir:

- `core/media/media_upload_client_*`

Bu sayede feature katmaninda import veya payload degisikligi gerekmeden adapter degistirilir.

## Operasyon Siniri

Upload edilen medya daha sonra moderasyon veya audit akislarina konu olabilir; ancak bunlar upload adapter dokumaninin parcasi degildir.

- queue triage ve `media_flag` davranisi: `docs/moderation_queue.md`
- audit gorunurlugu ve kritik aksiyon kaydi: `docs/audit.md`
