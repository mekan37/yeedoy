# Supabase External Migration Recovery — 2026-06-09

## Özet
- Remote-only toplam: 31
- Git dışı kaynaklarda bulunan: 0
- Hâlâ bulunamayan: 31
- Restore edilebilir gerçek SQL dosyası var mı: Hayır
- Production işlemi yapıldı mı: Hayır
- Marker dosyası oluşturuldu mu: Hayır
- Repair çalıştırıldı mı: Hayır

Bu çalışma yalnızca okuma ve dokümantasyon amaçlıdır. `supabase db push`, `supabase db push --dry-run`, `supabase migration repair`, `supabase migration up`, `apply_migration`, production SQL ve remote migration history değiştiren işlem çalıştırılmadı.

## Araştırılan Kaynaklar
| Kaynak | Kontrol edildi mi | Sonuç | Not |
|---|---:|---|---|
| `C:\` root yeedoy klasörleri | Evet | `C:\yeedoy` bulundu | Aktif çalışma kopyası |
| `D:\` root yeedoy klasörleri | Evet | `D:\yeedoy` bulundu | Eski/ayrı repo kopyası; remote-only timestamp bulunmadı |
| Downloads/Desktop archive dosyaları | Evet | Migration içerikli aday bulunmadı | `yeedoy_logo_assets.zip` ve unrelated arşivler görüldü |
| `C:\Users\Mustafa\Downloads` | Evet | Eşleşme yok | `*.sql`, `*.md`, `*.txt`, `*.log`, `*.json`, `*.yaml`, `*.yml` arandı |
| `C:\Users\Mustafa\Desktop` | Evet | Eşleşme yok | Aynı remote-only pattern ile arandı |
| `C:\Users\Mustafa\Documents` | Evet | Eşleşme yok | Aynı remote-only pattern ile arandı |
| `C:\Users\Mustafa\.codex` | Evet | Eşleşme yok | Aynı remote-only pattern ile arandı |
| `C:\Users\Mustafa` genel recursive arama | Kısmen | 5 dakika timeout | Çok geniş olduğu için hedefli alt klasör aramalarıyla sınırlandı |
| `D:\yeedoy\supabase\migrations` | Evet | Eşleşme yok | Remote-only version dosyası yok |
| `D:\yeedoy` git history/reflog | Evet | Eşleşme yok | `git log --all`, `name-status`, `walk-reflogs` pattern arandı |
| GitHub PR listesi | Evet | Remote-only içerik yok | 300 PR listelendi; migration PR'ları yalnızca mevcut repo dosyalarına işaret ediyor |
| GitHub Actions run listesi | Evet | Remote-only içerik yok | 570 run listelendi; liste 2026-06-02 ve bazı eski main run'lara kadar indi |
| GitHub Actions logları | Kısmen | Remote-only içerik yok | 2026-06-03/05 migration branch run loglarında timestamp ve apply izleri aranıp bulunmadı |

## Bulunan Adaylar
| Version | Kaynak | Dosya/Log | Güven seviyesi | Restore önerisi |
|---|---|---|---|---|
| — | — | — | — | Restore edilebilir gerçek SQL adayı bulunmadı |

## Hâlâ Bulunamayanlar
| Version | Durum | Sonraki öneri |
|---|---|---|
| `20260515133138` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260515133207` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260515144203` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260515144919` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260515155342` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516061601` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516061848` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516062016` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516070305` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516072004` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260516074319` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518061541` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518062116` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518094023` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518095042` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518095331` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518130718` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518130830` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260518145644` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260520131128` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260520133611` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260520133814` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260521143020` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260523070533` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260523070554` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260523070613` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260523070655` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260523070730` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260601135822` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260601140042` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |
| `20260605150838` | Bulunamadı | Supabase dashboard/history, audit log veya backup/export kontrolü |

