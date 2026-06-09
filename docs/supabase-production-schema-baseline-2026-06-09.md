# Supabase Production Schema Baseline - 2026-06-09

## Ozet
- Production schema read-only incelendi mi: Evet. Supabase MCP uzerinden yalnizca `SELECT` / catalog introspection sorgulari calistirildi.
- Mutation calistirildi mi: Hayir.
- Migration repair/db push calistirildi mi: Hayir. `supabase db push`, `supabase db push --dry-run`, `supabase migration repair`, `supabase migration up`, `apply_migration` veya production SQL mutation calistirilmadi.
- Production schema source-of-truth kabul edilmeli mi: Evet, kisa vadede fiili source-of-truth production schema olmali. Remote/local migration history drift nedeniyle local migration klasoru tek basina guvenilir degil.
- PR #95/#96 icin guvenli yol: Normal `supabase db push` yerine, production baseline ve yazili manual apply/runbook ile yalnizca alias migration setinin kontrollu uygulanmasi degerlendirilmeli.
- PR #94 icin durum: Beklemeli. PR #95/#96 production apply ve alias smoke test tamamlanmadan location normalization uygulanmamali.

## Read-only Kontroller
| Kontrol | Sonuc | Not |
|---|---|---|
| Supabase project discovery | Basarili | Production proje: `yeedoy-production` (`dktdnbeougrmhkzplbap`). |
| `information_schema.tables` | Basarili | `public` schema altinda 165 tablo/view benzeri obje listelendi. |
| `information_schema.routines` | Basarili | `public` schema altinda 1308 routine listelendi; PostGIS fonksiyonlari dahil. |
| `pg_policies` | Basarili | `public` schema altinda 331 policy sayildi. |
| `pg_indexes` | Basarili | `public` schema altinda 450 index sayildi. |
| PR #95/#96 hedef obje kontrolleri | Basarili | Alias tablo/helper production'da yok; mevcut search RPC imzalari var. |
| PR #94 hedef obje kontrolleri | Basarili | `businesses` var; review/reference tablolar production'da yok. |
| `supabase db dump --schema public` | Basarisiz, read-only deneme | Docker Desktop mevcut olmadigi icin 0 byte dump uretildi. Mutation yapilmadi. |

## Production Objeleri
### Tablolar
| Obje | Var mi | Not |
|---|---|---|
| `public.businesses` | Evet | Ana isletme tablosu production'da var. |
| `public.city_search_aliases` | Hayir | PR #95 alias tablosu production'a uygulanmamis gorunuyor. |
| `public.business_location_review_queue` | Hayir | PR #94 review queue tablosu production'da yok. |
| `public.turkey_districts` | Hayir | PR #94 on kontrolunde beklenen referans tablo production'da yok. |
| `public.turkey_districts_reference` | Hayir | Alternatif/olasi referans tablo adi da production'da yok. |
| `public.businesses_with_stats` / `public.businesses_with_stats_mv` | Evet | Production schema'da isletme istatistik gorunumleri/materialized view mevcut. |
| `public.osm_admin_boundaries` | Evet | Location/boundary iliskili mevcut production objesi. |

### Fonksiyonlar / RPC
| Obje | Var mi | Signature | Not |
|---|---|---|---|
| `public.normalize_tr_location_text` | Hayir | `normalize_tr_location_text(text)` yok | PR #95/#96 helper production'da yok. |
| `public.search_businesses_v1` | Evet | `search_businesses_v1(text,text,text,integer,integer)` | Kisa imza mevcut. |
| `public.search_businesses_v1` | Evet | `search_businesses_v1(text,text,text,double precision,double precision,double precision,integer,integer)` | Konum parametreli imza mevcut. |
| `public.search_nearby_businesses_v3` | Evet | `search_nearby_businesses_v3(double precision,double precision,double precision,integer,integer,text,text,text)` | Mevcut v3 imzalarindan biri. |
| `public.search_nearby_businesses_v3` | Evet | `search_nearby_businesses_v3(double precision,double precision,integer,text,text,boolean,integer)` | Mevcut v3 imzalarindan biri. |

### Policy / RLS
| Obje | Var mi | Not |
|---|---|---|
| `public.businesses` policies | Evet | `businesses_read`, admin write/delete ve owner/admin write policy'leri gorundu. |
| `public.city_search_aliases` policies | Hayir | Tablo olmadigi icin PR #95 policy'leri de production'da yok. |
| `public.business_location_review_queue` policies | Hayir | Tablo olmadigi icin PR #94 policy'leri production'da yok. |
| `public.turkey_districts` / `public.turkey_districts_reference` policies | Hayir | Bu tablolar production'da yok. |

