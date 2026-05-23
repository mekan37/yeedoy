# Panel Kullanilmayan Dosya Temizligi

Bu dokuman `uygulamalar/panel_flutter_web` icinde analiz sonrasi kaldirilan kullanilmayan veya tekrar eden dosyalari listeler.

## Silinen Dosyalar

### `uygulamalar/panel_flutter_web/tool/README_release_gate.md`

- Neden silindi:
  - Script degildi, sadece aciklama dosyasiydi.
  - Tekrarladigi icerik yeni tek kaynak dokumanlara tasindi.
  - Repo icinde baska bir dosya tarafindan referans edilmiyordu.
- Yerine ne var:
  - `docs/tools_inventory.md`
  - `docs/test_strategy.md`

### `uygulamalar/panel_flutter_web/tool/README_qa_strategy.md`

- Neden silindi:
  - Script degildi, QA akislarini aciklayan tekrar dokumaniydi.
  - `basic_surfaces_golden_test.dart` gibi artik aktif olmayan kalintilari da referansliyordu.
  - Repo icinde baska bir dosya tarafindan referans edilmiyordu.
- Yerine ne var:
  - `docs/test_strategy.md`
  - `docs/tools_inventory.md`

### `uygulamalar/panel_flutter_web/test/ui/golden/basic_surfaces_golden_test.dart`

- Neden silindi:
  - Varsayilan olarak skip idi (`RUN_GOLDENS` gerektiriyordu).
  - Repo icinde `test/ui/golden/goldens/` referans asset'leri yoktu.
  - `package.json`, CI veya baska bir test paketi tarafindan tetiklenmiyordu.
- Yerine ne var:
  - Yok

### `uygulamalar/panel_flutter_web/test/core/contracts/README.md`

- Neden silindi:
  - Gercek test dosyasi degil, sadece placeholder README idi.
  - Herhangi bir test kosumunda kullanilmiyordu.
  - `test_strategy` icinde artik aktif test seti aciklandigi icin ayri stub gereksizdi.
- Yerine ne var:
  - Yok

## Not

- `uygulamalar/panel_flutter_web/tools/` altinda aktif dosya bulunmadi.
- Aktif yardimci scriptler `uygulamalar/panel_flutter_web/tool/` altinda tutuluyor ve korunuyor.
