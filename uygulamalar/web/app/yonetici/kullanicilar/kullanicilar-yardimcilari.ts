export interface KullaniciSatiri {
  id: string;
  displayName: string | null;
  email: string | null;
  phone: string | null;
  role: string;
  city: string | null;
  createdAt: string;
  lastSignInAt: string | null;
  isOwner: boolean;
  shadowBanned: boolean;
}

export const ROLE_MAP: Record<string, { label: string; className: string }> = {
  super_admin: { label: 'Süper Admin', className: 'bg-purple-100 text-purple-800' },
  admin: { label: 'Admin', className: 'bg-purple-50 text-purple-700' },
  community_mod: { label: 'Moderatör', className: 'bg-blue-50 text-blue-700' },
  user: { label: 'Kullanıcı', className: 'bg-zinc-100 text-zinc-500' },
};

export function kullanicilarCsvOlustur(rows: KullaniciSatiri[]): string {
  const basliklar = ['Ad', 'E-posta', 'Telefon', 'Rol', 'Şehir', 'Kayıt Tarihi', 'Son Giriş', 'Durum'];
  const satirlar = rows.map((r) => [
    r.displayName ?? '',
    r.email ?? '',
    r.phone ?? '',
    ROLE_MAP[r.role]?.label ?? r.role,
    r.city ?? '',
    new Date(r.createdAt).toLocaleDateString('tr-TR'),
    r.lastSignInAt ? new Date(r.lastSignInAt).toLocaleDateString('tr-TR') : '',
    r.shadowBanned ? 'Engellendi' : 'Aktif',
  ]);
  const kacis = (v: string) => `"${v.replace(/"/g, '""')}"`;
  return [basliklar, ...satirlar].map((satir) => satir.map(kacis).join(',')).join('\n');
}

export function yuzdeDegisim(bu: number, onceki: number): number {
  if (onceki === 0) return bu > 0 ? 100 : 0;
  return Math.round(((bu - onceki) / onceki) * 100);
}
