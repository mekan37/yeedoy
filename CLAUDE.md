# Yeedoy Claude Calisma Notlari

Bu dosya `AGENTS.md` ile ayni mimariyi uygular; farki, Claude/Codex calisma akisini kisa operasyon kurallari olarak vermesidir.

## Once Neyi Okuyacaksin

- Repo geneli: `AGENTS.md`
- Mimari sinirlar: `docs/mimari-kurallari.md`
- UI kurallari: `docs/style-guide.md`
- Adlandirma: `docs/naming-conventions.md`
- I18n: `docs/ceviri-kurallari.md`

App bazli calisiyorsan:

- `uygulamalar/mobil/AGENTS.md`
- `uygulamalar/web/AGENTS.md`

## Repo Gercegi

- Ana runtime Flutter + Next + Supabase monorepo'sudur.
- Riverpod, GoRouter, Supabase RPC desenleri Flutter tarafinda baskindir.
- Next tarafinda App Router + `src/lib` helper'lari + `zod` validation baskindir.
- Tema kaynagi Flutter theme'dir; web sadece aynasini tutar.

## Yapman Gerekenler

- Yeni kodu mevcut app sinirinda tut.
- Repository/provider/controller/page adlandirma zincirini bozma.
- Flutter'da deposu disinda yeni Supabase erisimi acma.
- Web'de route handler yaziyorsan `safeParse`, auth ve rate-limit ekle.
- Yeni copy ekliyorsan Flutter icin ARB, web icin `src/lib/i18n.ts` kullan.
- Duplicated primitive gorursen dorduncu kopya yazma; mevcut local primitive'i kullan veya gercekten ortaksa `packages/shared_ui_components` hedefle.

## Yapmaman Gerekenler

- `packages/api_client`, `packages/shared_config`, `packages/shared_types` ustune yeni mimari kurma.
- `uygulamalar/web` icine owner/admin CRUD tasima.
- Mobil/panel disinda ikinci state yonetimi kutuphanesi ekleme.
- Inline renk, spacing, raw Tailwind hex, inline ARB-disi user string gommek.
- Root dokumanlardaki eski generik kurallari tekrar etme; bu repo icin gecerli degiller.

## Minimum Dogrulama

- Flutter kodu: `flutter analyze`
- Panel degisikligi: `flutter analyze` + `flutter test`
- Web degisikligi: `npm run typecheck` + `npm run lint`
- L10n degisikligi: `node tools/ceviri-denetimi.mjs`

Dokumantasyon-only degisikliginde test calistirmak zorunlu degildir; ancak hangi komutlarin calistirilmadigini acikca belirt.
