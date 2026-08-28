# Yeedoy Web Sayfa Bazli Tasarim Yonu

Bu not, mobildeki tekil ekranlardan degil, feature ailelerinden turetilen web tasarim yonunu tarif eder. Web tarafinda ayni yuzeyin Turkce/ingilizce veya legacy route kopyalari varsa tek tasarim sozlesmesi kullanilir.

## Ortak Tasarim Sistemi

- Tipografi: Sora ana font. Public marka anlarinda display font kullanilabilir, panel ve operasyon ekranlarinda yalniz Sora.
- Renk: primary `#7F1D1D`, accent `#DC2626`, bg `#F9FAFB`, card `#FFFFFF`, cardAlt `#FDF8F7`, textStrong `#111827`, text `#434D57`, border `#E5E7EB`.
- Yuzey: mobildeki `AppCard` hissi korunur ama webde kartlar sadece tekrar eden item, tablo satiri, modal/sheet ve kontrol yuzeyleri icin kullanilir.
- Radius: public menu ve food image yuzeylerinde 20-24px; operasyon panelinde 8-16px; icon button ve pilllerde 999px.
- Etkilesim: 44px minimum hedef, 150-220ms gecis, hover renk/border/shadow ile olur. Layout kaydiran scale kullanilmaz.
- Ikon: emoji yok. Mevcut public discovery kodundaki kategori emojileri web tasarim yonunde line icon veya sade text pill ile degistirilmeli.
- Copy: component icine yeni sabit string gomulmez; public copy merkezi i18n dosyalarina gider.

## 1. Ana Sayfa ve Public Kesif

Kapsam:
`/`, `/kesif`, `/kesif/harita`, `/arama`, `/en-iyiler`, `/liderler`, `/top`, `/discover`, `/feed`, `/akis`, `/butce`, `/fiyat-endeksi`, `/karsilastir`, `/compare`, `/zincirler`, `/zincir/[slug]`, `/chain/[slug]`, `/gurmeler`, `/gurmeler/[username]`.

Mobil karsiligi:
`discovery_page`, `discovery_map_page`, `top_businesses_page`, `compare_page`, `chains`, `gourmets`, `smart_feed`.

Tasarim yonu:
Public kesif, tek landing hero degil; arama ve sonuc odakli marketplace yuzeyi olmali. Ustte kisa marka/nav satiri, altinda arama + konum + kategori filtreleri, devaminda sonuc grid/listesi. Desktopta sol ana liste, sagda fiyat sinyalleri/top isletmeler gibi yardimci kolon. Mobil webde yatay pill filtreler ve tek kolon kart listesi.

Sayfa ayrimi:
- Ana sayfa: en genis giris; hero kisa, arama kutusu birincil.
- Kesif/arama: hero kuculur; filtre ve sonuc sayisi one cikar.
- Harita: split layout; sol liste, sag harita. Mobilde harita/list toggle.
- En iyiler/liderler/top: ranked list; badge ve siralama agirlikli.
- Fiyat/butce/karsilastir: tablo + mini grafik + sehir/kategori filtreleri.
- Zincir/gurme/feed: editorial degil, taranabilir liste ve profil/akis yuzeyi.

## 2. Isletme Detay ve Yorumlar

Kapsam:
`/isletme/[slug]`, `/b/[slug]`, `/isletme/[slug]/yorumlar`, `/b/[slug]/reviews`, `/b/[slug]/reviews/new`.

Mobil karsiligi:
`business_page`, `business_detail_sections`, `business_reviews_page`, `review_create_page`.

Tasarim yonu:
Isletme sayfasi mobildeki identity card + compact info + trust bolumlerinin web karsiligi olmali. Ilk viewportta full-width fotograf baslik, logo, dogrulanmis/acik badge, puan ve ana CTA `Menuyu Gor`. Alt kisimda bilgi paneli, saatler, konum, fiyat karsilastirma, fiyat gecmisi, yeni urunler, yorumlar ve sahiplenme cagrisi moduler bloklar halinde akar.

Sayfa ayrimi:
- Detay: fotograf baslik + guven/fiyat/konum modulleri.
- Yorum listesi: yorum filtreleri, puan dagilimi, report action.
- Yorum yaz: form odakli, tek kolon, mobilde sheet hissi, webde merkezlenmis form yuzeyi.

## 3. Public QR Menu ve Urun Detayi

Kapsam:
`/m/[slug]`, `/m/[slug]/c/[categoryId]`, `/m/[slug]/i/[itemId]`, `/q/[code]`, `/kod/[code]`, `/qr/[businessId]`, `/karekod/[businessId]`, `/embed/[businessId]`, `/yerlestir/[businessId]`.