### Indexler
| Obje | Var mi | Not |
|---|---|---|
| `businesses_pkey` | Evet | Ana primary key index mevcut. |
| `businesses_city_idx` | Evet | City bazli arama icin mevcut index. |
| `businesses_city_district_idx` | Evet | City/district bazli mevcut index. |
| `businesses_city_district_norm_idx` | Evet | Normalize location alanlari production schema'da mevcut gorunuyor. |
| `idx_businesses_city_district_name` | Evet | Location/name aramasi icin mevcut index. |
| `idx_businesses_geog` / `idx_businesses_geog_gist` | Evet | Geospatial arama indexleri mevcut. |
| `businesses_public_slug_unique_idx` | Evet | Local-only migration etkilerinden bazilarinin production schema'da zaten olabilecegine isaret ediyor. |
| `city_search_aliases` indexleri | Hayir | PR #95 tablo production'da olmadigi icin index yok. |

## PR #95/#96 On Kontrol
| Obje | Production'da var mi | Beklenen | Karar |
|---|---|---|---|
| `public.city_search_aliases` | Hayir | PR #95 ile olusmali, 9 seed row icermeli | Alias seti production'da uygulanmamis. |
| `public.normalize_tr_location_text(text)` | Hayir | PR #95 ile eklenip PR #96 ile combining mark fix almali | Helper production'da yok; PR #95/#96 birlikte ele alinmali. |
| `public.search_businesses_v1(...)` | Evet | PR #95 sonrasi alias lookup desteklemeli | Mevcut RPC var ama alias entegrasyonu production'da dogrulanmadi; helper/tablo yok oldugu icin PR #95 uygulanmamis kabul edilmeli. |
| `public.search_nearby_businesses_v3(...)` | Evet | PR #95 sonrasi alias lookup desteklemeli | Mevcut RPC var ama alias entegrasyonu production'da dogrulanmadi; helper/tablo yok oldugu icin PR #95 uygulanmamis kabul edilmeli. |
| Alias smoke testleri | Yapilmadi | Apply sonrasi calismali | Tablo/helper yokken smoke test calistirmak anlamli degil. |

## PR #94 On Kontrol
| Obje | Production'da var mi | Beklenen | Karar |
|---|---|---|---|
| `public.businesses` | Evet | Zorunlu ana tablo | On kosul mevcut. |
| `businesses.id` | Evet | `uuid`, not null | On kosul mevcut. |
| `businesses.city` | Evet | `text`, nullable | On kosul mevcut; veri normalizasyonu henuz bu raporda uygulanmadi. |
| `businesses.district` | Evet | `text`, nullable | On kosul mevcut; veri normalizasyonu henuz bu raporda uygulanmadi. |
| `public.business_location_review_queue` | Hayir | PR #94 ile olusmali | PR #94 production'a uygulanmamis. |
| `public.turkey_districts` | Hayir | PR #94 referans tablosu olarak bekleniyor | PR #94 production'a uygulanmamis. |
| `public.turkey_districts_reference` | Hayir | Dosya adina gore olasi referans tablo adi | Production'da yok. |

## Drift Reconciliation Degerlendirmesi
- 31 remote-only migration etkisi bilinmiyor: Evet. Bu version'lar remote history'de applied gorunuyor ancak local repo ve git disi recovery kaynaklarinda gercek SQL bulunamadi.
- 44 local-only migration production'da schema olarak var mi: Tamamiyla dogrulanmadi. Ancak `businesses_public_slug_unique_idx`, `businesses_city_district_norm_idx`, `city_norm`, `district_norm`, `geog`, `public_slug`, `search_tsv` kolonlari ve mevcut `search_nearby_businesses_v3` imzalari bazi local-only degisikliklerin production schema'da zaten bulunabilecegini gosteriyor.
- Local migration history guvenilir mi: Tek basina hayir. 31 remote-only ve 44 local-only fark varken normal migration history okumasiyla production apply karari verilmemeli.
- Production schema baseline gerekli mi: Evet. Read-only baseline/dump ve schema fark raporu, hangi local-only migration'larin production'da fiilen mevcut oldugunu ayirmak icin gerekli.

## Onerilen Yol
1. Production schema icin read-only, tam ve versiyonlanmis baseline alin: tablo, kolon, constraint, index, policy, function signature ve extension envanteri.
2. 44 local-only migration'i production schema baseline'a karsi siniflandir: schema'da mevcut, schema'da eksik, yalniz veri/seed etkili, belirsiz.
3. PR #95/#96 icin normal `supabase db push` yerine review edilmis manual apply/runbook hazirla; history temsilinin nasil tutulacagini ayrica onaylat.
4. PR #95/#96 apply sonrasi alias smoke testleri gecmeden PR #94'u merge/apply etme.
5. PR #94 icin apply oncesi backup, review queue beklentisi, etkilenecek business sayisi ve rollback/compensation planini yazili hale getir.

## Kesinlikle Yapilmamasi Gerekenler
- `supabase migration repair` kor veya deneme amacli calistirilmamali.
- `supabase db push` normal sekilde calistirilmamali.
- Remote migration history, 31 remote-only version'in schema etkisi netlesmeden degistirilmemeli.
- Marker/no-op migration dosyalari ayri PR ve acik onay olmadan olusturulmamali.
- PR #95/#96 production'a manual apply/runbook ve acik onay olmadan uygulanmamali.
- PR #94 production'a PR #95/#96 apply + alias smoke test tamamlanmadan uygulanmamali.
