/**
 * E-posta kampanyası gövdesi için düz metin temizleme ve HTML'e güvenli
 * gömme yardımcıları.
 *
 * Sıra kritik: önce HTML entity'lerini decode et (`&amp;lt;script&amp;gt;`
 * gibi çift kodlanmış girdilerin arkasına gizlenmiş etiketleri ortaya
 * çıkarır), sonra etiketleri temizle. Decode-then-strip tek başına yeterli
 * DEĞİLDİR — çıktı, bir HTML şablon literaline her gömüldüğünde ayrıca
 * escapeHtml ile kaçılmalıdır (escape-at-output, decode-and-trust değil).
 * Böylece kullanıcının düz metin olarak yazdığı `&` veya `<` karakterleri de
 * doğru görüntülenir ve strip aşamasını atlatan uç durumlar zararsız kalır.
 */

export function stripHtml(input: string): string {
  const decoded = input
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
  return decoded.replace(/<[^>]*>/g, '');
}

export function escapeHtml(input: string): string {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
