## Özet
<!-- Ne değişti ve neden? 1-2 cümle -->

## Değişen Yüzeyler
<!-- Hangi app'ler ve modüller etkilendi? -->
- [ ] uygulamalar/mobil
- [ ] uygulamalar/web
- [ ] supabase/migrations
- [ ] supabase/functions
- [ ] packages/*
- [ ] .github/workflows
- [ ] docs/*

## Risk Seviyesi
<!-- LOW / MEDIUM / HIGH -->
**Risk:** 

**Gerekçe:** 

## Değişim Türü
- [ ] Yeni özellik (feature)
- [ ] Bug düzeltme (fix)
- [ ] Yeniden yapılandırma (refactor)
- [ ] Performans iyileştirmesi (perf)
- [ ] Test ekleme
- [ ] Dokümantasyon (docs-only)
- [ ] Bağımlılık güncellemesi (chore)

## Test Edilen Komutlar
```bash
# Örnek:
# cd uygulamalar/web && npm run typecheck && npm run lint
# cd uygulamalar/mobil && flutter analyze
```

## Test Edilmeyen Komutlar (Neden?)
<!-- Eğer birkaç kontrol yapılmadıysa açıkla -->

## Supabase Değişiklikleri
<!-- SADECE migration/edge function branch'leri için gerekli -->
- [ ] Yeni migration dosyası var (örn. `20260524000001_*.sql`)
- [ ] RPC signature değişti → etkilenen callerlar: 
- [ ] RLS policy değişti → etkilenen roller: 
- [ ] Yeni tablo/sütun eklendi → data migration gerekli mi?
- [ ] Edge Function auth değişti → test edildi mi?

## Davranış Değişiklikleri
- [ ] Public route davranışı değişti (SEO, cache, auth)
- [ ] Owner/admin panel davranışı değişti
- [ ] Auth/session akışı değişti
- [ ] API schema değişti (breaking?)

## Ekran Görüntüsü / Video
<!-- UI değişikliği varsa eklendi mi? Responsive test linki varsa ekle -->

## Rollback Planı
<!-- Bu PR'ı geri almak için ne yapılmalı? -->
Örnek:
- Migration: `supabase db reset` (lokal) veya `supabase migrations delete [version]`
- Code: `git revert` ve redeploy
- Config: restore `.env` veya previous deployment

## Checklist
- [ ] Commit mesajı conventional commit formatı (`type(scope): description`)
- [ ] Tests pass (CI logs gösteriliyor mu?)
- [ ] Hiç secret / API key / `.env` commit etmedim
- [ ] Generated dosya (`.next/`, `build/`, `.dart_tool/`) commit etmedim
- [ ] TypeScript / Dart code kalitesi kontrolleri pass
- [ ] L10n audit pass (eğer ARB dosyası değiştirdim)
- [ ] PR doğru branch'te mi? (`feature/*`, `fix/*`, `hotfix/*`, `migration/*`)

---

**İlgili Issue:** <!-- Closes #123 varsa yaz -->

**Ek Açıklamalar:**
<!-- Reviewer'lar için ekstra bağlam varsa yaz -->
