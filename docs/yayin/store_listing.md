# Yeedoy — App Store / Google Play Mağaza Listeleme Kılavuzu

> **Durum:** ✅ Teknik altyapı tamamlandı — Store assets hazırlanıyor — Release readiness bkz. docs/yayin/mobile-release-readiness.md
>
> - ✅ Privacy Policy sayfası: https://yeedoy.com/gizlilik — Hukuki nihai onay önerilir
> - ✅ Android Keystore + CI workflow: ANDROID_KEYSTORE_BASE64 secret eklendi (2026-06-05) — kalan 3 secret terminal'de set edilecek
> - ✅ Data Safety + IARC taslağı: docs/yayin/store-data-safety-iarc.md — Play Console'da manuel doldurulacak
> - ⏳ **Store Assets:** App icon 1024×1024, 8 screenshot, release notes — docs/yayin/mobile-release-readiness.md (§16)
>
> **Amaç:** ASO (App Store Optimization) için TR/EN başlık, açıklama ve anahtar kelime seti.  
> **Son Güncelleme:** 2026-04-22

---

## App Store (iOS) — Türkçe

### Başlık (30 karakter maks.)
```
Yeedoy: Fiyat Takip & Menü
```

### Alt Başlık (30 karakter maks.)
```
Menü fiyatlarını topluluğun onaylar
```

### Kısa Açıklama (170 karakter maks.)
```
Yakınındaki restoran fiyatlarını keşfet, geçmiş fiyatları karşılaştır ve fiyat değişiminde anında bildirim al. Menü fiyatlarını sen onaylıyorsun!
```

### Uzun Açıklama (4000 karakter maks.)
```
Yeedoy, Türkiye'nin ilk topluluk destekli restoran fiyat takip uygulamasıdır.

🔍 FİYAT ŞEFFAFLIĞI
• Restoran ve kafe fiyatlarını gerçek zamanlı takip et
• Fiyat geçmişini grafikle gör — "Bu kebap 3 ay önce kaç liraydı?"
• Şehir ortalamasıyla karşılaştır
• Favori menü öğelerinde fiyat değişince anında bildirim al

⭐ GÜVENILIR YORUMLAR
• Lezzet, servis, fiyat/performans, temizlik ve atmosferi ayrı ayrı puanla
• Yorum fotoğrafı ekle — gerçek yemek deneyimini paylaş
• İşletme sahibi yanıtlarını oku

🗺️ KEŞİF & KİŞİSELLEŞTİRME
• Harita veya liste görünümüyle yakınındaki işletmeleri bul
• Bütçe Kombou: kaç kişisin, bütçen nedir → en uygun seçenekler
• "Bana göre fiyat" filtresiyle kişi başı harcamayı kontrol et
• Çevrimdışı menü — masada internet yokken de kullanabilirsin

📊 TOPLULUK GÜCÜ
• Fiyat doğrulaması: "X kişi onayladı" rozeti ile veriye güven
• "Sıkça bahsedilen" etiketler — yorumlardan çıkan öne çıkan özellikler
• Check-in yaparak topluluğa katkıda bulun
• "Şu an X kişi bakıyor" ile popüler işletmeleri keşfet

📱 ANA EKRAN WİDGET'I
• Yakınındaki işletme bilgilerini ana ekranda anlık gör

Yeedoy ile yemek seçimi artık şeffaf, güvenilir ve eğlenceli!
```

### Anahtar Kelimeler (100 karakter, virgülle ayrılmış)
```
restoran,fiyat,menü,yemek,fiyat takip,lokanta,kafe,yorum,keşif,bütçe,fiyat karşılaştırma,qr menü
```

---

## App Store (iOS) — İngilizce

### Başlık
```
Yeedoy: Menu Price Tracker
```

### Alt Başlık
```
Community-verified restaurant prices
```

### Kısa Açıklama
```
Discover nearby restaurant prices, track price history, and get notified when prices change. Community-powered price verification.
```

### Uzun Açıklama
```
Yeedoy is Turkey's first community-driven restaurant price tracking app.

🔍 PRICE TRANSPARENCY
• Track restaurant and café prices in real time
• View price history charts — see how prices have changed
• Compare against city averages
• Get notified instantly when tracked menu item prices change

⭐ TRUSTED REVIEWS
• Rate taste, service speed, price/quality, cleanliness and atmosphere separately
• Add review photos — share your real dining experience
• Read owner responses to reviews

🗺️ DISCOVERY & PERSONALIZATION
• Find nearby businesses in map or list view
• Budget Combo: enter party size and budget → best matching options
• "Price for me" filter to control per-person spending
• Offline menu — browse even without internet at the table

📊 COMMUNITY POWER
• Price verification: "X people confirmed" badge for trustworthy data
• Frequently mentioned tags — highlights extracted from reviews
• Check-in to contribute to the community
• "X people viewing now" to discover popular spots

📱 HOME SCREEN WIDGET
• See nearby business info at a glance on your home screen

With Yeedoy, dining decisions are transparent, trustworthy, and fun!
```

### Anahtar Kelimeler
```
restaurant,menu,price,food,price tracker,café,review,discover,budget,price comparison,qr menu,dining
```

---

## Google Play — Türkçe

### Başlık (50 karakter maks.)
```
Yeedoy: Restoran Fiyat Takip & Menü
```

### Kısa Açıklama (80 karakter maks.)
```
Restoran fiyatlarını takip et. Toplulukla doğrula. Bütçene uygun yeri bul.
```

### Tam Açıklama
*(Yukarıdaki iOS Türkçe uzun açıklama kullanılabilir — 4000 karakter limiti aynı)*

---

## Ekran Görüntüsü Kontrol Listesi

Her platform için aşağıdaki akışlardan alınacak:

| # | Ekran | Akış |
|---|-------|------|
| 1 | Onboarding — "Şehrin fiyatlarını sen belirliyorsun" | Onboarding slide 1 |
| 2 | Keşif — harita + yakındaki işletmeler | Discovery Map |
| 3 | İşletme detayı — fiyat geçmişi grafiği + "X kişi onayladı" | Business Detail |
| 4 | Menü öğesi — fiyat geçmişi çizgi grafiği | Menu Item Detail |
| 5 | Yorum yazma — 5 kriter + fotoğraf ekleme | Review Create |
| 6 | Bütçe Kombou sonuçları | Budget Combo Results |
| 7 | Ana ekran widget'ı | Home Screen Widget |
| 8 | İşletme sahibi yanıtı — "İşletme Yanıtı" bölümü | Business Reviews |

**Ekran boyutu gereksinimleri:**
- iOS: 6.7" (1290×2796 px) + 6.5" + iPad Pro
- Android: 16:9 + 9:16 phone

---

## Uygulama İkonu

- Mevcut: Yeedoy logosu (kırmızı #7F1D1D arka plan)
- Kontrol et: iOS rounded corners preview + Android adaptive icon