Mobil karsiligi:
`menu_page`, `menu_item_page`, `menu_item_detail_sections`, `public_menu_share_page`.

Tasarim yonu:
Bu yuzey webde en gorsel olani. Restaurant fotograf hero, business identity, acik/dogrulanmis/menu updated badge, QR/share/reservation CTAlari. Hero altinda sticky kategori pillleri, search/filter row, sonra menu item listesi. Desktopta iki kolon veya genis liste; mobilde tek kolon ve altta kategori/arama odakli sticky kontrol.

Urun detayi:
Desktopta sagdan gelen detay paneli veya modal; mobilde bottom sheet. Icerik sirasiyla fotograf, ad, fiyat, aciklama, alerjen/diyet chipleri, fiyat dogrulama/guncelleme sinyali.

Embed:
Cevre chrome minimum; sadece menu listesi, marka bandi ve powered-by satiri.

## 4. Masa Siparisi ve Geri Bildirim

Kapsam:
`/siparis/[slug]`, masa siparisi route handlerlari, `/oyoyla/[token]`, masa geri bildirimleri.

Mobil karsiligi:
Menu item selection, review/report sheets, group vote flows.

Tasarim yonu:
Siparis yuzeyi public menuden daha islemsel. Sticky sepet, adet stepper, item availability, masa numarasi ve durum timeline gerekir. Mobilde bottom cart; desktopta sag sepet paneli. Geri bildirim sayfasi tek is akisi: puan, kisa not, opsiyonel fotograf, gonder.

## 5. Auth, Onboarding ve Hesap

Kapsam:
`/login`, `/giris`, `/forgot-password`, `/sifremi-unuttum`, `/reset-password`, `/sifre-sifirlama`, `/onboarding`, `/baslangic`, profile/security/settings pages.

Mobil karsiligi:
`login_page`, `register_page`, `forgot_password_page`, `onboarding_page`, `profile_page`, `account_security_page`.

Tasarim yonu:
Auth ekranlari sakin ve guven odakli. Split hero yerine merkezlenmis form + kisa marka bloku. Onboarding adimli wizard olarak calisir: profil, konum, tercih, bildirim. Webde stepper sol/ust kisimda; mobilde tek adim ve alt CTA.

Hesap sayfalari:
Profile summary header, sonra ayar satirlari. Security iki faktor, oturumlar ve sifre bloklarini ayri ama ayni sayfa gridinde verir.

## 6. Kullanici Uygulama Yuzeyi

Kapsam:
`/(kimlik)` ve `/(auth)` altindaki favoriler, takip, gelen kutusu, bildirimler, fiyat uyarilari, avantajlar, sadakat, diyet profili, yemek gunlugum, oneriler, katki, makbuz yukle, ortak listeler, grup istekleri, taste twin, smart feed.

Mobil karsiligi:
`favorites_page`, `following_page`, `inbox_page`, `notification_preferences_page`, `price_alerts_page`, `perks_page`, `sadakat_kartlarim_sayfasi`, `diet_profile_page`, `yemek_gunlugu_sayfasi`, `contribute_page`, `receipt_upload_sheet`, `collab_lists`, `group_requests`, `taste_twin_page`, `smart_feed_page`.

Tasarim yonu:
Bu alan app gibi davranir, landing gibi degil. Desktopta compact user nav + ana calisma alani; mobilde bottom nav/section tabs. Kart mozaigi yerine liste, timeline ve form yuzeyleri.

Sayfa ayrimi:
- Favoriler/takip: saved business list, filter chips, empty state.
- Gelen kutusu/bildirim: inbox timeline, unread badge, preference shortcuts.
- Fiyat uyarilari: alert rules list + threshold editor.
- Avantaj/sadakat: pass/card list, progress bar, redemption history.
- Katki/makbuz: upload/dropzone, OCR durumu, dogrulama checklist.
- Ortak liste/grup istegi: collaboration list, vote/status, invite/share.
- Taste twin/smart feed: recommendation cards, preference chips, reason labels.
- Yemek gunlugu/diyet: calendar/list toggle, nutrition/preference filters.

## 7. Owner Operasyon Paneli

Kapsam:
`/sahip/*` ve `/owner/*`: dashboard, businesses, menus, menu editor, translations, QR, analytics, price report, reviews, price suggestions, requests, activity, trash, team, settings, hours, domain, onboarding.

Mobil karsiligi:
Mobilde owner panel yok; tasarim sadece mobile tokenlarindan turetilir.

