# Dokuman Arsivi

Bu klasor aktif source-of-truth olmayan ama silinmesi de istenmeyen belgeleri tutar.

## Klasorler

- `gecmis/`: surum snapshot'lari, geri alma planlari, kayma ve temizlik kayitlari
- `incelemeler/`: tarih damgali denetim, yurutme durumu ve benzeri raporlar

## Kural

- Yeni aktif belge buraya yazilmaz.
- Bir belge artik guncel operasyon kaynagi degilse ama kurumsal hafiza olarak saklanacaksa arsive tasinir.
- Aktif arama ve navigasyon icin once `docs/index.md` kullanilir.
