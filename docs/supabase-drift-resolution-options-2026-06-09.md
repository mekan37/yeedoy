# Supabase Drift Resolution Options — 2026-06-09

## Özet
- Remote-only migration sayısı: 31
- Local-only migration sayısı: 44
- Gerçek SQL recover edildi mi: Hayır. Git history, deleted history, reflog, eski `D:\yeedoy` kopyası, hedefli local klasör aramaları ve GitHub Actions log incelemesinde bulunamadı.
- Production schema source-of-truth kabul edilmeli mi: Evet, kısa vadede fiili source-of-truth production schema olmalı; migration history ise ayrı bir reconciliation işi olarak ele alınmalı.
- En güvenli öneri: Önce production schema baseline/dump + drift reconciliation raporu hazırlanmalı; PR #95/#96 için gerekirse kontrollü manual SQL apply planı ve ayrı migration history temsil kararı yazılmalı.
- Production apply yapılmalı mı: Şu an hayır. Açık onay, schema baseline ve beklenen smoke test planı olmadan apply yapılmamalı.

## Mevcut Durum
- PR #95/#96 durumu: Main'e merge edildi. `20260609000001`-`20260609000004` alias migration seti local-only görünüyor ve production'a uygulanmadı.
- PR #94 durumu: Açık branch'te timestamp çakışması giderildi; `20260609000005`-`20260609000007` olarak beklemeli.
- Drift raporları:
  - `docs/supabase-migration-drift-inventory-2026-06-09.md`
  - `docs/supabase-remote-applied-migrations-restore-2026-06-09.md`
  - `docs/supabase-marker-migration-strategy-2026-06-09.md`
  - `docs/supabase-external-migration-recovery-2026-06-09.md`
- Neden normal `supabase db push` güvenli değil: Remote history 31 version için local'de temsil edilmiyor, local'de de 44 unapplied version var. Normal push beklenen PR #95/#96 setinden fazlasını uygulamaya kalkabilir veya drift nedeniyle durabilir. Dry-run bile karar için tek başına yeterli değil; önce history/schema stratejisi netleşmeli.

## Seçenek 1 — Marker/no-op migration dosyaları

### Ne çözer?
Remote'da applied görünen 31 version'ın local migration klasöründe dosya olarak temsil edilmesini sağlar. `supabase migration list` görünümündeki remote-only boşlukları azaltabilir.

### Ne çözmez?
Gerçek schema değişikliklerini local'e taşımaz. Local `db reset` sonrası production schema'nın tam karşılığı oluşmayabilir. Local-only 44 migration'ın production karşılığını da çözmez.

### Artılar
Remote history değiştirmeden repo tarafında version temsili sağlar. Review edilebilir, açık yorumlu marker dosyalarla audit trail oluşur. PR #95/#96 pending setini migration list gürültüsünden ayırmayı kolaylaştırabilir.

### Riskler
No-op dosyalar yanlış güven hissi yaratır. Gelecekte geliştiriciler marker'ları gerçek migration sanabilir. Eğer remote-only SQL'ler production'da önemli obje/policy/function oluşturduysa local testler eksik schema üzerinde koşar.

### Ne zaman uygulanabilir?
Gerçek SQL içerikleri bulunamadığı, production schema'nın ayrıca baseline/diff ile doğrulandığı ve marker dosyaların yalnızca history temsil dosyası olduğu açıkça kabul edildiği zaman.

### Bu proje için karar
İlk tercih değil. Ancak production schema baseline alındıktan sonra, remote-only version'ları repo history'de temsil etmek için ayrı ve net etiketli marker PR'ı değerlendirilebilir.

## Seçenek 2 — Production schema baseline / schema dump

### Ne çözer?
Production'ın fiili schema durumunu repo tarafında görünür hale getirir. Remote-only migrationların gerçek SQL'i bulunamasa bile mevcut production state'i karşılaştırma ve doğrulama için temel sağlar.

### Ne çözmez?
Geçmiş migration niyetini ve adım adım değişiklikleri geri getirmez. Migration history tablosundaki 31 remote-only / 44 local-only ayrışmayı tek başına düzeltmez.

