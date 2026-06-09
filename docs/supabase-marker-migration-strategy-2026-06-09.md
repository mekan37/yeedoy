# Supabase Marker Migration Strategy — 2026-06-09

## Özet
- Remote-only version sayısı: 31
- İçerik recover edilebildi mi: Hayır; git history, deleted history, object list ve reflog aramasında içerik bulunamadı.
- Marker/no-op öneriliyor mu: Kısa vadede yalnızca review edilmiş ve açıkça belgelenmiş bir ara çözüm olarak değerlendirilebilir; ilk tercih olmamalı.
- Kısa karar: Önce git dışı recovery ve production schema doğrulaması denenmeli. Marker/no-op dosyalar ancak remote-only kayıtların gerçek schema etkisi başka yollarla doğrulanıp repo history uyumu için temsil dosyası gerektiği kabul edilirse ayrı PR ile oluşturulmalı.

## Marker Migration Nedir?
- Açıklama: Marker migration, remote migration history'de applied görünen ama local repo'da gerçek SQL içeriği bulunamayan bir version'ı local migration klasöründe temsil eden bilinçli no-op dosyadır. Amacı schema değiştirmek değil, local dosya setinin remote history'deki version numarasını tanımasını sağlamaktır.
- Örnek no-op SQL:
```sql
-- Remote-applied migration marker.
-- Version: <VERSION>
-- Original migration content could not be recovered from git history.
-- This file exists only to represent remote migration history locally.
-- It must remain a no-op.
select 1;
```

## Artılar

* Local migration klasörü remote history'de görünen version numaralarını temsil etmeye başlar.
* `supabase migration list` çıktısındaki remote-only boşluklar azalabilir.
* İleride `db push --dry-run` çıktısı daha okunabilir hale gelebilir; PR #95/#96 gibi yeni pending migration'ları drift gürültüsünden ayırmak kolaylaşabilir.
* Marker dosyaları review edilebilir, açıklamalı ve arşivlenmiş bir audit trail oluşturur.
* Remote history'yi değiştirmeden, repo tarafında temsil eksikliğini gidermeye çalışır.

## Eksiler / Riskler

* Marker dosyalar gerçek schema değişikliğini içermez; local `db reset` sonrası schema production'ı temsil etmeyebilir.
* Eski migration'ın gerçek SQL'i bilinmediği için marker dosya yanlış güven hissi yaratabilir.
* Eğer remote-only migration'lar production schema'da önemli değişiklikler yaptıysa no-op dosyalar bu değişiklikleri local/staging'e taşımaz.
* Future contributor'lar marker dosyaları gerçek migration sanabilir; dosya başlığı ve docs çok açık olmalı.
* Marker stratejisi, local-only 44 migration'ın production karşılığı sorununu tek başına çözmez.
* No-op marker dosyaları remote history ile local version listesini hizalasa bile semantic schema drift devam edebilir.

## Supabase CLI Davranışı Değerlendirmesi

### `supabase migration list`

* Aynı version numaralı marker dosyalar eklendiğinde remote-only satırların local tarafı dolabilir.
* Bu, history görünümünü iyileştirir ancak migration içeriğinin gerçekliğini garanti etmez.
* `migration list` daha temiz görünse bile production schema ile local reset schema arasında fark kalabilir.

### `supabase db push --dry-run`

* Marker dosyalar remote'da already-applied görünen version'lar için tekrar apply edilmemelidir.
* Dry-run'ın PR #95/#96 gibi yeni local-only migration'ları göstermesi daha olası hale gelir.
* Ancak local-only eski migration'lar hâlâ remote'da missing görünüyorsa dry-run yine beklenen PR setinden fazlasını gösterebilir.
* Bu nedenle marker dosyalar eklense bile dry-run tek başına apply onayı sayılmamalı; çıktı beklenen migration listesiyle satır satır karşılaştırılmalı.

### `supabase db reset`

* `db reset` local migration dosyalarını sırayla uygular.
* Marker/no-op dosyalar gerçek eski schema değişikliklerini üretmeyeceği için reset sonrası local schema production geçmişinden eksik kalabilir.
* Eğer remote-only migration'lar yalnızca ephemeral/obsolete history kayıtlarıysa risk düşük olabilir; aksi kanıtlanmadan düşük kabul edilmemeli.
* Local testlerde production'da var olan tablo/fonksiyon/policy eksikliği saklanabilir veya tersine beklenmeyen farklar oluşabilir.

