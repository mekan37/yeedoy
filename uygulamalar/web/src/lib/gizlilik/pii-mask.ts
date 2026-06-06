/**
 * PII maskeleme yardımcıları.
 * Bu modül kullanıcıya özel hassas verileri UI'da gizler.
 */

/**
 * Telefon numarasının yalnızca son 2 rakamını gösterir.
 * Tüm rakam dışı karakterler kaldırılır; kalan rakamlar '*' ile örtülür.
 *
 * Örnekler:
 *   05321234567   → *********67
 *   +905321234567 → ***********67
 *   null          → '—'
 */
export function maskPhone(phone: string | null | undefined): string {
  if (!phone) return '—';
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 2) return '—';
  const last2 = digits.slice(-2);
  const masked = '*'.repeat(digits.length - 2);
  return masked + last2;
}

/**
 * Serbest metin içindeki e-posta ve telefon örüntülerini maskeler.
 * Lead.message gibi alanlar için uygundur.
 */
export function maskMessage(text: string | null | undefined): string {
  if (!text) return '';
  // E-posta örüntüsünü maskele
  const maskedEmail = text.replace(/[\w.+-]+@[\w-]+\.[\w.]+/g, '[email]');
  // 10+ rakam içeren telefon örüntüsünü maskele
  const maskedPhone = maskedEmail.replace(/[\d\s\-().+]{10,}/g, '[telefon]');
  return maskedPhone;
}