### Artılar
Schema doğruluğu açısından en dürüst bilgi kaynağıdır. Marker/no-op stratejisinden daha güvenilir bir teknik baseline sağlar. PR #95/#96 apply öncesi beklenen obje, policy, function ve extension durumunu doğrulamaya yarar.

### Riskler
Dump büyük olabilir ve review edilmesi zor olabilir. Hassas veri içermemesi, sadece schema olması gerekir. Baseline'ın mevcut migration zinciriyle nasıl ilişkileneceği dikkatli tasarlanmalıdır.

### Ne zaman uygulanabilir?
Production read-only schema export/diff alınması için açık onay verildiğinde ve export sürecinin veri değil schema odaklı olacağı netleştiğinde.

### Bu proje için karar
En güvenli ana yön bu. Production schema fiili source-of-truth kabul edilmeli; önce read-only schema baseline/diff raporu hazırlanmalı, sonra marker/history stratejisi seçilmeli.

## Seçenek 3 — Kontrollü manual SQL apply + ayrı history planı

### Ne çözer?
PR #95/#96 gibi küçük, bağımsız ve acil bir migration setinin normal `db push` drift riskinden ayrılarak uygulanmasını sağlayabilir.

### Ne çözmez?
Migration history drift'ini otomatik çözmez. Manual SQL uygulanırsa history'nin nasıl temsil edileceği ayrıca kararlaştırılmalıdır.

### Artılar
Alias search gibi sınırlı kapsamlı değişiklikler, tüm drift çözülmeden kontrollü ve review edilmiş şekilde production'a alınabilir. Smoke test odaklı bir uygulama planı yazılabilir.

### Riskler
History ayrı ele alınmazsa aynı değişiklik ileride tekrar apply edilmeye çalışılabilir. SQL apply ile history repair/marker kararının ayrılması operasyonel karmaşa yaratır.

### Ne zaman uygulanabilir?
SQL dosyaları tek tek review edilir, idempotency/rollback/smoke test planı yazılır, production schema baseline ile ön koşullar doğrulanır ve açık production onayı alınırsa.

### Bu proje için karar
PR #95/#96 için kısa vadeli uygulanabilir seçenek olabilir, fakat yalnızca ayrı bir manual apply runbook + history temsil planı ile. PR #94 için bu seçenek daha riskli; önce alias smoke test tamamlanmalı.

## Seçenek 4 — Supabase migration repair

### Ne çözer?
Supabase migration history tablosundaki applied/reverted kayıtlarını local repo ile hizalamaya yarar.

### Ne çözmez?
Schema'yı değiştirmez ve eksik gerçek SQL içeriklerini geri getirmez. Yanlış kullanılırsa production history'yi gerçeğe aykırı hale getirir.

### Artılar
Doğru kanıtla kullanılırsa migration history drift'ini hızlı düzeltebilir.

### Riskler
Kör repair, gerçekten uygulanmış migrationları history'den düşürür veya uygulanmamış migrationları uygulanmış gibi gösterebilir. Sonraki `db push`/reset kararlarını kalıcı olarak yanıltabilir.

### Neden en son seçenek?
31 remote-only migration'ın gerçek SQL'i ve production schema etkisi bilinmiyor. Bu bilgi olmadan repair, teknik borcu düzeltmek yerine gizler.

### Bu proje için karar
Şu aşamada uygulanmamalı. Ancak production schema baseline, remote-only version değerlendirmesi ve yazılı rollback planı sonrası son seçenek olarak düşünülebilir.

## PR #95/#96 İçin Kısa Vadeli Yol

Alias migration seti:

1. `20260609000001_city_search_aliases.sql`
2. `20260609000002_normalize_tr_location.sql`
3. `20260609000003_update_search_rpcs_city_alias.sql`
4. `20260609000004_fix_normalize_tr_location_combining_dot.sql`

