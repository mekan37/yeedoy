# Supabase Edge Functions

Bu klasor, Yeedoy'un Supabase Edge Function kaynaklarini tutar. Her alt klasor bir function adina karsilik gelir ve `index.ts` giris noktasi olarak deploy edilir.

## Klasorler

- `admin-api`: allowlist mantigiyla secili admin RPC veya write akislarini tek bir edge girisinden calistirir.
- `ai-allergen-detect`: menu veya urun metninden alerjen adaylarini cikarir.
- `ai-ingredient-detect`: menu veya urun metninden ingredient adaylarini cikarir.
- `ai-menu-analyze`: menu gorseli veya metni uzerinden toplu AI menu analizi yapar.
- `ai-menu-image-gen`: menu veya urun icin AI destekli gorsel uretim akislarini tetikler.
- `ai-nutrition-estimate`: menu metninden yaklasik besin degeri tahmini yapar.
- `anti-spam-guard`: review, report, verify ve benzeri yazma akislarinda anti-spam ve rate-limit denetimi saglar.
- `get-exchange-rates`: kur verisini ceker ve panel tarafindaki coklu para birimi akislarini besler.
- `import_places_json`: JSON kaynakli toplu place import yardimcisidir.
- `media-upload`: panel/admin tarafindaki medya upload endpoint'idir. Su an WordPress media API uyumluluk katmani gibi calisir.
- `media-upload-user`: mobile ve user-scoped upload endpoint'idir. Supabase Storage bucket'larina yazar.
- `purge-temp-uploads`: gecici upload ve temizleme queue'larini periyodik olarak siler.
- `push-dispatch`: veritabaninda kuyruğa alinmis bildirimleri push saglayicilarina yollar.
- `send-push-campaign`: owner tarafindan tetiklenen push kampanyalarini FCM batch ile gonderir.
- `write-gatekeeper`: hassas yazma akislarinda merkezi guard katmani olarak calisir.

## Lokal Calistirma

Repo kokunden:

```bash
supabase start
supabase functions serve media-upload --env-file supabase/.env.local
supabase functions serve media-upload-user --env-file supabase/.env.local
```

Tek bir function yerine birden fazla function localde test edilecekse her biri icin ayri terminal acilabilir.

## `index.ts` Dosyalari Nasil Calisir

Her function klasorundeki `index.ts`, ilgili edge function'in giris dosyasidir. Bu dosya dogrudan `deno run index.ts` gibi calistirilmaz; Supabase CLI function klasorunu okuyup o `index.ts` dosyasini ayağa kaldirir.

Pattern:

```bash
supabase functions serve <function-adi> --env-file supabase/.env.local
```

Ornekler:

```bash
supabase functions serve ai-menu-image-gen --env-file supabase/.env.local
supabase functions serve ai-menu-analyze --env-file supabase/.env.local
supabase functions serve ai-nutrition-estimate --env-file supabase/.env.local
supabase functions serve ai-allergen-detect --env-file supabase/.env.local
supabase functions serve ai-ingredient-detect --env-file supabase/.env.local
supabase functions serve get-exchange-rates --env-file supabase/.env.local
supabase functions serve media-upload --env-file supabase/.env.local
supabase functions serve media-upload-user --env-file supabase/.env.local

tümünü çalıştırma 

supabase functions serve --env-file supabase/.env.local
```


Yani su klasor:

```text
supabase/functions/ai-menu-image-gen/index.ts
```

su komutla calisir:

```bash
supabase functions serve ai-menu-image-gen --env-file supabase/.env.local
```

Serve ettikten sonra function endpoint'i genelde su sekilde olur:

```text
http://127.0.0.1:54321/functions/v1/ai-menu-image-gen
```

Bir function'i degistirdikten sonra en guvenli akis:

```bash
supabase functions serve ai-menu-image-gen --env-file supabase/.env.local
```

ayri bir terminalde de:

```bash
curl -i -X POST "http://127.0.0.1:54321/functions/v1/ai-menu-image-gen"
```

Not:

- `supabase start` local Supabase stack'ini acmak icindir.
- `supabase functions serve ...` ilgili function'in `index.ts` dosyasini local runtime'da sunar.
- Remote'a gondermek icin `serve` degil, `deploy` kullanilir.

## Invoke Ornekleri

JWT gerektiren function'lar icin:

```bash
curl -i \
  -X POST "http://127.0.0.1:54321/functions/v1/media-upload-user" \
  -H "Authorization: Bearer <access-token>" \
  -H "apikey: <anon-key>" \
  -F "file=@./sample.png" \
  -F "title=Sample" \
  -F "business_id=<uuid>"
```

AI function'lari icin tipik pattern:

```bash
curl -i \
  -X POST "http://127.0.0.1:54321/functions/v1/ai-menu-analyze" \
  -H "Authorization: Bearer <access-token>" \
  -H "apikey: <anon-key>" \
  -H "Content-Type: application/json" \
  -d "{\"imageUrl\":\"https://...\",\"locale\":\"tr\"}"
```

## Deploy

Tek function deploy:

```bash
supabase functions deploy media-upload --project-ref <project-ref>
```

Birden fazla function deploy:

```bash
supabase functions deploy media-upload --project-ref <project-ref>
supabase functions deploy media-upload-user --project-ref <project-ref>
supabase functions deploy ai-menu-analyze --project-ref <project-ref>
```

## Ortam Degiskenleri

Function bazinda gereken env'ler farklidir, ama ana grup su sekildedir:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENROUTER_API_KEY` veya ilgili AI provider key'leri
- `WP_BASE_URL`
- `WP_USERNAME`
- `WP_APP_PASSWORD`
- `EDGE_RATE_LIMIT_SALT`

Notlar:

- `media-upload` hala WordPress media API'ye yazar. Isim temizlendi, davranis legacy uyumluluk icin korunuyor.
- `media-upload-user` dogrudan Supabase Storage kullanir.
- Env degerleri repo icine hardcode edilmemeli; local icin `supabase/.env.local`, deploy icin Supabase secrets kullanilmalidir.

## Kontrol

Deploy sonrasi:

```bash
supabase functions list
supabase functions logs media-upload --project-ref <project-ref>
supabase functions logs media-upload-user --project-ref <project-ref>
```

Panel veya mobile istemci function adini degistirdiginde, istemci endpoint referanslari ve bu README birlikte guncellenmelidir.
