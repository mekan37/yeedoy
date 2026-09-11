// Re-export shim — kanonik kaynak @/src/lib/sablonlar/sablon-kaydi.ts
// (Türkçe adlandırma projedeki kural). Bu dosyanın TR metinleri ASCII'ye
// düşürülmüş şekilde (ör. "odakli" yerine "odaklı") elle senkronize
// tutuluyordu — artık tek kaynaktan üretiliyor. proxy.ts gibi bu dosyayı
// import eden hot-path kod, değişiklik gerekmeden doğru Türkçe metni alır.
// Yeni kod doğrudan '@/src/lib/sablonlar/sablon-kaydi' import etmeli.
export * from '@/src/lib/sablonlar/sablon-kaydi';
