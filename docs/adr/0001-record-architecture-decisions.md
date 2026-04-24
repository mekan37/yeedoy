# ADR-0001: Architecture Decision Records Kullanımı

**Durum:** Kabul edildi  
**Tarih:** 2026-04-22  
**Karar verenler:** Geliştirme ekibi

## Bağlam

Yeedoy üç uygulama (mobile Flutter, panel Flutter Web, Next.js) ve bir Supabase backend'den oluşan bir monorepo'dur. Büyük mimari kararlar (örn. state management seçimi, multi-tenant RLS tasarımı, token stratejisi) şu anda kod incelemesi veya commit mesajlarından çıkarılmak zorunda kalınıyor. Bu durum yeni geliştiricilerin geçmiş kararları anlayamamasına yol açıyor.

## Karar

Tüm büyük mimari kararları `docs/adr/` dizini altında, bu şablona uygun ADR dosyaları ile kayıt altına alacağız.

## Şablon Yapısı

```
# ADR-XXXX: Kısa Başlık

**Durum:** Taslak | Kabul edildi | Kullanımdan kaldırıldı | Değiştirildi (ADR-YYYY)
**Tarih:** YYYY-MM-DD
**Karar verenler:** [isimler veya roller]

## Bağlam
[Neden bu karar gerekli? Hangi sorunu çözüyor?]

## Değerlendirilen Alternatifler
[Hangi seçenekler incelendi?]

## Karar
[Ne yapılacağına karar verildi?]

## Gerekçe
[Neden bu alternatif seçildi?]

## Sonuçlar
[Olumlu ve olumsuz etkiler nelerdir?]
```

## Kural

- Her büyük mimari karar için yeni bir dosya açılır.
- Numaralandırma sıralıdır: 0001, 0002, …
- Karar değişirse eski ADR "Değiştirildi (ADR-YYYY)" olarak işaretlenir, silinmez.
- ADR dosyaları geri dönüşü olmayan kararlar içindir; sprint planlaması ADR değildir.

## Sonuçlar

**Olumlu:** Mimari hafıza oluşur; yeni geliştirici onboarding hızlanır.  
**Olumsuz:** Her büyük kararın yazılı gerekçe gerektirmesi ek disiplin ister.
