-- Sadakat v1 — 20260810000006'da kaçırılan tek satır: trg_award_loyalty_on_review
-- de anon/authenticated'a EXECUTE hakkına sahipti (advisors ile doğrulandı).
-- Trigger fonksiyonu olduğu için doğrudan çağrılırsa Postgres zaten "trigger
-- functions can only be called as triggers" hatası verir (pratik istismar
-- riski neredeyse yok), ama tutarlılık ve advisor uyarısını kapatmak için
-- diğer 8 fonksiyonla aynı şekilde kilitleniyor.

REVOKE EXECUTE ON FUNCTION public.trg_award_loyalty_on_review() FROM anon, authenticated;
