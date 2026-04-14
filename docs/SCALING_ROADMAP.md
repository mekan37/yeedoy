# Olceklenme Yol Haritasi

**Tarih:** 2026-03-11
**Kapsam:** Mobil, panel, web, veritabani ve operasyon altyapisi

## Baslangic Noktasi

| Katman | Bugunku Durum |
|---|---|
| Veritabani | Supabase, 178+ migration |
| Admin ve owner listeleri | Karisik; bazi yerlerde server pagination, bazi yerlerde istemci yuklemesi |
| Panel render | Owner listelerinde iyi, admin sanallastirma kismi |
| Bundle dagitimi | Deferred route loading mevcut |
| Web public render | SSR agirlikli, kalici CDN stratejisi net degil |
| Analytics | Gunluk agregasyon agirlikli |
| Rate limit | Kritik public ve auth akislarinda mevcut |

Bugunku mimari yaklasik 10k business seviyesine kadar mantikli bir taban sunuyor. 100k+ olcek ve daha agir operasyon yukleri icin ek adimlar gerekiyor.

## Faz 1: Stabilite

Bu faz, olcek buyumeden once kapanmasi gereken temel bosluklara odaklanir.

### 1. Server-side pagination standardi

- `/admin/queue`, `/admin/claims`, `/admin/reports`, `/admin/businesses` gibi ekranlarda ortak sayfalama kontrati tamamlanmali.
- `total_count` donduren RPC modeli standart hale gelmeli.
- Buyuk admin tablolarinda istemcide tum veri cekme deseni kaldirilmali.

### 2. Observability tabani

- Var olan telemetry ve analytics verisi operasyonel dashboard'da standart okunabilir hale getirilmeli.
- Queue throughput, RPC hata orani, moderation SLA ve offline mutation outcome sinyalleri tek yerde gorunmeli.

### 3. RBAC gecisinin sertlestirilmesi

- Kalan eski owner/admin gating izleri temizlenmeli.
- Yeni write akislarinda yalnizca explicit permission temelli RPC modeli kabul edilmeli.

### 4. e2e ve smoke kapsami

- Handoff, slug fallback, auth guard ve QR redirect akislari release kapisina baglanmali.
- `NEXT_PUBLIC_PANEL_URL` gibi kritik ortam degiskenleri icin smoke korumasi eklenmeli.

## Faz 2: Buyume

Bu faz 10x ila 100x buyume sirasinda performans ve operasyon kalitesini korumayi hedefler.

### 1. Analytics granulerligi

- Gunluk metriklerin yanina saatlik kirilim eklenmeli.
- `peak_hour` ve benzeri owner karar sinyalleri uretilmeli.
- Event metadata zorunluluklari zenginlestirilmeli.

### 2. Public menu cache stratejisi

- Route tipine gore cache-control politikasi netlesmeli.
- Menu veya business write sonrasinda invalidation modeli tanimlanmali.
- Bu strateji `deploy.md` ile uyumlu hale getirilmeli.

### 3. Admin tablo sanallastirma

- `AdminVirtualTableCard` deseni tum buyuk admin listelerine yayilmali.
- Yuksek satir sayisinda mock testlerle dogrulanmali.

### 4. Mobil write durability

- Offline write sonucunun panel observability tarafinda izlenmesi guclendirilmeli.
- Retry exhaustion ve dead-letter benzeri politikalar acik tanimlanmali.

## Faz 3: Buyuk Olcek

Bu faz daha agresif isletme sayisi, daha agir trafik ve daha yuksek operasyon hacmi icin dusunulur.

### Oncelikler

- Public read katmaninda daha guclu cache ve dagitim stratejisi
- Moderasyon operasyonlarinda daha otomatik karar destek katmani
- Analytics ve export urunlerinde daha zengin veri urunu yuzeyleri
- Release, smoke ve rollout disiplininin daha merkezi hale gelmesi

## Bugun Icin En Anlamli Siralama

1. Admin pagination ve virtual table standardi
2. Handoff ve auth smoke coverage
3. Saatlik analytics ve richer metadata
4. Public menu cache invalidation stratejisi

Bu belge buyume planidir. Mevcut durum kaniti icin `vision_status.md`, detayli acik isler icin `roadmap.md` okunmalidir.
