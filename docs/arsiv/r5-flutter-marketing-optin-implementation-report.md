# R-5 Flutter Pazarlama Opt-in Bağlama — Uygulama Raporu

Tarih: 2026-06-18
Katman: Flutter mobil (yalnızca Flutter)
Durum: Tamamlandı — `flutter analyze` temiz, 27/27 test geçti

---

## Kapsam

Bu rapor Yeedoy R-5 pazarlama e-posta izni özelliğinin Flutter mobil tarafını kapsar.
Web, Next.js ve Edge Function katmanları bu raporun dışındadır (bkz. `r5-email-filter-token-hardening-report.md`).

---

## Yapılan Değişiklikler Özeti

Beş dosya oluşturuldu/değiştirildi; iki dosyaya test yazıldı.

### Oluşturulan Dosyalar

| Dosya | Rol |
|---|---|
| `lib/features/notifications/domain/notification_preferences_models.dart` | `NotificationPreferences` immutable model |
| `lib/features/notifications/data/notification_preferences_repository.dart` | Abstract arayüz + `_NotificationPreferencesRepositoryImpl` |
| `lib/features/notifications/domain/notification_preferences_provider.dart` | Riverpod `AsyncNotifier` — optimistik güncelleme + rollback |
| `test/features/notifications/domain/notification_preferences_test.dart` | 19 birim testi |
| `test/features/legal/legal_acceptance_marketing_test.dart` | 8 iş mantığı testi |

### Değiştirilen Dosyalar

| Dosya | Değişiklik |
|---|---|
| `lib/features/notifications/ui/notification_preferences_page.dart` | `StatefulWidget` → `ConsumerStatefulWidget`; "Pazarlama E-postaları" bölümü eklendi |
| `lib/features/legal/ui/legal_acceptance_page.dart` | `_submit()` pazarlama RPC entegrasyonu; `_saveMarketingOptIn()` eklendi |

---

## Model

`NotificationPreferences` — `lib/features/notifications/domain/notification_preferences_models.dart`

