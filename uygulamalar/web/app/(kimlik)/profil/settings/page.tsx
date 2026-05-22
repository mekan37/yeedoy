'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { TR_ILLER, TR_ILCELER } from '@/src/lib/tr-ilceler';
import { toast } from '@/src/lib/toast-deposu';

const BIO_MAX = 280;

function formatPhone(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 4) return digits;
  if (digits.length <= 7) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
  if (digits.length <= 9) return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7, 9)} ${digits.slice(9, 11)}`;
}

export default function ProfileSettingsPage() {
  const router = useRouter();
  const [userId, setUserId] = useState<string | null>(null);
  const [displayName, setDisplayName] = useState('');
  const [bio, setBio] = useState('');
  const [phone, setPhone] = useState('');
  const [city, setCity] = useState('');
  const [district, setDistrict] = useState('');
  const [email, setEmail] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deletePhase, setDeletePhase] = useState<'idle' | 'confirm' | 'deleting' | 'done'>('idle');
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const districts = city ? (TR_ILCELER[city] ?? []) : [];

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setEmail(user.email ?? '');
      setUserId(user.id);
      (supabase as any)
        .from('user_profiles')
        .select('display_name, bio, phone, city, district')
        .eq('id', user.id)
        .maybeSingle()
        .then(({ data }: { data: Record<string, string | null> | null }) => {
          if (!data) return;
          if (data.display_name) setDisplayName(data.display_name);
          if (data.bio) setBio(data.bio);
          if (data.phone) setPhone(formatPhone(data.phone));
          if (data.city) setCity(data.city);
          if (data.district) setDistrict(data.district);
        });
    });
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!userId) return;
    setSaving(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { error: err } = await (supabase as any)
        .from('user_profiles')
        .update({
          display_name: displayName.trim() || null,
          bio: bio.trim() || null,
          phone: phone.replace(/\s/g, '') || null,
          city: city || null,
          district: district || null,
        })
        .eq('id', userId);
      if (err) throw err;
      toast('Profil kaydedildi', 'success');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Bir hata oluştu';
      setError(msg);
      toast(msg, 'danger');
    } finally {
      setSaving(false);
    }
  }

  async function handleDeleteAccount() {
    setDeletePhase('deleting');
    setDeleteError(null);
    try {
      const res = await fetch('/sunucu/hesap/sil', { method: 'POST' });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? 'Hesap silinemedi');
      setDeletePhase('done');
      setTimeout(() => router.push('/'), 2500);
    } catch (err: unknown) {
      setDeleteError(err instanceof Error ? err.message : 'Bir hata oluştu');
      setDeletePhase('confirm');
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
          ← Profilime Dön
        </Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Profil Ayarları</h1>

        {/* Profil formu */}
        <form onSubmit={handleSave} className="flex flex-col gap-5 rounded-[24px] border border-border bg-card p-6 shadow-yd1">
          <div>
            <label htmlFor="displayName" className="mb-1.5 block text-sm font-[900] text-textStrong">Görünen Ad</label>
            <input
              id="displayName"
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              maxLength={80}
              placeholder="Adınız"
              className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>

          <div>
            <div className="mb-1.5 flex items-center justify-between">
              <label htmlFor="bio" className="text-sm font-[900] text-textStrong">Hakkımda</label>
              <span className={`text-xs font-[700] ${bio.length > BIO_MAX * 0.9 ? 'text-warning' : 'text-muted'}`}>
                {bio.length}/{BIO_MAX}
              </span>
            </div>
            <textarea
              id="bio"
              value={bio}
              onChange={(e) => setBio(e.target.value.slice(0, BIO_MAX))}
              rows={3}
              placeholder="Kendinizden kısaca bahsedin..."
              className="w-full resize-none rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>

          <div>
            <label htmlFor="phone" className="mb-1.5 block text-sm font-[900] text-textStrong">Telefon</label>
            <input
              id="phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(formatPhone(e.target.value))}
              maxLength={14}
              placeholder="0532 123 45 67"
              className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="city" className="mb-1.5 block text-sm font-[900] text-textStrong">İl</label>
              <select
                id="city"
                value={city}
                onChange={(e) => { setCity(e.target.value); setDistrict(''); }}
                className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                <option value="">Seçin</option>
                {TR_ILLER.map((il) => <option key={il} value={il}>{il}</option>)}
              </select>
            </div>
            <div>
              <label htmlFor="district" className="mb-1.5 block text-sm font-[900] text-textStrong">İlçe</label>
              <select
                id="district"
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                disabled={!city}
                className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-50"
              >
                <option value="">Seçin</option>
                {districts.map((ilce) => <option key={ilce} value={ilce}>{ilce}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-[700] text-muted">E-posta (değiştirilemez)</label>
            <input
              type="email"
              value={email}
              readOnly
              className="w-full cursor-not-allowed rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-muted"
            />
          </div>

          {error && (
            <div className="rounded-2xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-sm font-[700] text-danger">{error}</div>
          )}

          <button
            type="submit"
            disabled={saving}
            className="inline-flex min-h-[52px] items-center justify-center rounded-2xl text-sm font-[900] text-white disabled:opacity-60"
            style={{ background: 'var(--yd-gradient-primary)' }}
          >
            {saving ? 'Kaydediliyor…' : 'Kaydet'}
          </button>
        </form>

        {/* Şifre Değiştir */}
        <section className="mt-6 rounded-[24px] border border-border bg-card p-6">
          <h2 className="mb-2 text-base font-[900] text-textStrong">Şifre</h2>
          <p className="mb-4 text-sm text-muted">Şifrenizi değiştirmek için sıfırlama e-postası gönderin.</p>
          <Link
            href="/sifremi-unuttum"
            className="inline-flex min-h-11 items-center gap-2 rounded-2xl border border-border bg-bg px-4 text-sm font-[800] text-textStrong hover:border-primary/30"
          >
            Şifre Sıfırlama E-postası Gönder
          </Link>
        </section>

        {/* KVKK */}
        <section className="mt-6 rounded-[24px] border border-border bg-card p-6">
          <h2 className="mb-3 text-base font-[900] text-textStrong">Veri Gizliliği (KVKK)</h2>
          <p className="mb-4 text-sm leading-relaxed text-muted">
            Yeedoy, 6698 sayılı KVKK ve GDPR kapsamında kişisel verilerinizi işlemektedir.
          </p>
          <div className="flex flex-wrap gap-3">
            <Link href="/yasal" className="text-xs font-[800] text-primary underline-offset-2 hover:underline">Gizlilik Politikası</Link>
            <a href="mailto:kvkk@yeedoy.com?subject=Veri%20Talebi" className="text-xs font-[800] text-primary underline-offset-2 hover:underline">Veri erişim / düzeltme talebi</a>
          </div>
        </section>

        {/* Hesap Silme */}
        <section className="mt-6 rounded-[24px] border border-danger/20 bg-danger/[0.04] p-6">
          <h2 className="mb-2 text-base font-[900] text-danger">Hesabı Sil</h2>
          <p className="mb-4 text-sm leading-relaxed text-muted">Hesabınızı sildiğinizde kişisel verileriniz kalıcı olarak kaldırılır.</p>

          {deletePhase === 'idle' && (
            <button onClick={() => setDeletePhase('confirm')} className="rounded-xl border border-danger/30 bg-danger/[0.08] px-4 py-2.5 text-sm font-[800] text-danger transition-colors hover:bg-danger/[0.14]">
              Hesabımı Sil
            </button>
          )}
          {deletePhase === 'confirm' && (
            <div className="flex flex-col gap-3">
              <p className="text-sm font-[800] text-danger">Bu işlem geri alınamaz. Devam etmek istiyor musunuz?</p>
              {deleteError && <p className="text-sm text-danger">{deleteError}</p>}
              <div className="flex gap-2">
                <button onClick={handleDeleteAccount} className="rounded-xl bg-danger px-4 py-2.5 text-sm font-[800] text-white hover:brightness-95">Evet, Hesabımı Sil</button>
                <button onClick={() => { setDeletePhase('idle'); setDeleteError(null); }} className="rounded-xl border border-border bg-card px-4 py-2.5 text-sm font-[700] text-textStrong">Vazgeç</button>
              </div>
            </div>
          )}
          {deletePhase === 'deleting' && <p className="text-sm font-[700] text-muted">Hesabınız siliniyor…</p>}
          {deletePhase === 'done' && <p className="text-sm font-[700] text-success">Hesabınız silindi. Yönlendiriliyorsunuz…</p>}
        </section>
      </div>
    </main>
  );
}