### Remote already-applied version

* Remote history'de applied olan version için marker dosya eklemek remote'a schema değişikliği yapmaz.
* Normal şartta CLI bu version'ı already-applied gördüğü için marker SQL'i remote'a push etmez.
* Risk, history'nin yanlış yorumlanması veya sonradan repair ile durumun değiştirilmesidir; bu yüzden repair ve marker stratejisi aynı anda plansız uygulanmamalı.

### Local schema doğruluğu

* Marker dosyalar local schema doğruluğunu artırmaz; yalnızca migration version temsilini artırır.
* Local schema doğruluğu için gerçek migration SQL'i, schema dump/baseline veya production schema diff gerekir.
* Marker dosya kullanılan her version için "content unrecovered, no-op marker only" bilgisi dosyada ve merkezi raporda kalmalı.

## Migration Repair Alternatifi

* Ne işe yarar: Supabase migration history tablosunda version durumunu applied/reverted olarak elle hizalamaya yarar.
* Bu durumda neden riskli: Remote-only kayıtların gerçek schema etkisi bilinmiyor. Kör repair, production history'den gerçekten uygulanmış değişiklikleri silmiş gibi gösterebilir ve gelecekte yanlış apply/skip kararlarına neden olabilir.
* Ne zaman düşünülebilir: Remote-only kayıtların schema karşılığı olmadığı, hatalı history kaydı olduğu veya başka bir canonical baseline ile değiştirileceği kanıtlanırsa; yazılı plan, backup ve review sonrası.

## Manual Schema Baseline Alternatifi

* Ne işe yarar: Production schema'nın belirli bir andaki gerçek halini yeni bir baseline olarak repo'ya taşır; sonraki migration'lar bu baseline üzerine kurulur.
* Avantaj: Gerçek schema durumunu temsil etme şansı marker/no-op dosyalardan daha yüksektir.
* Risk: Büyük diff üretir, history okunabilirliğini azaltabilir, mevcut migration zinciriyle nasıl ilişkileneceği dikkatli tasarlanmalıdır.
* Ne zaman doğru olabilir: Eski migration içerikleri bulunamıyor, drift çok büyük, production schema artık fiili source-of-truth kabul edilmek zorundaysa.

## Git Dışı Kaynaklardan Recovery Alternatifi

Araştırılabilecek yerler:

* eski local clone
* ekip arkadaşının clone’u
* CI artifacts
* Supabase dashboard SQL editor history
* backup dosyaları
* eski PR branchleri
* GitHub Actions logları
* Claude/Codex çalışma çıktıları
* zip/backup klasörleri

Bu alternatif en doğru ilk adımdır. Gerçek migration içerikleri bulunursa marker/no-op dosyaya gerek kalmadan remote history repo'ya daha dürüst şekilde geri kazandırılabilir.

## Önerilen Yol

1. Remote-only 31 version için git dışı recovery kaynakları kontrol edilsin.
2. Bulunan gerçek SQL dosyaları aynı version filename ile repo'ya geri kazandırılsın; bulunamayanlar için kanıt listesi güncellensin.
3. Hâlâ bulunamayan version'lar için marker/no-op PR taslağı hazırlansın, ancak her dosyada bunun gerçek SQL olmadığı açıkça yazılsın.
4. Marker PR merge edilse bile `db push --dry-run` sadece beklenen migration'ları gösterene kadar production apply yapılmasın.

## Kesinlikle Yapılmaması Gerekenler

* `supabase migration repair` kör çalıştırılmamalı
* Remote history local’e uydurulmak için silinmemeli
* PR #95/#96 production’a drift çözülmeden uygulanmamalı
* PR #94 production’a alias apply + smoke test olmadan uygulanmamalı

## Karar Bekleyen Noktalar

* Marker dosyaları oluşturulsun mu: Henüz hayır; önce git dışı recovery denenmeli.
* Önce git dışı kaynak recovery denensin mi: Evet.
* Önce Supabase support/dashboard history kontrolü gerekiyor mu: Evet, özellikle 31 remote-only version için.
* PR #95/#96 apply ne zaman denenebilir: Remote/local history planı netleşip `db push --dry-run` çıktısı yalnızca beklenen pending migration setini gösterdiğinde ve açık production onayı verildiğinde.