Değerlendirme:
- Bu migration'lar drift çözülmeden production'a alınabilir mi? Normal `supabase db push` ile hayır. Kontrollü manual SQL apply planı ile, production schema baseline ve açık onay sonrası mümkün olabilir.
- Manual apply planı gerekir mi? Evet, eğer tüm drift çözülmeden alias desteği production'a alınacaksa ayrı runbook gerekir.
- History kaydı nasıl ele alınmalı? Manual apply sonrası history için marker/repair/baseline seçeneklerinden biri ayrıca seçilmeli; apply ile history manipülasyonu aynı adımda plansız yapılmamalı.
- Hangi smoke testler yapılmalı?

Smoke test listesi:
- `city_search_aliases` seed kontrolü
- `normalize_tr_location_text('İzmit')`
- `normalize_tr_location_text('i̇zmi̇t')`
- `normalize_tr_location_text('Adapazarı')`
- `search_businesses_v1` alias testi
- `search_nearby_businesses_v3` alias testi
- canonical city testleri
- `p_city = null` regresyon testi

## PR #94 İçin Yol

PR #94 migration seti:

1. `20260609000005_business_location_review_queue.sql`
2. `20260609000006_turkey_districts_reference.sql`
3. `20260609000007_normalize_businesses_location.sql`

Değerlendirme:
- Neden PR #95/#96'dan sonra uygulanmalı? PR #94 city/district değerlerini canonical hale getirir; alias RPC desteği önce production'a alınmazsa `İzmit`, `Adapazarı`, `Afyon`, `Antakya` gibi kullanıcı aramaları boş sonuç riski taşır.
- Neden alias smoke test tamamlanmadan uygulanmamalı? Çünkü PR #94 veri dönüşümü arama davranışını doğrudan etkiler. Alias fonksiyonları ve RPC'ler production verisi üzerinde doğrulanmadan normalization apply etmek kullanıcı-facing search regression yaratabilir.
- Apply öncesi hangi production schema kontrolleri gerekir? `businesses` kolonları, mevcut search RPC imzaları, PostGIS/extension durumu, RLS/policy etkisi, backup tablo adı çakışması, review queue tablo varlığı ve district reference ön koşulları doğrulanmalı.
- Backup/review queue beklentileri neler olmalı? Backup snapshot'ın veri içermesi, review queue insert sayısının dry-run tahminleriyle uyumlu olması, düşük güvenli kayıtların ana veriye dokunmadan kuyruğa gitmesi beklenmeli.

## Önerilen Karar

1. Production schema için read-only baseline/diff raporu hazırlanmalı; production schema fiili source-of-truth kabul edilmeli.
2. PR #95/#96 için normal `db push` yerine ayrı bir kontrollü manual apply runbook hazırlanmalı; runbook smoke test ve history temsil kararını ayrı başlık yapmalı.
3. Remote-only 31 version için marker/no-op dosyalar ancak baseline sonrası ve ayrı PR ile düşünülmeli.
4. `supabase migration repair` şu aşamada kullanılmamalı; sadece kanıtlı ve review edilmiş son seçenek olarak kalmalı.
5. PR #94, PR #95/#96 production apply + alias smoke test tamamlanana kadar beklemeli.

## Kesinlikle Yapılmaması Gerekenler

- `supabase migration repair` kör çalıştırılmamalı
- `supabase db push` normal şekilde çalıştırılmamalı
- Marker/no-op dosyalar ayrı PR ve açık onay olmadan oluşturulmamalı
- PR #95/#96 production’a karar raporu olmadan uygulanmamalı
- PR #94 production’a alias apply + smoke test olmadan uygulanmamalı

## Açık Kararlar

- Production schema baseline alınacak mı: Evet öneriliyor; açık onay ve read-only yöntem belirlenmeli.
- Marker/no-op dosyaları oluşturulacak mı: Şimdilik hayır; baseline sonrası tekrar değerlendirilmeli.
- PR #95/#96 manual apply planı hazırlanacak mı: Evet, alias desteği gerekiyorsa sıradaki teknik plan bu olmalı.
- Migration history nasıl temsil edilecek: Baseline + marker/no-op veya kanıtlı repair seçeneklerinden biri ayrıca seçilmeli.
- PR #94 ne zaman uygulanacak: PR #95/#96 apply ve alias smoke test başarıyla tamamlandıktan sonra.
