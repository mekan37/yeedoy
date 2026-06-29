# Remote-applied Supabase Migration Restore — 2026-06-09

## Özet
- Remote-only toplam: 31
- Git geçmişinde bulunan: 0
- Restore edilen: 0
- İçeriği bulunamayan: 31
- Çakışmalı olan: 0

Bu çalışma yalnızca local git/repo geçmişinde arama yaptı. Production migration, `supabase db push`, `supabase migration repair`, `supabase migration up`, `apply_migration`, production SQL veya remote migration history değiştiren bir işlem çalıştırılmadı.

Aranan kaynaklar:
- `git log --all --name-status -- supabase/migrations`
- `git log --all --diff-filter=D --name-status -- supabase/migrations`
- `git log --all --name-only -- supabase/migrations`
- `git rev-list --objects --all`
- `git log --walk-reflogs --all --name-status -- supabase/migrations`

## Restore Edilen Dosyalar
| Version | Dosya | Kaynak commit | Not |
|---|---|---|---|
| — | — | — | Restore edilebilen remote-only migration dosyası bulunamadı |

## Bulunamayanlar
| Version | Remote applied | Git geçmişinde bulundu mu | Öneri |
|---|---|---|---|
| `20260515133138` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260515133207` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260515144203` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260515144919` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260515155342` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516061601` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516061848` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516062016` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516070305` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516072004` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260516074319` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518061541` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518062116` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518094023` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518095042` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518095331` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518130718` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518130830` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260518145644` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260520131128` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260520133611` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260520133814` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260521143020` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260523070533` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260523070554` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260523070613` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260523070655` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260523070730` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260601135822` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260601140042` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |
| `20260605150838` | Evet | Hayır | Supabase dashboard/history, CI artifact, eski export veya ekip apply notlarından içerik aranmalı |

## Çakışmalı / Belirsizler
| Version | Aday dosyalar | Neden belirsiz | Öneri |
|---|---|---|---|
| — | — | Aynı version için birden fazla aday bulunmadı | — |

## Risk
- Yanlış içerik restore riski: Şu an restore yapılmadığı için yeni yanlış içerik eklenmedi. Asıl risk, ileride bu version'lar için tahmini veya placeholder SQL yazılmasıdır; bu yapılmamalı.
- Migration history riski: Remote history 31 version için local repo ile temsil edilmiyor. Bu durum çözülmeden normal `supabase db push` güvenilir kabul edilmemeli.
- Production apply riski: PR #95/#96 veya PR #94 migration'ları production'a uygulanmadan önce remote-only kayıtların schema etkisi ve local-only migrationların production karşılığı netleşmeli.

## Sonraki Adım
- PR açılabilir mi: Evet, bu rapor dokümantasyon PR'ı olarak açılabilir; migration dosyası restore etmez.
- `supabase db push --dry-run` ne zaman denenmeli: Remote-only migration içerikleri repo dışı kaynaklardan bulunup local repo'ya geri kazandırıldıktan veya bilinçli bir migration history planı yazılı olarak onaylandıktan sonra denenmeli.

Önerilen araştırma kaynakları:
1. Supabase dashboard migration/history kayıtları veya proje SQL audit logları.
2. CI/CD artifact'ları ve geçmiş deployment logları.
3. Ekip içi production apply notları.
4. Eski local çalışma kopyaları veya dış yedekler.
