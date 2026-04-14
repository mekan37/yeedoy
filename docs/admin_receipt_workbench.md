# Admin Fis Inceleme Tezgahi

Bu dokuman `/admin/receipt-submissions` ekraninin urun ve operasyon sinirini tanimlar.

Amac:

- receipt/OCR tabanli saha kanitlarini operatore sirali inceleme yuzeyi olarak sunmak
- ayni isletme veya zincirde biriken kayitlari toplu menu kalite sinyali olarak gostermek
- OCR eslesmesi olmayan veya takip gerektiren kayitlari normal akistan ayirmak

## Kapsam

Workbench su katmanlari icerir:

- filtrelenebilir receipt listesi
- summary KPI kartlari
- batch review opportunities
- secili receipt detayi
- OCR eslesme tablosu
- review status ve operator notu

Teknik kaynaklar:

- `apps/panel_flutter_web/lib/features/admin/ui/admin_receipt_submissions_page.dart`
- `apps/panel_flutter_web/lib/features/admin/data/admin_receipt_submissions_repository.dart`
- `apps/panel_flutter_web/lib/features/admin/domain/admin_receipt_submission.dart`
- `supabase/migrations/20260309_000001_receipt_ocr.sql`
- `supabase/migrations/20260325000015_receipt_review_workbench_v1.sql`

## Review Durumlari

### Pending

Anlam:

- kayit henuz operator tarafinda triage edilmedi
- batch veya detail inceleme sirasinda ilk ele alinacak isler bu havuzda kalir

### Reviewed

Anlam:

- operator OCR eslesmesini gordu
- kayit operasyonel olarak tamamlanmis sayildi
- ek saha aksiyonu gerekmedigi dusunuldu

### Needs Follow-up

Anlam:

- OCR eslesmesi zayif, sifir eslesmeli veya supheli
- menu guncelleme, saha tekrar kontrolu ya da zincir bazli toplu inceleme gerektirebilir

## Batch Review Mantigi

Ekran ayni business veya chain icinde biriken receipt'leri ayri kartta gosterir.

Amac:

- operatorun tek tek receipt secmek yerine yogunlasan sorunlu alanlari oncelemesi
- ayni sube veya zincirde tekrar eden menu drift'ini hizli fark etmesi

Kart uzerindeki sinyaller:

- bekleyen kayıt sayisi
- sifir eslesme sayisi
- son receipt zamani

Bu yuzey toplu update araci degildir; fakat hangi business/chain icin toplu menü incelemesi gerekebilecegini gosterir.

## OCR Eslesme Tablosu

Secili receipt detayinda:

- item adi
- OCR ile tespit edilen fiyat
- sistemdeki mevcut fiyat
- iki fiyat arasindaki delta

birlikte gorulur.

Bu tablo operatorun su ayrimi yapmasini kolaylastirir:

- gercek fiyat drift'i
- OCR yanlis okuma ihtimali
- item eslesmesi zayifligi

## Is Kurallari

- yeni receipt kaydi varsayilan olarak `pending` baslar
- `pending -> reviewed` gecisi kaydi kapatir
- `pending -> needs_followup` gecisi saha veya ikinci inceleme sinyali uretir
- `pending` durumuna donus support/ops gerekirse kaydi yeniden aktif triage havuzuna sokar
- sifir eslesmeli receipt otomatik reddedilmez; operator veya batch inceleme sinyali olarak tutulur

## Bugunku Sinir

Calisanlar:

- receipt queue filtrelenebilir
- OCR eslesme detaylari gorulebilir
- operator notu ve review durumu saklanir
- batch opportunity sinyali business/chain bazinda gorunur

Henuz olmayanlar:

- receipt'ten dogrudan toplu menu guncelleme wizard'i
- OCR confidence skoru veya parse quality puani
- otomatik assignment veya SLA katmani

## Operasyon Notu

Bu ekranin amaci receipt'i nihai veri kaynagi ilan etmek degil, saha kanitini menu kalite operasyonuna dogru baglamaktir.
