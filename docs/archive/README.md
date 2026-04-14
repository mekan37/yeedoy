# Dokuman Arsivi

Bu klasor aktif source-of-truth olmayan ama silinmesi de istenmeyen belgeleri tutar.

## Klasorler

- `history/`: release snapshot'lari, rollback planlari, drift ve temizlik kayitlari
- `reviews/`: tarih damgali audit, execution status ve benzeri denetim raporlari

## Kural

- Yeni aktif belge buraya yazilmaz.
- Bir belge artik guncel operasyon kaynagi degilse ama kurumsal hafiza olarak saklanacaksa arsive tasinir.
- Aktif arama ve navigasyon icin once `docs/index.md` kullanilir.
