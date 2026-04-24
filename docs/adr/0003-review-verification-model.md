# ADR-0003: Yorum Doğrulama Modeli (Verified Visit)

**Durum:** Kabul edildi  
**Tarih:** 2026-04-22  
**Karar verenler:** Geliştirme ekibi

## Bağlam

Kullanıcılar hem check-in (crowd check-in) hem de yorum yapabilmektedir. "Doğrulanmış Ziyaret" rozeti, gerçek bir ziyaret yapıldığının sosyal kanıtı olarak değerlidir. Soru: check-in ile yorum aynı günde mi eşleştirilmeli, yoksa daha uzun bir zaman penceresinde mi?

## Değerlendirilen Alternatifler

1. **Aynı gün (UTC):** Yorum tarihi ile check-in tarihi aynı takvim gününde → doğrulanmış.
2. **72 saat penceresi:** Yorumdan 72 saat öncesine kadar yapılan check-in geçerli.
3. **QR tarama ile eşleştirme:** Kullanıcı yorum yazarken aktif QR session kontrolü.

## Karar

**Seçenek 1**: Aynı gün UTC. `get_business_reviews_v3` sorgusuna `verified_visit boolean` sütunu eklenir; hesaplama SQL içinde yapılır.

```sql
-- verified_visit hesaplama (SQL örneği)
EXISTS (
  SELECT 1 FROM crowd_checkins cc
  WHERE cc.user_id = r.user_id
    AND cc.business_id = r.business_id
    AND DATE(cc.checked_in_at AT TIME ZONE 'UTC')
        = DATE(r.created_at AT TIME ZONE 'UTC')
) AS verified_visit
```

## Gerekçe

- Seçenek 2 abuse riskini artırır (1-2 gün önce girilip geriye dönük yorum yazılabilir).
- Seçenek 3 iOS/Android permission + backend session karmaşıklığı getirir.
- Aynı gün eşleşmesi kullanıcı için şeffaf; manipüle edilmesi zorlaşır.

## Gizlilik Kuralı

`verified_visit` yalnızca boolean olarak public'e sızdırılır. Check-in zamanı veya check-in kimliği hiçbir public endpoint'te açılmaz. RLS: `SECURITY DEFINER` fonksiyon, sadece boolean döner.

## Sonuçlar

**Olumlu:** Basit SQL, yeni tablo gerektirmez, güçlü abuse direnci.  
**Olumsuz:** Farklı zaman dilimleri olan kullanıcılar için UTC bazında yanlış eşleşme olabilir (kabul edilebilir risk).
