# CRM v2 — Müşteri Listesi Arama — Design Doc

## Bağlam

CRM v1'in "Kapsam Dışı" bölümünde bırakılan dört bağımsız alt-özellikten ikincisi (bkz. `docs/superpowers/specs/2026-08-11-crm-musteri-profili-design.md`): not/etiket ekleme tamamlandı (`docs/superpowers/specs/2026-08-11-crm-v2-not-etiket-design.md`), sıradaki bu alt-proje **arama/filtre**.

## Hedefler

- Owner, `/sahip/musteriler` listesinde müşteri adına göre anlık arama yapabilsin.

## Kapsam Dışı (YAGNI)

- Etiket bazlı filtre (dropdown/chip) — sadece isim araması var, ayrı bir kontrol yok.
- Sunucu taraflı arama (`?q=` + RPC parametresi) — liste zaten tek seferde tamamen yükleniyor (sayfalama yok), bu ölçekte client-side filtreleme yeterli.
- Debounce — client-side filtreleme küçük bir diziyi (`Array.filter`) her tuş vuruşunda anında filtreler, gecikme gerekmiyor.
- Zincir-çapında/diğer sayfalarda arama — sadece `/sahip/musteriler` kapsamda.

## Tasarım

`musteri-listesi.tsx` şu an bir server-render edilen (ama zaten client tarafında state gerektirmeyen) saf sunum bileşeni. Arama state'i eklemek için `'use client'` olur:

- `useState<string>` — arama metni.
- Filtreleme mantığı ayrı bir saf fonksiyona çıkarılır (test edilebilir olsun diye): `filtrelenmisMusteriler(musteriler, aramaMetni)`.
- Eşleştirme: `m.display_name.toLocaleLowerCase('tr').includes(aramaMetni.toLocaleLowerCase('tr'))`. **Not:** plain `.toLowerCase()` kullanılmayacak — Türkçe İ/i büyük/küçük harf dönüşümü `.toLowerCase()` ile bozuluyor (İstanbul → i̇stanbul, iki karakter), bu projede önceden gerçek bir arama bug'ına sebep olmuştu (bkz. çoklu şube zincir arama düzeltmesi). `.toLocaleLowerCase('tr')` doğru sonucu verir.
- `useMemo` ile her `aramaMetni` değişiminde filtrelenmiş liste yeniden hesaplanır.
- `page.tsx` değişmez — hâlâ tüm `musteriler` dizisini `MusteriListesi`'ye prop olarak geçer.

## UI

- Tablonun üstüne bir arama `<input>` eklenir: `placeholder="Müşteri ara..."`, mevcut input stil deseniyle aynı (`rounded-xl border border-border bg-card px-4 py-2 text-sm ...`, admin kullanıcılar sayfasındaki arama kutusuyla tutarlı).
- Boş durum iki ayrı mesaj: (a) `musteriler.length === 0` → mevcut "Henüz hiç müşteri etkileşimi yok"; (b) filtre sonucu boş ama orijinal liste boş değil → yeni mesaj: `` `"${aramaMetni}" ile eşleşen müşteri bulunamadı.` ``.

## Test

- `filtrelenmisMusteriler` saf fonksiyonu için birim testleri: boş arama (tüm liste döner), eşleşen isim, eşleşmeyen isim (boş dizi), Türkçe büyük/küçük harf senaryosu (`"istanbul"` araması `"İstanbul Şube"` adlı bir müşteriyle eşleşmeli).

## Güvenlik

Yeni bir RPC/migration yok, hiçbir yetkilendirme yüzeyi değişmiyor — mevcut `get_business_customers_v1` dönüşü üzerinde saf client-side filtreleme. Ek güvenlik incelemesi gerekmiyor.
