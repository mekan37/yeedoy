# Yol Haritasi (Onceliklendirilmis)

Bu liste koddan gorulen aktif aciklara dayanir.

## Tamamlananlar

Tamamlanan turlerin ayrintili tarihsel kaydi bu dosyada tutulmaz. Release ve kapanis snapshot'lari icin:

- `docs/release_index.md`

Bu dosya yalnizca acik ve siradaki islere odaklanir.

## P1 (Kisa Vade)

1. Panel login -> Next login geri donus UX'ini tek adima indir
2. QR yetki hatalarinda daha acik owner/admin mesajlari ekle
3. Gercek production business verileriyle smoke testi release checklist'ine gore per-release uygula

## P2 (Orta Vade)

1. Canonical slug smoke ve legacy UUID redirect health-check'ini release pipeline'a zorunlu hale getir
2. Analytics eventlerini panelde okunabilir hale getiren hafif raporlama ekrani olustur
3. Public menu icin cache invalidation stratejisini deployment pipeline ile standardize et

## Guncel Aciklar

1. Panel login'den Next QR sayfasina donus hala handoff aksiyonu ile oluyor; tek adimli otomatik geri donus UX'i yok.
2. `NEXT_PUBLIC_PANEL_URL` yanlis set edilirse login geri donus CTA'si hatali domaine bakabilir.
3. Web Next e2e kapsami temel ve live smoke seviyesinde; daha genis edge-case senaryolari eksik.
4. Panel integration testi aktif ama minimal; gercek owner/admin smoke senaryolariyla genisletilmeli.

## Son Notlar

- `apps/web_next` public menu `?theme=minimal|bold|elegant` destekler.
- `/q/[code]` edge route handler olarak calisir ve redirect hazirlama suresini loglar.
- Semantik public route `/m/[publicSlugOrId]` olup canonical hedef `public_slug` tercih eder; mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` seklindedir.
- Public menu item kartlari, sticky category bar ve detail sheet motion/refinement turu tamamlanmistir.

## Referans

- mevcut durum ve kod kaniti: `docs/vision_status.md`
- tarihsel release kayitlari: `docs/release_index.md`
