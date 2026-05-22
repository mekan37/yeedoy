export const PASSWORD_CRITERIA = [
  { id: 'length',  label: 'En az 8 karakter', test: (p: string) => p.length >= 8 },
  { id: 'upper',   label: 'Büyük harf',        test: (p: string) => /[A-ZÇĞİÖŞÜ]/.test(p) },
  { id: 'lower',   label: 'Küçük harf',        test: (p: string) => /[a-zçğışöü]/.test(p) },
  { id: 'digit',   label: 'Rakam',             test: (p: string) => /[0-9]/.test(p) },
  { id: 'special', label: 'Özel karakter',     test: (p: string) => /[^a-zA-Z0-9çğışöüÇĞİÖŞÜ]/.test(p) },
] as const;

export function getPasswordStrength(password: string) {
  const met = PASSWORD_CRITERIA.filter((c) => c.test(password)).length;
  if (met <= 2) return { level: 0, label: 'Zayıf', color: 'bg-red-500',    width: 'w-2/5' };
  if (met === 3) return { level: 1, label: 'Orta',  color: 'bg-yellow-400', width: 'w-3/5' };
  if (met === 4) return { level: 2, label: 'İyi',   color: 'bg-orange-400', width: 'w-4/5' };
  return               { level: 3, label: 'Güçlü', color: 'bg-green-500',  width: 'w-full' };
}

export function hataMesaji(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err ?? '');
  const lower = raw.toLowerCase();
  if (lower.includes('already registered') || lower.includes('already exists') || lower.includes('23505'))
    return 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.';
  if (lower.includes('invalid login') || lower.includes('invalid credentials') || lower.includes('wrong password'))
    return 'E-posta veya şifre hatalı.';
  if (lower.includes('email not confirmed'))
    return 'E-posta adresinizi doğrulamanız gerekiyor. Gelen kutunuzu kontrol edin.';
  if (lower.includes('rate limit') || lower.includes('too many'))
    return 'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyin.';
  if (lower.includes('network') || lower.includes('fetch'))
    return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
  if (lower.includes('weak password') || lower.includes('at least 6'))
    return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
  if (lower.includes('signup is disabled'))
    return 'Şu an yeni kayıtlar kapalıdır. Lütfen daha sonra tekrar deneyin.';
  return raw || 'Bir hata oluştu. Lütfen tekrar deneyin.';
}

export function formatPhone(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 4) return digits;
  if (digits.length <= 7) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
  if (digits.length <= 9) return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7, 9)} ${digits.slice(9, 11)}`;
}
