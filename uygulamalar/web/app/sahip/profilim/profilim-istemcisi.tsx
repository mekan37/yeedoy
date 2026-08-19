'use client';

import Link from 'next/link';
import { useActionState, useState } from 'react';
import { clsx } from 'clsx';
import { AvatarYukleme } from '@/app/(kimlik)/profil/avatar-yukleme';
import { GizlilikGuvenlikTab } from '@/app/sahip/ayarlar/sekmeler/gizlilik-guvenlik-sekmesi';
import { BildirimAyarlariTab } from '@/app/sahip/ayarlar/sekmeler/bildirim-ayarlari-sekmesi';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { updateKisiselBilgiler } from './profilim-islemleri';

type Sekme = 'kisisel' | 'isletme' | 'guvenlik' | 'bildirim';

const GENDER_ETIKETLERI: Record<string, string> = {
  erkek: 'Erkek',
  kadin: 'Kadın',
  belirtilmedi: 'Belirtmek istemiyorum',
};

export function ProfilimIstemcisi({
  user,
  profile,
  planTier,
  businessCount,
  notificationPrefs,
}: {
  user: { id: string; email: string; createdAt: string; lastSignInAt: string | null; emailConfirmed: boolean };
  profile: { displayName: string; avatarUrl: string | null; bio: string | null; phone: string | null; birthDate: string | null; gender: string | null };
  planTier: string | null;
  businessCount: number;
  notificationPrefs: Record<string, boolean>;
}) {
  const [sekme, setSekme] = useState<Sekme>('kisisel');
  const [state, action, pending] = useActionState(updateKisiselBilgiler, null);
  const [bioLen, setBioLen] = useState(profile.bio?.length ?? 0);

  const initials = profile.displayName.charAt(0).toUpperCase();

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-black tracking-tight text-textStrong">Profilim</h1>
        <p className="mt-1 text-sm text-muted">İşletme hesap bilgilerinizi görüntüleyin ve yönetin.</p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <div className="flex min-w-0 flex-col gap-4">
          {/* Kapak + kimlik */}
          <div className="overflow-hidden rounded-2xl border border-border bg-card">
            <div
              className="h-28 w-full sm:h-36"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626, #991b1b)' }}
            />
            <div className="flex flex-col gap-4 px-5 pb-5 sm:flex-row sm:items-end sm:justify-between">
              <div className="flex flex-col items-start gap-3 sm:flex-row sm:items-end">
                <div className="-mt-10 sm:-mt-12">
                  <AvatarYukleme userId={user.id} avatarUrl={profile.avatarUrl} displayName={profile.displayName} initials={initials} size="lg" />
                </div>
                <div className="pt-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-lg font-black text-textStrong">{profile.displayName}</p>
                    {user.emailConfirmed && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-extrabold text-emerald-700">
                        <CheckIcon /> Doğrulanmış
                      </span>
                    )}
                  </div>
                  <p className="text-xs font-bold text-muted">İşletme Sahibi</p>
                  <div className="mt-1.5 flex flex-wrap items-center gap-3 text-xs text-muted">
                    <span className="flex items-center gap-1"><MailIcon /> {user.email}</span>
                    {profile.phone && <span className="flex items-center gap-1"><PhoneIcon /> {profile.phone}</span>}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Sekmeler */}
          <div className="flex flex-wrap gap-1 border-b border-border">
            <TabButon active={sekme === 'kisisel'} onClick={() => setSekme('kisisel')}>Kişisel Bilgiler</TabButon>
            <TabButon active={sekme === 'isletme'} onClick={() => setSekme('isletme')}>İşletme Bilgileri</TabButon>
            <TabButon active={sekme === 'guvenlik'} onClick={() => setSekme('guvenlik')}>Güvenlik</TabButon>
            <TabButon active={sekme === 'bildirim'} onClick={() => setSekme('bildirim')}>Bildirim Tercihleri</TabButon>
          </div>

          {sekme === 'kisisel' && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <h2 className="mb-4 text-sm font-black text-textStrong">Kişisel Bilgiler</h2>
              <form action={action} className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <Alan label="Ad Soyad" htmlFor="display_name">
                  <input id="display_name" name="display_name" defaultValue={profile.displayName} required maxLength={100} className={INPUT_CLASS} />
                </Alan>
                <Alan label="E-posta" htmlFor="email">
                  <input id="email" value={user.email} disabled className={clsx(INPUT_CLASS, 'cursor-not-allowed opacity-60')} />
                </Alan>
                <Alan label="Telefon Numarası" htmlFor="phone">
                  <input id="phone" name="phone" type="tel" defaultValue={profile.phone ?? ''} maxLength={30} placeholder="+90 555 000 00 00" className={INPUT_CLASS} />
                </Alan>
                <Alan label="Pozisyon" htmlFor="pozisyon">
                  <input id="pozisyon" value="İşletme Sahibi" disabled className={clsx(INPUT_CLASS, 'cursor-not-allowed opacity-60')} />
                </Alan>
                <Alan label="Doğum Tarihi" htmlFor="birth_date">
                  <input id="birth_date" name="birth_date" type="date" defaultValue={profile.birthDate ?? ''} className={INPUT_CLASS} />
                </Alan>
                <Alan label="Cinsiyet" htmlFor="gender">
                  <select id="gender" name="gender" defaultValue={profile.gender ?? ''} className={INPUT_CLASS}>
                    <option value="">Belirtilmedi</option>
                    {Object.entries(GENDER_ETIKETLERI).map(([value, label]) => (
                      <option key={value} value={value}>{label}</option>
                    ))}
                  </select>
                </Alan>
                <div className="sm:col-span-2">
                  <label htmlFor="bio" className="mb-1.5 block text-xs font-bold text-muted">Hakkımda</label>
                  <textarea
                    id="bio"
                    name="bio"
                    defaultValue={profile.bio ?? ''}
                    maxLength={250}
                    rows={3}
                    onChange={(e) => setBioLen(e.target.value.length)}
                    className={clsx(INPUT_CLASS, 'resize-none')}
                  />
                  <p className="mt-1 text-right text-[11px] text-muted">{bioLen} / 250</p>
                </div>

                {state && 'error' in state && (
                  <p className="sm:col-span-2 rounded-xl bg-danger/10 px-3 py-2.5 text-sm font-bold text-danger">{state.error}</p>
                )}
                {state && 'success' in state && (
                  <p className="sm:col-span-2 rounded-xl bg-success/10 px-3 py-2.5 text-sm font-bold text-success">Bilgileriniz güncellendi.</p>
                )}

                <div className="sm:col-span-2">
                  <PanelActionButton type="submit" variant="primary" loading={pending}>
                    Değişiklikleri Kaydet
                  </PanelActionButton>
                </div>
              </form>
            </div>
          )}

          {sekme === 'isletme' && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <h2 className="mb-1 text-sm font-black text-textStrong">İşletme Bilgileri</h2>
              <p className="mb-4 text-sm text-muted">
                İşletme adı, adres, kategori, çalışma saatleri ve iletişim bilgileri Ayarlar sayfasından yönetilir.
              </p>
              <Link href="/sahip/ayarlar">
                <PanelActionButton variant="secondary">Ayarlara Git</PanelActionButton>
              </Link>
            </div>
          )}

          {sekme === 'guvenlik' && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <GizlilikGuvenlikTab />
            </div>
          )}

          {sekme === 'bildirim' && (
            <div className="rounded-2xl border border-border bg-card p-5">
              <BildirimAyarlariTab userId={user.id} initialPrefs={notificationPrefs} />
            </div>
          )}
        </div>

        {/* Sağ sidebar */}
        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Hesap Özeti</h3>
            <div className="flex flex-col gap-3 text-sm">
              {planTier && (
                <OzetSatiri icon={<CrownIcon />} label="Üyelik Türü" value={planTier === 'premium' ? 'Premium' : planTier === 'standard' ? 'Standart' : 'Ücretsiz'} />
              )}
              <OzetSatiri icon={<CalendarIcon />} label="Yeedoy'a Katılma" value={new Date(user.createdAt).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' })} />
              {user.lastSignInAt && (
                <OzetSatiri icon={<ClockIcon />} label="Son Giriş" value={`${new Date(user.lastSignInAt).toLocaleDateString('tr-TR')} ${new Date(user.lastSignInAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}`} />
              )}
              <OzetSatiri icon={<BuildingIcon />} label="Toplam İşletme" value={`${businessCount} ${businessCount === 1 ? 'İşletme' : 'İşletme'}`} />
            </div>
            <Link href="/sahip/ayarlar/plan">
              <PanelActionButton variant="primary" className="mt-4 w-full justify-center">Paketimi Yönet</PanelActionButton>
            </Link>
          </div>

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
            <div className="flex flex-col gap-1">
              <HizliIslem label="Profil Fotoğrafını Değiştir" onClick={() => setSekme('kisisel')} />
              <HizliIslem label="Şifre Değiştir" onClick={() => setSekme('guvenlik')} />
              <HizliIslemLink label="İki Adımlı Doğrulama" href="/profil/guvenlik" />
              <HizliIslemLink label="Oturumları Yönet" href="/profil/guvenlik" />
            </div>
          </div>

          <div className="rounded-2xl border border-danger/25 bg-danger/5 p-4">
            <h3 className="mb-1 text-sm font-black text-textStrong">Hesabımı Sil</h3>
            <p className="mb-3 text-[11px] text-muted">Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istiyorsanız devam edin.</p>
            <Link href="/profil/ayarlar">
              <PanelActionButton variant="danger" className="w-full justify-center">Hesabı Sil</PanelActionButton>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

const INPUT_CLASS = 'w-full rounded-xl border border-border bg-bg px-3 py-2.5 text-sm text-textStrong outline-hidden focus:border-primary focus:ring-2 focus:ring-primary/20';

function Alan({ label, htmlFor, children }: { label: string; htmlFor: string; children: React.ReactNode }) {
  return (
    <div>
      <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-bold text-muted">{label}</label>
      {children}
    </div>
  );
}

function TabButon({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'border-b-2 px-3 py-2.5 text-sm font-extrabold transition-colors',
        active ? 'border-primary text-primary' : 'border-transparent text-muted hover:text-textStrong',
      )}
    >
      {children}
    </button>
  );
}

