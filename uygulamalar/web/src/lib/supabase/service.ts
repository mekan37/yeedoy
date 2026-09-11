// Re-export shim — kanonik kaynak @/src/lib/taban/hizmet.ts (Türkçe adlandırma
// projedeki kural). İki dosya elle senkronize tutulan byte-byte bir kopyaydı
// (drift riski) — artık tek kaynaktan üretiliyor. Yeni kod doğrudan
// '@/src/lib/taban/hizmet' import etmeli, bu dosya yalnızca geriye dönük
// uyumluluk için var.
export { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