Tasarim yonu:
Owner panel islemsel ve yogun olmali. Sol sidebar, ust business switcher/search/user menu, ana calisma alani. Dashboard metrikler + yapilacaklar; CRUD sayfalari toolbar + tablo/list + sag inspector; form sayfalari iki kolon: ana form ve sag rehber/status.

Sayfa ayrimi:
- Dashboard: KPI, son aktivite, menu sagligi, QR performansi.
- Isletmeler: business list, status, claim/verification, quick edit.
- Menu listesi/editor: kategori tabs, item table, selected item inspector, bulk actions.
- Ceviriler: dil tabs, eksik ceviri filtresi, satir bazli editor.
- QR Studio: preview canvas, theme controls, download/share actions.
- Analitik/fiyat raporu: tarih filtresi, trend grafik, tablo drilldown.
- Yorumlar/fiyat onerileri/istekler: moderation-style queues.
- Ekip/ayarlar/domain/saatler: form + validation + audit hint.
- Cop kutusu/aktivite: audit timeline ve restore actions.

## 8. Owner Pazarlama, CRM ve Finansal

Kapsam:
`/sahip/pazarlama/*`, `/owner/marketing/*`, `/sahip/crm`, `/sahip/finansal`, `/sahip/siparisler`, `/sahip/envanter`, `/sahip/yapay-zeka-analizi`, `/owner/ai-analysis`, growth pages.

Mobil karsiligi:
Mobilde dogrudan karsilik yok; growth ve campaign aksiyonlari web owner yuzeyinde kalir.

Tasarim yonu:
Operasyon paneliyle ayni shell, ama kampanya kurulumunda wizard ve preview gerektirir. Email/SMS/loyalty/campaign ekranlari sol form, sag canli preview. CRM musteri segmentleri tablo + segment drawer. Finansal sayfalar reconciliation tablosu, export CTA ve status badge odakli.

## 9. Admin Panel

Kapsam:
`/yonetici/*` ve `/admin/*`: dashboard, businesses, users, roles, search, queue, claims, appeals, reports, reviews, receipt submissions, photo moderation, temp uploads, table feedback, sponsorships, analytics, support, suggestions, price suggestions, fraud, feature flags, api keys, observability, audit, dev tools, KVKK/GDPR.

Mobil karsiligi:
Mobilde admin panel yok; tasarim web-only operasyon standardina bagli.

Tasarim yonu:
Admin, ownerdan daha yogun ve daha az markali olmali. Sol sidebar korunur, ust global search merkezi. Renklerde bordo sadece action/selection icin; risk/uyari/status renkleri daha belirgin. Ana desen: queue, table, detail drawer, audit timeline.

Sayfa ayrimi:
- Dashboard/analytics/growth: sistem sagligi, hacim, trend ve anomaly.
- Isletmeler/kullanicilar/roller: data table + advanced filters + detail drawer.
- Kuyruk/itiraz/claim/review/photo/receipt: triage queue; sol liste, orta detay, sag karar paneli.
- Reports/support/suggestions: kanban veya queue + SLA badge.
- Feature flags/api keys/dev tools: teknik ayar tablolari; destructive actionlar ikincil onay ister.
- Observability/audit/incidents: log stream, severity filter, timeline.
- KVKK/GDPR: request list, identity/masking, export/delete workflow.

## 10. Legal, Support ve Statik Bilgi

Kapsam:
`/yardim`, `/destek`, `/gizlilik`, `/yasal`, `/yasal/[slug]`, `/legal`, `/abonelik-iptal`, `/askida`, `/sahiplen/*`, forbidden/suspended pages.

Mobil karsiligi:
`help_support_page`, `faq_page`, `legal_page`, `data_deletion_page`, suspended meal and claim flows.

Tasarim yonu:
Bu sayfalar belge gibi ama marka uyumlu olmali. Dar okuma kolonu, sol icindekiler nav'i desktopta, mobilde sticky select/tabs. Sahiplenme akisinda belge okuma degil, adimli basvuru wizard kullanilir: isletme bul, kanit yukle, inceleme durumu.

## Gorsel Uretim Seti

Her sayfa icin tek tek bitmap uretmek yerine su 12 ekran konsepti tum route ailelerini kapsar:

1. Public kesif / arama sonuc.
2. Harita kesif.
3. Isletme detay.
4. Public QR menu.
5. Urun detay sheet.
6. Kullanici profil/favoriler hub.
7. Katki / makbuz yukleme.
8. Ortak liste / grup istegi.
9. Owner dashboard.
10. Owner menu editor + inspector.
11. Owner QR/marketing preview.
12. Admin moderation queue + detail drawer.

Bu 12 konsept uretildiginde, webdeki her route ailesi icin uygulanabilir genel tasarim gorseli tamamlanmis olur.