## GitHub Actions Bulguları
| Run/Workflow | Tarih | Bulgu | Migration ilişkisi |
|---|---|---|---|
| `gh run list --limit 1000` | 2026-06-09 | 570 run listelendi | Liste 2026-06-02'ye ve bazı eski main run'lara kadar indi; Mayıs remote-only penceresindeki ayrıntılı run'lar görünmedi |
| `27022995217` / Personel Quality | 2026-06-05 | `20260603000011_user_profiles_social_links.sql` added | Local-only migration; remote-only timestamp değil |
| `27022995201` / Web Quality | 2026-06-05 | `20260603000011_user_profiles_social_links.sql` added | Local-only migration; remote-only timestamp değil |
| `27022995165` / Mobile Quality | 2026-06-05 | `20260603000011_user_profiles_social_links.sql` added | Local-only migration; remote-only timestamp değil |
| `27009304715/714/710` | 2026-06-05 | `20260603000010_fix_estimate_email_segment_v1.sql` added | Local-only migration; remote-only timestamp değil |
| `27000998874/823/787` | 2026-06-05 | `20260603000009_marketing_automations_rls_owner_claims.sql` added | Local-only migration; remote-only timestamp değil |
| `26934886865/854/848` | 2026-06-04 | `20260603000008_menu_ocr_engine_deepseek.sql` added | Local-only migration; remote-only timestamp değil |
| `26888435080/933/899` | 2026-06-03 | `20260603000007_business_slug_columns.sql` added | Local-only migration; remote-only timestamp değil |
| `26880643226/157/151` | 2026-06-03 | `20260603000006_business_busy_hours_rpc.sql` added | Local-only migration; remote-only timestamp değil |
| `26880491708/581/544` | 2026-06-03 | `20260603000005_analytics_events_busy_hours_indexes.sql` added | Local-only migration; remote-only timestamp değil |
| `26879040578/571/537` | 2026-06-03 | `20260603000004_search_nearby_v3_extend_returns.sql` added | Local-only migration; remote-only timestamp değil |
| `26874229396/338/237` | 2026-06-03 | `20260603000001/2/3` price level files added | Local-only migrations; remote-only timestamp değil |

## Lokal Yedek Bulguları
| Konum | Bulgu | Migration ilişkisi |
|---|---|---|
| `C:\yeedoy` | Aktif repo | Remote-only SQL içeriği yok |
| `D:\yeedoy` | Ayrı/eski repo kopyası bulundu; `main...origin/main` durumunda | Aktif migration klasöründe ve git history/reflog aramasında remote-only timestamp yok |
| `C:\Users\Mustafa\Downloads` | `yeedoy_logo_assets.zip`, `PTS*.zip` bulundu | Migration ilişkisi yok |
| `C:\Users\Mustafa\Desktop` | `xmlconverter` build arşivi bulundu | Migration ilişkisi yok |
| `C:\Users\Mustafa\.codex` | Remote-only timestamp arandı | Eşleşme yok |

## Supabase Dashboard Manuel Kontrol Listesi
- [ ] SQL Editor history kontrol edildi
- [ ] Database logs kontrol edildi
- [ ] Backup/export kontrol edildi
- [ ] Support/history seçeneği değerlendirildi

## Risk
- Yanlış dosya eşleştirme riski: Şu an restore adayı bulunmadığı için yanlış dosya eklenmedi. İleride aday bulunursa version, tarih, SQL içeriği ve remote schema etkisi birlikte doğrulanmalı.
- Eksik schema riski: 31 remote-only migration'ın gerçek SQL içeriği hâlâ bilinmiyor; local reset/schema production geçmişini temsil etmeyebilir.
- Production apply riski: Drift çözülmeden PR #95/#96 veya PR #94 migration apply denenirse beklenmeyen pending set veya schema farkı riski var.
- Marker/no-op riski: Gerçek SQL bulunmadan marker dosya oluşturmak migration list görünümünü temizleyebilir ama schema doğruluğunu sağlamaz.

## Önerilen Yol
1. Supabase Dashboard SQL Editor history, database logs ve backup/export kaynakları manuel kontrol edilsin.
2. Eğer dashboard/support üzerinden gerçek SQL içerikleri bulunursa aynı version filename ile repo'ya geri kazandırılsın.
3. Gerçek SQL bulunamazsa marker/no-op stratejisi ayrı bir PR ve açık karar kaydıyla değerlendirilsin.
4. PR #95/#96 production apply yalnızca drift planı netleştikten ve beklenen pending migration seti açıkça doğrulandıktan sonra ele alınsın.

## Kesinlikle Yapılmaması Gerekenler
- `supabase migration repair` kör çalıştırılmamalı
- `supabase db push` çalıştırılmamalı
- Marker/no-op dosyaları ayrı onay olmadan oluşturulmamalı
- PR #95/#96 production’a drift çözülmeden uygulanmamalı
- PR #94 production’a alias apply + smoke test olmadan uygulanmamalı