Alanlar:
- `marketingEmailOptIn: bool` — global pazarlama e-posta izni
- `marketingEmailOptedInAt: DateTime?` — iznin verildiği an (opt-out'ta null)

Özellikler:
- `const` constructor, `@immutable`
- `defaultValue` sabiti: `marketingEmailOptIn: false`
- `fromRpcJson()`: `marketing_email_opt_in` ve `marketing_email_opted_in_at` alanlarını ayrıştırır; null değerler güvenle işlenir
- `copyWith()`: `clearOptedInAt: true` parametresiyle `opted_in_at` alanı null yapılabilir

---

## Repository

`NotificationPreferencesRepository` — soyut arayüz

```
abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> getMyNotificationPreferences();
  Future<void> updateMyMarketingEmailOptIn({required bool enabled});
}
```

Gerçek implementasyon `_NotificationPreferencesRepositoryImpl` (private):

- `getMyNotificationPreferences()`: `get_my_notification_preferences_v1()` RPC çağrısı. `PostgrestException` dahil tüm hatalar yakalanır, `defaultValue` döndürülür — asla exception fırlatmaz.
- `updateMyMarketingEmailOptIn({required bool enabled})`: `update_my_marketing_email_opt_in_v1(p_value: enabled)` RPC çağrısı. Auth kontrolü: `uid == null` ise `StateError('auth_required')` fırlatır.

`notificationPreferencesRepositoryProvider` — `Provider<NotificationPreferencesRepository>`, Riverpod container'ında `supabaseProvider` bağımlılığı ile oluşturulur.

### Kritik Ayrımlar

- `business_follows.is_subscribed_email` bu repository tarafından hiçbir zaman okunmaz veya yazılmaz. Bu alan işletme bazlı aboneliği temsil eder; global pazarlama izninden tamamen bağımsızdır.
- `SharedPreferences` source-of-truth değildir. Değer yalnızca Supabase RPC üzerinden saklanır.

---

## Provider

`NotificationPreferencesNotifier` — `lib/features/notifications/domain/notification_preferences_provider.dart`

Riverpod 3.x `AsyncNotifier<NotificationPreferences>`:

- `build()`: `getMyNotificationPreferences()` çağrısı — sayfa ilk yüklenirken RPC tetiklenir.
- `setMarketingEmailOptIn({required bool enabled})`:
  1. Önceki `state.asData?.value` saklanır.
  2. Optimistik güncelleme: `state = AsyncData(previous.copyWith(...))` — UI anlık döner.
  3. RPC çağrısı: `updateMyMarketingEmailOptIn(enabled: enabled)`.
  4. Başarı: `getMyNotificationPreferences()` ile güncel değer yeniden çekilir (`opted_in_at` dahil).
  5. Hata: `state = AsyncData(previous)` ile rollback, exception rethrow edilir — çağıran UI katmanı SnackBar gösterir.
- `refresh()`: `AsyncLoading` → `AsyncValue.guard(...)` ile yeniden yükleme.

---

## legal_acceptance_page.dart Davranışı

`_submit()` değişikliği:

1. `_acceptedRequiredPolicies` false ise erken dönüş — ne RPC ne navigate.
2. `acceptPolicyVersions(versions)` — zorunlu adım. Hata fırlatırsa `catch` bloku devralır, navigate edilmez.
3. `_marketingOptIn == true` ise `_saveMarketingOptIn(enabled: true)` çağrılır.
4. `_marketingOptIn == false` ise RPC çağrılmaz — backend default `false` değerini korur.
5. `_saveMarketingOptIn()` hata alırsa: kullanıcıya SnackBar gösterilir ("Pazarlama e-posta tercihiniz kaydedilemedi. Bildirim ayarlarından tekrar değiştirebilirsiniz."), ancak navigate engellenmez — zorunlu kabul akışı bloke olmaz.

---

## notification_preferences_page.dart Davranışı

Değişiklik özeti:
- `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`
- "Pazarlama E-postaları" bölümü eklendi — mevcut push bildirim bölümlerinin (kanallar, kategoriler, sessiz saatler) altında, footer'ın üstünde.

`_MarketingEmailSection` (ConsumerWidget):
- `notificationPreferencesProvider` izlenir.
- `loading`: küçük progress indicator.
- `error`: satır içi hata mesajı + yenile butonu.
- `data`: `_MarketingEmailTile` gösterilir.

`_MarketingEmailTile`:
- Başlık: "Pazarlama e-postaları"
- Açıklama: "Yeedoy kampanyaları, yenilikleri ve fırsatları hakkında e-posta almak istiyorum."
- Switch: `setMarketingEmailOptIn(enabled: value)` tetikler.
- RPC hatası → SnackBar: "Tercih kaydedilemedi. Lütfen tekrar deneyin."
- Alt bilgi: "Bu izni dilediğiniz zaman kapatabilirsiniz."

Mevcut bölümler (push, kanallar, kategoriler, sessiz saatler) değiştirilmedi.

---

## Kullanılan RPC'ler

| RPC | Kullanım yeri | Yön |
|---|---|---|
| `get_my_notification_preferences_v1()` | `_NotificationPreferencesRepositoryImpl.getMyNotificationPreferences()` | Okuma |
| `update_my_marketing_email_opt_in_v1(p_value: bool)` | `_NotificationPreferencesRepositoryImpl.updateMyMarketingEmailOptIn()` | Yazma |

Migration bağımlılığı: `user_profiles.marketing_email_opt_in` sütunu `20260620000001` migrasyonu ile eklendi. Migration üretimde uygulanmamışsa `getMyNotificationPreferences()` `PGRST202` hatası alır ve `defaultValue` döndürür — uygulama çökmez.

---

## Çalıştırılan Testler

```
flutter analyze lib/features/notifications/data/notification_preferences_repository.dart \
  lib/features/notifications/domain/notification_preferences_models.dart \
  lib/features/notifications/domain/notification_preferences_provider.dart \
  lib/features/notifications/ui/notification_preferences_page.dart \
  lib/features/legal/ui/legal_acceptance_page.dart
→ No issues found.

flutter test test/features/notifications/domain/notification_preferences_test.dart \
  test/features/legal/legal_acceptance_marketing_test.dart
→ 27/27 All tests passed.
```

Test dağılımı:

| Dosya | Test sayısı | Kapsam |
|---|---|---|
| `notification_preferences_test.dart` | 19 | Model (6), Repository fake (5), Notifier (8) |
| `legal_acceptance_marketing_test.dart` | 8 | T1–T8: _submit() pazarlama opt-in iş mantığı |

Notifier testleri (önemli senaryolar):
- `build()` başlangıç değeri yükler
- `setMarketingEmailOptIn(true)` → RPC `true` ile çağrılır
- `setMarketingEmailOptIn(false)` → RPC `false` ile çağrılır
- Optimistik güncelleme: RPC bitmeden state hemen değişir
- RPC hata verirse rollback: eski değere döner
- `business_follows.is_subscribed_email` global pazarlama izni olarak kullanılmaz
- `SharedPreferences` source-of-truth değil

Legal tests (T1–T8):
- T1: `_marketingOptIn=true` → RPC çağrılır
- T2: `_marketingOptIn=false` → RPC çağrılmaz (otomatik opt-in yok)
- T3: Zorunlu kabul yok → navigate yok, RPC yok
- T4: Pazarlama RPC hatası → navigate devam eder (bloke olmaz)
- T5: Zorunlu kabul RPC hatası → navigate bloke olur
- T6: `is_subscribed_email` global izin olarak kullanılmaz
- T7: `SharedPreferences` kullanılmaz — RPC source-of-truth
- T8: `ProviderContainer` entegrasyon — `notificationPreferencesProvider` başlangıç değeri

---

## Çalıştırılamayan Testler

`AsyncNotifier.build()` hata fırlatınca oluşan `AsyncError` state geçişi `ProviderContainer` birim testinde `FakeAsync` veya `WidgetTester.pumpAndSettle()` olmadan güvenle beklenemiyor (Riverpod 3.3.2). Bu senaryo `notification_preferences_test.dart` içinde repository katmanında exception assertion ile belgelenmiştir; notifier katmanındaki `AsyncError` state geçişi widget integration testinde doğrulanmalıdır.

---

## SharedPreferences Durumu

Pazarlama e-posta izni için `SharedPreferences` kullanılmamaktadır. Değer yalnızca Supabase `user_profiles.marketing_email_opt_in` sütununda tutulur; okuma ve yazma işlemleri yalnızca RPC üzerinden gerçekleşir. Bu yaklaşım:
- Cihaz değişikliğinde doğru değeri garanti eder.
- Çevrimdışı durumda `defaultValue` (false) ile güvenli başarısızlık sağlar.
- KVKK md.11/2-ç ret hakkı gereksinimini yalnızca backend'de değer tutarak sağlar.

---

## Global Pazarlama İzni / İşletme Bazlı Abonelik Ayrımı

| Alan | Tablo | Bu repository | Açıklama |
|---|---|---|---|
| `marketing_email_opt_in` | `user_profiles` | Evet — okur ve yazar | Global platform pazarlama izni |
| `is_subscribed_email` | `business_follows` | Hayır — hiç dokunulmaz | İşletme bazlı e-posta aboneliği |

Bu iki alan birbirinden tamamen bağımsızdır. `NotificationPreferencesRepository` yalnızca `marketing_email_opt_in` alanıyla ilgilenir.

---

## Kalan Riskler

| Risk | Önem | Durum |
|---|---|---|
| Migration üretimde uygulanmamış (`20260620000001`) | Yüksek | Repository güvenle `defaultValue` döner; uygulama çökmez. Migration uygulandıktan sonra değer doğru okunur. |
| Migration üretimde uygulanmamış (`20260620000002`) | Yüksek | `notification_preferences_page.dart` toggle gösterilir ama RPC hata verir. UI hata mesajı gösterir. |
| `UNSUBSCRIBE_HMAC_SECRET` eksik | Yüksek | Flutter tarafında etkisi yok — edge function katmanı. Bkz. `r5-email-filter-token-hardening-report.md`. |
| `notification_preferences_page.dart` widget integration testi yok | Düşük | Birim testleri iş mantığını kapsar; UI entegrasyon testi sprint içinde eklenebilir. |
| İşletme bazlı e-posta abonelik yönetimi (`/bildirim-ayarlari`) | Düşük | `business_follows.is_subscribed_email` için ayrı UI gerekir — bu sprint dışında. |

---

## Production Öncesi Kontrol Listesi

- [ ] Migration `20260620000001` üretimde uygulandı mı? (`user_profiles.marketing_email_opt_in` sütunu mevcut)
- [ ] Migration `20260620000002` üretimde uygulandı mı? (`get_my_notification_preferences_v1` ve `update_my_marketing_email_opt_in_v1` RPCs mevcut)
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Next.js ortam değişkeni ayarlandı mı?
- [ ] `UNSUBSCRIBE_HMAC_SECRET` Supabase edge function secret olarak yapılandırıldı mı?
- [ ] `legal_acceptance_page.dart` end-to-end smoke testi yapıldı mı? (opt-in true ve false her iki yol)
- [ ] `notification_preferences_page.dart` toggle açıp kapatma smoke testi yapıldı mı?
- [ ] Unsubscribe bağlantısı e-postada doğru görünüyor mu? (6563 md.9/3 gerekliliği)

---

## Sonraki QA Adımı

1. Migration'lar uygulandıktan sonra staging ortamında uçtan uca test:
   - Legal kabul sayfasında opt-in true ile kayıt → `user_profiles.marketing_email_opt_in = true` doğrulanır
   - Legal kabul sayfasında opt-in false ile kayıt → `user_profiles.marketing_email_opt_in = false` (değişmez)
   - Bildirim ayarları toggle açma/kapatma → anlık UI, rollback (mock ağ hatası)
2. `WidgetTester` ile `_MarketingEmailSection` entegrasyon testi: `AsyncError` state gösterimi.
3. İşletme bazlı e-posta abonelik sayfası `/bildirim-ayarlari` — `business_follows.is_subscribed_email` yönetimi için ayrı sprint maddesi.