function OzetSatiri({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-start gap-2.5">
      <span className="mt-0.5 shrink-0 text-primary">{icon}</span>
      <div className="min-w-0">
        <p className="text-[11px] text-muted">{label}</p>
        <p className="truncate text-xs font-extrabold text-textStrong">{value}</p>
      </div>
    </div>
  );
}

function HizliIslem({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-left transition-colors hover:bg-black/4">
      <span className="text-xs font-extrabold text-textStrong">{label}</span>
      <ChevronRightIcon />
    </button>
  );
}

function HizliIslemLink({ label, href }: { label: string; href: string }) {
  return (
    <Link href={href} className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4">
      <span className="text-xs font-extrabold text-textStrong">{label}</span>
      <ChevronRightIcon />
    </Link>
  );
}

function CheckIcon() {
  return <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>;
}
function MailIcon() {
  return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>;
}
function PhoneIcon() {
  return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.362 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.338 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
function CrownIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m2 20 2-11 5 5 3-8 3 8 5-5 2 11Z" /></svg>;
}
function CalendarIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /></svg>;
}
function ClockIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 3" /></svg>;
}
function BuildingIcon() {
  return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M9 22V12h6v10" /></svg>;
}
function ChevronRightIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted"><path d="m9 18 6-6-6-6" /></svg>;
}
