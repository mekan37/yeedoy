// JSON.stringify kaçırmaz: `<`, `>`, `&`, ve JS'te geçerli ama JSON'da
// olmayan satır ayırıcıları U+2028/U+2029. Bir schema.org alanına
// (business.name/description, ürün adı vb.) `</script><img onerror=...>`
// gibi bir değer girilirse ham JSON.stringify çıktısı script bloğunu erken
// kapatıp HTML/script enjekte edebilir. CSP (nonce'lu, unsafe-inline yok) şu
// an tek başına engelliyor — bu, ikinci savunma katmanı.
const LINE_SEPARATOR = String.fromCharCode(0x2028);
const PARAGRAPH_SEPARATOR = String.fromCharCode(0x2029);

export function jsonLd(value: unknown): string {
  return JSON.stringify(value)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
    .split(LINE_SEPARATOR).join('\\u2028')
    .split(PARAGRAPH_SEPARATOR).join('\\u2029');
}
