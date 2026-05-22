'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { TR_ILLER, TR_ILCELER } from '@/src/lib/tr-ilceler';
import { toast } from '@/src/lib/toast-deposu';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

const BIO_MAX = 280;
const AVATAR_BUCKET = 'menu-media';

function formatPhone(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 4) return digits;
  if (digits.length <= 7) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
  if (digits.length <= 9) return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  return `${digits.slice(0, 4)} ${digits.slice(4, 7)} ${digits.slice(7, 9)} ${digits.slice(9, 11)}`;
}

export default function ProfileSettingsPage() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [displayName, setDisplayName] = useState('');
  const [bio, setBio] = useState('');
  const [phone, setPhone] = useState('');
  const [city, setCity] = useState('');
  const [district, setDistrict] = useState('');
  const [email, setEmail] = useState('');
  const [isPublic, setIsPublic] = useState(true);
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarUploading, setAvatarUploading] = useState(false);
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
        .select('display_name, bio, phone, city, district, is_public, avatar_url')
        .eq('user_id', user.id)
        .maybeSingle()
        .then(({ data }: { data: Record<string, unknown> | null }) => {
          if (!data) return;
          if (data.display_name) setDisplayName(data.display_name as string);
          if (data.bio) setBio(data.bio as string);
          if (data.phone) setPhone(formatPhone(data.phone as string));
          if (data.city) setCity(data.city as string);
          if (data.district) setDistrict(data.district as string);
          if (typeof data.is_public === 'boolean') setIsPublic(data.is_public);
          if (data.avatar_url) setAvatarUrl(data.avatar_url as string);
        });
    });
  }, []);

  async function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !userId) return;
    if (file.size > 3 * 1024 * 1024) { toast('Dosya 3 MB\'dan küçük olmalı', 'danger'); return; }

    // Local preview
    const objectUrl = URL.createObjectURL(file);
    setAvatarPreview(objectUrl);
    setAvatarUploading(true);

    try {
      const supabase = createSupabaseBrowserClient();
      const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg';
      const path = `user-avatars/${userId}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from(AVATAR_BUCKET)
        .upload(path, file, { upsert: true, contentType: file.type });
      if (upErr) throw upErr;

      const publicUrl = supabase.storage.from(AVATAR_BUCKET).getPublicUrl(path).data.publicUrl;
      await (supabase as any)
        .from('user_profiles')
        .update({ avatar_url: publicUrl })
        .eq('user_id', userId);
      setAvatarUrl(publicUrl);
      toast('Profil fotoğrafı güncellendi', 'success');
    } catch (err: unknown) {
      setAvatarPreview(null);
      toast(err instanceof Error ? err.message : 'Yükleme başarısız', 'danger');
    } finally {
      setAvatarUploading(false);
    }
  }

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
          is_public: isPublic,
        })
        .eq('user_id', userId);
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

  const displayAvatar = avatarPreview ?? (avatarUrl ? buildMenuImageUrl(avatarUrl, { width: 160, quality: 85 }) : null);
  const initials = displayName.trim()[0]?.toUpperCase() ?? email[0]?.toUpperCase() ?? 'K';

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profil" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary">
          ← Profilime Dön
        </Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Profil Ayarları</h1>

        {/* W-2: Avatar yükleme */}
        <div className="mb-6 flex items-center gap-5">
          <div className="relative">
            <div className="h-20 w-20 overflow-hidden rounded-full border-2 border-border bg-cardAlt">
              {displayAvatar ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={displayAvatar} alt="Profil" className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-2xl font-[900] text-primary">
                  {initials}
                </div>
              )}
            </div>
            {avatarUploading && (
              <div className="absolute inset-0 flex items-center justify-center rounded-full bg-black/40">
                <span className="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
              </div>
            )}
          </div>
          <div>
            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              disabled={avatarUploading}
              className="inline-flex min-h-10 items-center gap-2 rounded-2xl border border-border bg-bg px-4 text-sm font-[800] text-textStrong hover:border-primary/30 disabled:opacity-50"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="17 8 12 3 7 8"/>
                <line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
              {avatarUploading ? 'Yükleniyor…' : 'Fotoğraf Değiştir'}
            </button>
            <p className="mt-1.5 text-xs text-muted">JPG, PNG veya WebP · Maks 3 MB</p>
          </div>
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={handleAvatarChange}
          />
        </div>

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

          {/* W-21: Profil gizliliği */}
          <div className="flex items-center justify-between gap-4">
            <div>
              <p className="text-sm font-[900] text-textStrong">Profil Görünürlüğü</p>
              <p className="mt-0.5 text-xs text-muted">{isPublic ? 'Profiliniz herkese açık' : 'Profiliniz gizli'}</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={isPublic}
              onClick={() => setIsPublic((v) => !v)}
              className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full transition-colors ${isPublic ? 'bg-primary' : 'bg-border'}`}
            >
              <span className={`pointer-events-none absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${isPublic ? 'translate-x-5' : 'translate-x-0.5'}`} />
            </button>
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
