# Yeedoy Docs

Bu klasor sadece karar, kontrat, operasyon ve release icin gerekli dokumanlari tutar.

## Temel

| Dosya | Amac |
|---|---|
| `docs/mimari-kurallari.md` | Aktif mimari sinirlar ve repo kurallari |
| `docs/veri-modeli.md` | Supabase veri modeli ozeti |
| `docs/rol-yetki-matrisi.md` | Rol ve yetki matrisi |
| `docs/veri-guvenligi.md` | Veri guvenligi ve saklama notlari |
| `docs/ceviri-kurallari.md` | L10n kurallari |

## Operasyon

| Dosya | Amac |
|---|---|
| `docs/dagitim.md` | Deploy notlari |
| `docs/operasyon-kilavuzu.md` | Operasyon runbook'u |
| `docs/yol-haritasi.md` | Kalan acik isler |
| `docs/mobil-release-kontrol-listesi.md` | Mobil release kontrol listesi |
| `docs/mobil-ci-ios-hazirlik.md` | iOS/Android CI release hazirligi |

## Teknik Kontratlar

| Dosya | Amac |
|---|---|
| `docs/mobil-supabase-kontratlari.md` | Mobil Supabase/RPC kontratlari |
| `docs/mobil-kesif-telemetri-kontrati.md` | Mobil discovery telemetry kontrati |
| `docs/mobil-yerel-db-offline-plani.md` | Offline/local DB plani |
| `docs/mobil-test-stratejisi.md` | Mobil test stratejisi |
| `docs/karekod-sistemi.md` | Karekod/public menu link kontrati |
| `docs/ai-menu-analiz-plani.md` | AI menu analiz plani |

## Kararlar

ADR dosyalari `docs/adr/` altinda tutulur.

## Temizleme (2026-06-01)

44 obsolete/duplicate dosya silindi:
- English-Turkish duplikasyon konsolidasyonu (22 dosya): Türkçe versiyonlar tutuldu
- Tamamlanmış proje durum raporları (6 dosya): yol-haritasi.md ve eksik.md'de tutulur
- Eski mimarı referansları (6 dosya): mimari-kurallari.md'de güncellenmiş
- Tarihsel geçiş planları (5 dosya): mobilnext.md'de aktif takip

Detaylar: `docs/CLEANUP_SUMMARY_2026-06-01.md`
