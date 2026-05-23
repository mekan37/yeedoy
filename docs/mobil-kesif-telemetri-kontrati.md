# Mobil Kesif Telemetry Kontrati

Tarih: 2026-03-05  
Kapsam: `uygulamalar/mobil` discovery/arama/perf telemetry olaylari

Bu belge discovery odakli telemetry/dashboard sozlesmesi icin tek kaynaktir.

## 1) Kaynaklar

- Telemetry API: `uygulamalar/mobil/lib/core/monitoring/app_telemetry.dart`
- Event anahtarlar: `uygulamalar/mobil/lib/core/analytics/app_events.dart`
- SLO hedefleri: `uygulamalar/mobil/lib/core/perf/perf_slo.dart`
- Discovery search akisi: `uygulamalar/mobil/lib/features/kesify/data/arama_deposu.dart`
- Discovery home TTI akisi: `uygulamalar/mobil/lib/features/kesify/domain/kesify_search_notifier.dart`

## 2) Event Sozlesmesi

| Event | Source | Temel meta alanlari | Not |
|---|---|---|---|
| `perf_rpc` | RPC operation adi | `operation`, `elapsed_ms`, `ok`, `request_id` | `traceRpc()` tarafindan yazilir |
| `perf_home_tti` | `discover` | `home_tti_ms`, `slo_budget_ms`, `slo_ok` | Home ilk anlamli render performansi |
| `home_tti_ms` | `discover` | `value`, `slo_budget_ms` | Numeric metric event |
| `perf_search` | `discover_search` / `discover_nearby` | `search_ms`, `cache_type`, `slo_budget_ms`, `slo_ok` | hit/miss ayrimi zorunlu |
| `search_latency_ms` | `discover_search` / `discover_nearby` | `value`, `cache_type`, `slo_budget_ms` | Numeric metric event |
| `business_open_ms` | `business_page` vb. | `value`, `business_id` (opsiyonel) | business detail gecis suresi |
| `perf_embed_open` | `embed_viewer` | `embed_open_ms`, `provider`, `fallback_used`, `slo_budget_ms`, `slo_ok` | embed acilis/fallback performans olcumu |
| `embed_open_ms` | `embed_viewer` | `value`, `provider`, `fallback_used`, `slo_budget_ms` | Numeric metric event |
| `perf_frames` | `app` | `sampled_frames`, `janky_frames`, `severe_frames`, `jank_rate`, `slo_ok` | frame jank penceresi |
| `frame_jank_rate` | `app` | `value`, `sampled_frames`, `severe_frames` | Numeric metric event |
| `observability_alert` | `alerting` | `alert_type`, threshold/current alanlari | alarm event'i |
| `app_error` | hata kaynagi | `taxonomy`, `error`, `stack` | `reportError()` ile |

## 3) SLO Esikleri

`PerfSlo` sabitleri:

- cold start p95: `2000 ms`
- warm start p95: `800 ms`
- home TTI p95: `1200 ms`
- search cache hit p95: `300 ms`
- search cache miss p95: `800 ms`
- embed open p95: `1500 ms`
- max jank rate: `0.01`

## 4) Dashboard Panelleri (Minimum)

1. Discovery Search p95 (hit/miss ayrik)
2. Discovery Search hata orani (`perf_rpc` where `ok=false` for search operations)
3. Home TTI p95 (`home_tti_ms`)
4. Business open p95 (`business_open_ms`)
5. Embed open p95 (`embed_open_ms`)
6. Jank rate trend (`frame_jank_rate`)
7. Alert sayaci (`observability_alert` by `alert_type`)
8. Offline mutation health panel (`offline_mutation_outcome` by `disposition` / `retry_category`, health summary thresholds)

## 5) Segmentasyon Kurali

Tum discovery panellerinde asgari boyutlar:

- `source`
- `cache_type` (search eventleri icin)
- `operation` (rpc panellerinde)
- `slo_ok`

Opsiyonel:

- `city`, `district`, `surface`, `business_id` (event ureten akis destekliyorsa)

## 6) Veri Kalite Kurallari

- Numeric metric eventlerinde `value` zorunlu.
- `perf_search` eventlerinde `cache_type` zorunlu (`hit`/`miss`).
- `perf_rpc` eventlerinde `operation` ve `ok` zorunlu.
- `app_error.stack` 800 karakter ustu truncate edilir (beklenen davranis).

## 7) Alarm Kurallari

Mevcut app-level alarm karar kaynaklari:

- crash-free rate < hedef
- home TTI p95 > hedef
- edge 429 spike

Uretim:

- `observability_alert` eventi (`alert_type` ile)

## 8) Degisiklik Protokolu

Telemetry event adi/alani degisecekse:

1. Bu dosya guncellenir
2. `app_telemetry.dart` + ilgili call-site birlikte guncellenir
3. `docs/arsiv/incelemeler/mobil-denetim-raporu.md` icinde P2 telemetry maddesine not dusulur

