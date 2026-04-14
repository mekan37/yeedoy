# Mimari Denetim

**Tarih:** 2026-03-11
**Kapsam:** `apps/`, `packages/`, `supabase/`

## Yonetici Ozeti

Yeedoy mimarisi bugunku olcekte saglam ve uretime cikabilir durumdadir. Uc uygulamali ayrim mantiklidir; temel riskler daha cok panel tarafindaki kismi tasarim sistemi gecis borcu ve eski RBAC gating izlerinden gelir.

Not: Onceki bir taslakta observability sayfasi gereksiz yere zayif gosterilmisti. Kod taramasi bunun yanlis oldugunu gosteriyor; admin observability ekrani kapsamli bir operasyon panelidir.

**Genel not:** B+ seviyesinde saglam temel, hedefli iyilestirme ihtiyaci var.

## Guclu Yonler

### Sistem tasarimi

- Uygulama sinirlari net: kesif, operasyon ve public dagitim karismiyor.
- Tek Supabase backend kullanildigi icin veri kopyalama karmasasi yok.
- RPC-first write deseni guvenlik tarafini guclendiriyor.
- Mobil idempotency deseni tekrar denemelerde duplicate write riskini dusuruyor.
- Public menu tablolarindaki read politikasi web render akisina uygun.
- Canonical slug modeli SEO ve link istikrarini guclendiriyor.
- Panelden Next.js'e session handoff deseni ayrik uygulamalar arasinda kontrollu gecis sagliyor.

### Panel mimarisi

- Ortak panel bilesen sistemi olgun.
- `AppTokens` tabanli merkezi tasarim kararlari mevcut.
- Kritik agir ekranlarda deferred loading kullaniliyor.
- Liste ekranlarinda TTL cache ve prefix invalidation deseni var.
- `AdminVirtualTableCard` sanallastirilmis tablo deseni icin temel atilmis durumda.

### Dokumantasyon

- Aktif belgeler ana konu alanlarina gore ayrisilmis.
- Source-of-truth mantigi genel olarak korunmus.
- Tarihsel kayitlar aktif belgelerden ayrilabiliyor.

## Riskler ve Zayifliklar

### Yuksek oncelik

| Risk | Detay | Oneri |
|---|---|---|
| Kismi panel tasarim sistemi gecisi | Ana admin yuzeyleri `PanelPageHeader` standardina tasindi; acik borc artik daha sinirli ve ikincil ekranlarda toplaniyor. | Kalan ikincil ekranlari `ADMIN_OWNER_GAP_ANALYSIS.md` uzerinden tek tek kapat. |
| Eski RBAC gating izleri | Ana akislarda yeni permission modeli kullaniliyor; kalan eski referanslar yeni is gelistirirken kafa karistirabilir. | Yeni owner/admin RPC'lerinde yalnizca explicit permission adlari kullan. |

### Orta oncelik

| Risk | Detay | Oneri |
|---|---|---|
| Sanallastirilmis admin tablo kapsami dar | `businesses`, `business-submissions`, `reports` ve `claims` icinde etkili; ana acik artik `queue` tarafinda. | `AdminVirtualTableCard` desenini kalan buyuk listelere yay. |
| Pagination standardi tam degil | `total_count` yaklasimi her admin liste ekraninda standart degil. | Tek pagination kontrati belirleyip tum admin tablolarina uygula. |
| Handoff kurgusu ortam degiskenine hassas | Yanlis `NEXT_PUBLIC_PANEL_URL` konfigi QR login geri donusunu bozabilir. | Release smoke icine handoff round-trip kontrolu ekle. |
| e2e kapsami tam kapanmamis | Temel smoke var ama edge-case coverage sinirli. | Auth, redirect ve handoff vakalarini genislet. |

### Dusuk oncelik

| Risk | Detay | Oneri |
|---|---|---|
| `packages/ui_tokens` algi borcu | Web artik bu paketi birincil kaynak gibi kullanmiyor. | Paket amacini netlestir veya arsivlemeyi dusun. |
| Analytics metadata kalitesi | Event metadata her zaman ayni zenginlikte olmayabilir. | Write aninda zorunlu metadata setini sertlestir. |
| Saatlik analytics eksigi | Owner analytics gunluk seviyede kaliyor. | Saatlik agregasyon secenegi ekle. |

## Modul Sinir Degerlendirmesi

| Modul | Durum | Not |
|---|---|---|
| `mobile_flutter` | Temiz | Panel ve web ile coupling dusuk |
| `panel_flutter_web` admin | Guclu | Ortak panel desenleri yaygin |
| `panel_flutter_web` owner | Guclu | Shell mutlu yollari standarda yakin |
| `web_next` public | Temiz | Public render ve QR ekseninde net |

## Onerilen Sirali Aksiyonlar

1. Kalan admin listelerinde pagination ve virtual table standardini birlestir.
2. Handoff ve auth edge-case smoke kapsamini release kapisina bagla.
3. Saatlik analytics ve metadata kalitesini veri kontrati seviyesinde guclendir.
4. Ikincil admin ekranlarindaki son dusuk etkili tasarim sistemi borcunu kapat.
