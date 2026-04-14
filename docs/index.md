# Dokuman Indeksi

Bu dosya `docs/` klasoru icin tek giris noktasidir.

## Temel Kural

- Klasor kokunde yalnizca aktif referans belgeleri durur.
- Tarihsel snapshot, eski audit ve release kayitlari `docs/archive/` altina tasinmistir.
- Yeni belge eklemeden once ayni konunun baska bir source-of-truth'u olup olmadigi burada kontrol edilir.

## Durum Etiketleri

- `Aktif`: Guncel ve bakilmasi gereken ana belge
- `Referans`: Derin teknik ayrinti veya destekleyici belge
- `Arsiv`: Tarihsel kayit, snapshot veya tamamlanmis audit

## En Hizli Yol

| Soru | Belge | Durum |
|---|---|---|
| Sistem su an nerede? | `docs/vision_status.md` | Aktif |
| Siradaki isler ne? | `docs/roadmap.md` | Aktif |
| Uygulama sinirlari ne? | `docs/apps.md` | Aktif |
| Mimari nasil calisiyor? | `docs/architecture.md` | Aktif |
| Ust seviye sistem ozeti ne? | `docs/SYSTEM_OVERVIEW.md` | Aktif |
| Hangi tablo ve RPC var? | `docs/data-model.md` | Aktif |
| Guvenlik, RLS ve migration sagligi ne durumda? | `docs/DATABASE_REVIEW.md` | Aktif |
| Admin ve owner panelde ne eksik? | `docs/ADMIN_OWNER_GAP_ANALYSIS.md` | Aktif |
| Kurulum ve komutlar nerede? | `docs/setup.md` | Aktif |
| Deploy ve env nasil yonetiliyor? | `docs/deploy.md` | Aktif |

## Cekirdek Belgeler

| Belge | Amac | Durum |
|---|---|---|
| `docs/SYSTEM_OVERVIEW.md` | Urun, 3 uygulama siniri, uc uca akislar | Aktif |
| `docs/apps.md` | Uygulama sorumluluk dagilimi | Aktif |
| `docs/product.md` | Urun tanimi ve kullanim degeri | Aktif |
| `docs/architecture.md` | Kod tabanli mimari akis | Aktif |
| `docs/ARCHITECTURE_AUDIT.md` | Mimari risk, guclu yonler, teknik borc | Aktif |
| `docs/data-model.md` | Tablo, RPC ve veri ekseni | Aktif |
| `docs/DATABASE_REVIEW.md` | Supabase guvenlik ve migration saglik ozeti | Aktif |
| `docs/rbac.md` | Yetki modeli ve erisim kurallari | Aktif |
| `docs/vision_status.md` | Guncel durum ozeti | Aktif |
| `docs/roadmap.md` | Acik isler ve oncelik | Aktif |
| `docs/SCALING_ROADMAP.md` | Buyume ve olcek yol haritasi | Aktif |

## Mobil

| Belge | Amac | Durum |
|---|---|---|
| `docs/mobile_architecture.md` | Mobil modul yapisi | Aktif |
| `docs/mobile_features_matrix.md` | Mobilde ne var, ne yok | Aktif |
| `docs/mobile_supabase_contracts.md` | Mobil-Supabase kontratlari | Referans |
| `docs/mobile_release_checklist.md` | Release kontrol listesi | Aktif |
| `docs/mobile_ci_ios_readiness.md` | iOS CI hazirlik durumu | Referans |
| `docs/mobile_test_strategy.md` | Mobil test stratejisi | Referans |
| `docs/mobile_discovery_telemetry_contract.md` | Discovery telemetry kurali | Referans |
| `docs/mobile_local_db_offline_plan.md` | Offline ve lokal DB plani | Referans |
| `docs/system_full_documentation.md` | Genis ve ayrintili sistem referansi | Referans |

## Panel ve Operasyon

| Belge | Amac | Durum |
|---|---|---|
| `docs/ADMIN_OWNER_GAP_ANALYSIS.md` | Admin/owner ekran durum matrisi | Aktif |
| `docs/admin_businesses.md` | Admin business operasyonu | Aktif |
| `docs/admin_business_submissions.md` | Admin basvuru akisleri | Aktif |
| `docs/admin_receipt_workbench.md` | Fis operator yuzeyi | Referans |
| `docs/admin_search.md` | Admin global search | Referans |
| `docs/moderation_queue.md` | Moderasyon kuyrugu | Aktif |
| `docs/audit.md` | Audit yazimi ve gorunurluk | Aktif |
| `docs/analytics_owner.md` | Owner analytics | Aktif |
| `docs/b2b_exports.md` | B2B veri urunleri | Referans |
| `docs/data_safety.md` | Trash, restore, snapshot ve rollback mantigi | Aktif |
| `docs/media_upload.md` | Medya yukleme kontrati | Referans |
| `docs/tools_inventory.md` | Panel script envanteri | Referans |
| `docs/devtools.md` | Platform bazli devtools yuzeyleri | Referans |
| `docs/test_strategy.md` | Panel test kapilari ve smoke stratejisi | Aktif |

## Performans ve Stil

| Belge | Amac | Durum |
|---|---|---|
| `docs/panel_perf.md` | Panel performans snapshot'i | Referans |
| `docs/panel_scale.md` | Panel olcekleme kararlari | Referans |
| `docs/web_next_perf.md` | Web perf snapshot'i | Referans |
| `docs/ui-style.md` | Stil sistemi ve tokenlar | Aktif |
| `docs/module_visibility_matrix.md` | Modul gorunurluk matrisi | Referans |
| `docs/panel_placeholders.md` | Placeholder ve gecici panel alanlari | Referans |

## Operasyon ve Kurulum

| Belge | Amac | Durum |
|---|---|---|
| `docs/setup.md` | Kurulum ve gelistirme baslangici | Aktif |
| `docs/deploy.md` | Deploy, env ve domain sozlesmesi | Aktif |
| `docs/runbook.md` | Smoke, incident ve operasyon adimlari | Aktif |
| `docs/qr-system.md` | QR ve public menu zinciri | Aktif |

## Arsiv

- Tarihsel release, rollback ve temizlik kayitlari: `docs/archive/history/`
- Eski audit ve durum snapshot'lari: `docs/archive/reviews/`
- Arsiv yapisinin aciklamasi: `docs/archive/README.md`

## Bu Turdaki Temizlik

- Cift giris dosyasi olan `DOCS_INDEX.md` arsive alindi.
- Release, rollback, drift, cleanup ve silinmis dosya kayitlari kokten cikarildi.
- Tarih damgali denetim snapshot'lari `docs/archive/reviews/` altina tasindi.
- Kokte kalan ana Ingilizce belgeler Turkcelestirildi.
