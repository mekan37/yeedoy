# Panel Placeholder Klasorleri

Bu dokuman `apps/panel_flutter_web` icinde bilincli olarak korunan fakat bugun aktif runtime kodu tasimayan klasorleri aciklar.

## `assets/brand`

Amac:

- Production brand logo, lockup ve export varyantlarini barindirmak
- Flutter asset manifest'ine yalnizca gercek dosya eklendiginde girmek

Neden bos olabilir:

- Panel tarafinda branded asset pipeline'i ayri yonetiliyor
- Her placeholder dosya repo sisirmesin diye klasor ici `.md` yerine bu merkezi dokuman tutuluyor

## `lib/core/privacy`

Amac:

- privacy / KVKK / GDPR odakli ortak policy helper'lari
- consent state helper'lari
- data deletion / export workflow'lari

Neden bos olabilir:

- Su an production panel akisinda ayri bir Flutter privacy modulu yok
- Alan gelecekte ortak privacy yardimcilari icin ayrildi
