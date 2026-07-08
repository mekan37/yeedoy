'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Sabitler ────────────────────────────────────────────────────────────────

const AVATAR_BUCKET = 'menu-media';
const HAKKINDA_MAX = 160;

const MUTFAKLAR = [
  'Türk Mutfağı', 'İtalyan Mutfağı', 'Çin Mutfağı', 'Japon Mutfağı',
  'Burger', 'Pizza', 'Deniz Ürünleri', 'Meksika Mutfağı',
  'Hint Mutfağı', 'Fransız Mutfağı', 'Akdeniz Mutfağı',
];
const DIYET_SECENEKLERI = [
  'Glutensiz', 'Vejetaryen', 'Vegan', 'Laktoz İçermez', 'Helal', 'Koşer',
];
const FIYAT_SEVIYELERI = ['₺', '₺₺', '₺₺₺', '₺₺₺₺'];
const CINSIYETLER = ['Belirtmek istemiyorum', 'Erkek', 'Kadın', 'Diğer'];

const NAV_SIDEBAR = [
  { href: '/profil',          label: 'Profilim' },
  { href: '/profil/settings', label: 'Profil Düzenle', active: true },
  { href: '/favoriler',       label: 'Favorilerim' },
  { href: '/onerilerim',      label: 'Önerilerim' },
  { href: '/gelen-kutusu',    label: 'Bildirimlerim' },
  { href: '/profil/settings', label: 'Ayarlar' },
  { href: '/yardim',          label: 'Yardım & Destek' },
];

// ── Yardımcılar ─────────────────────────────────────────────────────────────

function ChipTag({ label, onRemove }: { label: string; onRemove: () => void }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-border bg-cardAlt px-3 py-1.5 text-[13px] font-[700] text-textStrong">
      {label}
      <button
        type="button"
        onClick={onRemove}
        aria-label={`${label} kaldır`}
        className="flex h-4 w-4 items-center justify-center rounded-full bg-border text-muted hover:bg-danger/20 hover:text-danger transition-colors text-[10px] font-[900]"
      >
        ×
      </button>
    </span>
  );
}

function FormLabel({ htmlFor, children }: { htmlFor?: string; children: React.ReactNode }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-[13px] font-[900] text-textStrong">
      {children}
    </label>
  );
}

function InputBase({ className = '', ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={`w-full rounded-xl border border-border bg-bg px-4 py-3 text-[14px] font-[700] text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:cursor-not-allowed disabled:opacity-60 ${className}`}
    />
  );
}

function SelectBase({ className = '', ...props }: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      {...props}
      className={`w-full rounded-xl border border-border bg-bg px-4 py-3 text-[14px] font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30 ${className}`}
    />
  );
}

function SectionCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-border bg-card p-6 shadow-yd1">
      <h2 className="mb-5 text-[15px] font-[900] text-textStrong">{title}</h2>
      {children}
    </section>
  );
}

// ── Ana sayfa ────────────────────────────────────────────────────────────────

export default function ProfileSettingsPage() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);

  // Profil state
  const [userId, setUserId]           = useState<string | null>(null);
  const [email, setEmail]             = useState('');
  const [firstName, setFirstName]     = useState('');
  const [lastName, setLastName]       = useState('');
  const [username, setUsername]       = useState('');
  const [phone, setPhone]             = useState('');
  const [gender, setGender]           = useState('');
  const [birthDate, setBirthDate]     = useState('');
  const [hakkinda, setHakkinda]       = useState('');
  const [avatarUrl, setAvatarUrl]     = useState<string | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarUploading, setAvatarUploading] = useState(false);

  // Tercih state
  const [favMutfaklar, setFavMutfaklar]       = useState<string[]>([]);
  const [diyetTercihleri, setDiyetTercihleri] = useState<string[]>([]);
  const [fiyatTercihi, setFiyatTercihi]       = useState('');
  const [bildirimAktif, setBildirimAktif]     = useState(true);

  // Şifre state
  const [currentPass, setCurrentPass]   = useState('');
  const [newPass, setNewPass]           = useState('');
  const [newPassConfirm, setNewPassConfirm] = useState('');
  const [showPass, setShowPass]         = useState({ current: false, new: false, confirm: false });
  const [passError, setPassError]       = useState('');
  const [passSaving, setPassSaving]     = useState(false);

  // Genel state
  const [saving, setSaving]       = useState(false);
  const [saveError, setSaveError] = useState('');
  const [deletePhase, setDeletePhase] = useState<'idle' | 'confirm' | 'deleting' | 'done'>('idle');
  const [deleteError, setDeleteError] = useState('');

  // Profil yükle
  useEffect(() => {
    const sb = createSupabaseBrowserClient();
    sb.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setEmail(user.email ?? '');
      setUserId(user.id);
      const emailPrefix = (user.email ?? '').split('@')[0];
      setUsername(emailPrefix);

      (sb as any)
        .from('user_profiles')
        .select('display_name, bio, phone, avatar_url')
        .eq('user_id', user.id)
        .maybeSingle()
        .then(({ data }: { data: Record<string, unknown> | null }) => {
          if (!data) return;
          if (data.display_name) {
            const parts = (data.display_name as string).trim().split(' ');
            setFirstName(parts[0] ?? '');
            setLastName(parts.slice(1).join(' '));
          }
          if (data.bio)    setHakkinda(data.bio as string);
          if (data.phone)  setPhone(data.phone as string);
          if (data.avatar_url) setAvatarUrl(data.avatar_url as string);
        });
    });
  }, []);

  // Avatar yükle
  async function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file || !userId) return;
    if (file.size > 5 * 1024 * 1024) { toast('Dosya 5 MB\'dan küçük olmalı', 'danger'); return; }

    setAvatarPreview(URL.createObjectURL(file));
    setAvatarUploading(true);
    try {
      const sb = createSupabaseBrowserClient();
      const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg';
      const path = `user-avatars/${userId}.${ext}`;
      const { error: upErr } = await sb.storage
        .from(AVATAR_BUCKET)
        .upload(path, file, { upsert: true, contentType: file.type });
      if (upErr) throw upErr;
      const publicUrl = sb.storage.from(AVATAR_BUCKET).getPublicUrl(path).data.publicUrl;
      await (sb as any).from('user_profiles').update({ avatar_url: publicUrl }).eq('user_id', userId);
      setAvatarUrl(publicUrl);
      toast('Profil fotoğrafı güncellendi', 'success');
    } catch {
      setAvatarPreview(null);
      toast('Yükleme başarısız', 'danger');
    } finally {
      setAvatarUploading(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  }

  // Avatar kaldır
  async function handleRemoveAvatar() {
    if (!userId) return;
    setAvatarPreview(null);
    setAvatarUrl(null);
    const sb = createSupabaseBrowserClient();
    await (sb as any).from('user_profiles').update({ avatar_url: null }).eq('user_id', userId);
    toast('Fotoğraf kaldırıldı', 'success');
  }

  // Profil kaydet
  async function handleSave(e?: React.FormEvent) {
    e?.preventDefault();
    if (!userId) return;
    setSaving(true);
    setSaveError('');
    try {
      const sb = createSupabaseBrowserClient();
      const displayName = [firstName, lastName].filter(Boolean).join(' ').trim() || null;
      const { error: err } = await (sb as any)
        .from('user_profiles')
        .update({
          display_name: displayName,
          bio: hakkinda.trim() || null,
          phone: phone.replace(/\D/g, '') || null,
        })
        .eq('user_id', userId);
      if (err) throw err;
      toast('Profil kaydedildi', 'success');
      router.refresh();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Bir hata oluştu';
      setSaveError(msg);
      toast(msg, 'danger');
    } finally {
      setSaving(false);
    }
  }

  // Şifre değiştir
  async function handlePasswordChange() {
    if (!newPass || !currentPass) { setPassError('Tüm alanları doldurun.'); return; }
    if (newPass !== newPassConfirm) { setPassError('Yeni şifreler eşleşmiyor.'); return; }
    if (newPass.length < 8) { setPassError('Şifre en az 8 karakter olmalıdır.'); return; }
    if (!/[A-Z]/.test(newPass)) { setPassError('Şifre en az bir büyük harf içermelidir.'); return; }
    if (!/[0-9]/.test(newPass)) { setPassError('Şifre en az bir rakam içermelidir.'); return; }

    setPassSaving(true);
    setPassError('');
    try {
      const sb = createSupabaseBrowserClient();
      const { error: signErr } = await sb.auth.signInWithPassword({ email, password: currentPass });
      if (signErr) { setPassError('Mevcut şifre hatalı.'); return; }
      const { error: updErr } = await sb.auth.updateUser({ password: newPass });
      if (updErr) throw updErr;
      toast('Şifre güncellendi', 'success');
      setCurrentPass(''); setNewPass(''); setNewPassConfirm('');
    } catch {
      setPassError('Şifre değiştirilemedi. Lütfen tekrar deneyin.');
    } finally {
      setPassSaving(false);
    }
  }

  // Hesap sil
  async function handleDeleteAccount() {
    setDeletePhase('deleting');
    setDeleteError('');
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
  const initials = firstName[0]?.toUpperCase() ?? email[0]?.toUpperCase() ?? 'K';

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
        <div className="flex gap-6 lg:items-start">

          {/* ── Sol sidebar ────────────────────────────────────────────── */}
          <aside className="hidden w-56 shrink-0 lg:block lg:sticky lg:top-20 lg:self-start space-y-3">
            <nav className="rounded-2xl border border-border bg-card shadow-yd1 overflow-hidden">
              {NAV_SIDEBAR.map(({ href, label, active }) => (
                <Link key={label} href={href}
                  className={`flex items-center gap-3 px-4 py-3 text-sm font-[800] border-b border-border last:border-0 transition-colors ${
                    active
                      ? 'bg-primary/8 text-primary'
                      : 'text-textStrong hover:bg-cardAlt hover:text-primary'
                  }`}>
                  {active && (
                    <span className="h-1.5 w-1.5 rounded-full bg-primary shrink-0" aria-hidden="true" />
                  )}
                  {label}
                </Link>
              ))}
              <button type="button"
                className="flex w-full items-center gap-3 px-4 py-3 text-sm font-[800] text-danger transition-colors hover:bg-danger/5">
                Çıkış Yap
              </button>
            </nav>

            {/* Premium card */}
            <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
              <div className="mb-1 flex items-center gap-2">
                <span className="text-lg" aria-hidden="true">👑</span>
                <p className="text-sm font-[900] text-amber-900">Yeedoy Premium</p>
              </div>
              <p className="mb-3 text-[12px] font-[700] leading-snug text-amber-700">
                Daha fazla ayrıcalık ve özel fırsatlar seni bekliyor!
              </p>
              <button type="button"
                className="flex h-9 w-full items-center justify-center rounded-xl border border-amber-300 bg-white text-[13px] font-[900] text-amber-700 transition hover:bg-amber-100">
                Premium&apos;a Geç
              </button>
            </div>
          </aside>

          {/* ── Ana içerik ─────────────────────────────────────────────── */}
          <div className="min-w-0 flex-1 space-y-5">

            {/* Sayfa başlığı + butonlar */}
            <div className="flex items-start justify-between gap-4">
              <div>
                <Link href="/profil" className="mb-2 inline-flex items-center gap-1.5 text-[13px] font-[800] text-muted hover:text-primary transition-colors">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/></svg>
                  Geri
                </Link>
                <h1 className="text-2xl font-[900] text-textStrong">Profil Düzenle</h1>
                <p className="mt-1 text-[13px] font-[700] text-muted">Bilgilerini güncelle ve deneyimini kişiselleştir.</p>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <Link href="/profil"
                  className="flex h-10 items-center rounded-xl border border-border bg-card px-5 text-[14px] font-[800] text-textStrong transition hover:border-primary/30 shadow-yd1">
                  İptal
                </Link>
                <button
                  type="button"
                  onClick={() => handleSave()}
                  disabled={saving}
                  className="flex h-10 items-center rounded-xl bg-primary px-5 text-[14px] font-[900] text-white shadow-sm transition hover:brightness-110 disabled:opacity-60">
                  {saving ? 'Kaydediliyor…' : 'Kaydet'}
                </button>
              </div>
            </div>

            {/* ── Profil Fotoğrafı ─────────────────────────────────── */}
            <div className="flex items-center gap-6 rounded-2xl border border-border bg-card p-6 shadow-yd1">
              {/* Avatar */}
              <div className="relative shrink-0">
                <div className="h-24 w-24 overflow-hidden rounded-full border-[3px] border-white shadow-yd2 bg-primary/10">
                  {displayAvatar ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={displayAvatar} alt="Profil" className="h-full w-full object-cover" />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-2xl font-[900] text-primary">{initials}</div>
                  )}
                  {avatarUploading && (
                    <div className="absolute inset-0 flex items-center justify-center rounded-full bg-black/40">
                      <span className="h-5 w-5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                    </div>
                  )}
                </div>
                {/* Kamera overlay */}
                <label htmlFor="avatar-input"
                  className="absolute bottom-0 right-0 flex h-7 w-7 cursor-pointer items-center justify-center rounded-full bg-primary shadow-sm transition hover:brightness-110">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                    <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
                    <circle cx="12" cy="13" r="4"/>
                  </svg>
                </label>
              </div>

              <div>
                <p className="text-[15px] font-[900] text-textStrong">Profil Fotoğrafı</p>
                <p className="mt-0.5 text-[12px] font-[700] text-muted">JPG, PNG veya WebP. Maks. 5MB.</p>
                <div className="mt-3 flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => fileRef.current?.click()}
                    disabled={avatarUploading}
                    className="inline-flex h-9 items-center gap-2 rounded-xl border border-border bg-bg px-4 text-[13px] font-[800] text-textStrong transition hover:border-primary/30 hover:text-primary disabled:opacity-50">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                    Fotoğraf Yükle
                  </button>
                  {(displayAvatar || avatarUrl) && (
                    <button
                      type="button"
                      onClick={handleRemoveAvatar}
                      className="inline-flex h-9 items-center gap-2 rounded-xl border border-danger/20 bg-danger/5 px-4 text-[13px] font-[800] text-danger transition hover:bg-danger/10">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/></svg>
                      Kaldır
                    </button>
                  )}
                </div>
              </div>
              <input
                id="avatar-input"
                ref={fileRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="sr-only"
                onChange={handleAvatarChange}
              />
            </div>

            {/* ── Kişisel Bilgiler ─────────────────────────────────── */}
            <SectionCard title="Kişisel Bilgiler">
              <form id="profile-form" onSubmit={handleSave} className="space-y-4">
                {/* Ad / Soyad */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <FormLabel htmlFor="firstName">Ad</FormLabel>
                    <InputBase id="firstName" type="text" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="Adınız" maxLength={50} />
                  </div>
                  <div>
                    <FormLabel htmlFor="lastName">Soyad</FormLabel>
                    <InputBase id="lastName" type="text" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Soyadınız" maxLength={50} />
                  </div>
                </div>

                {/* E-posta / Kullanıcı Adı */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <FormLabel htmlFor="email">E-posta</FormLabel>
                    <InputBase id="email" type="email" value={email} readOnly className="cursor-not-allowed opacity-60" />
                  </div>
                  <div>
                    <FormLabel htmlFor="username">Kullanıcı Adı</FormLabel>
                    <InputBase id="username" type="text" value={username} onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))} placeholder="kullaniciadi" maxLength={30} />
                    <p className="mt-1 text-[11px] font-[700] text-muted">Kullanıcı adın bağlantında görünecektir.</p>
                  </div>
                </div>

                {/* Telefon / Cinsiyet */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <FormLabel htmlFor="phone">Telefon</FormLabel>
                    <div className="flex gap-2">
                      {/* Ülke kodu */}
                      <div className="flex h-[46px] w-20 shrink-0 items-center gap-2 rounded-xl border border-border bg-bg px-3 text-[13px] font-[700] text-textStrong">
                        <span className="text-base" aria-hidden="true">🇹🇷</span>
                        <span className="text-muted">+90</span>
                      </div>
                      <InputBase
                        id="phone"
                        type="tel"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value.replace(/[^\d\s]/g, '').slice(0, 14))}
                        placeholder="532 123 45 67"
                        className="flex-1"
                      />
                    </div>
                  </div>
                  <div>
                    <FormLabel htmlFor="gender">Cinsiyet</FormLabel>
                    <SelectBase id="gender" value={gender} onChange={(e) => setGender(e.target.value)}>
                      <option value="">Seçin</option>
                      {CINSIYETLER.map((c) => <option key={c} value={c}>{c}</option>)}
                    </SelectBase>
                  </div>
                </div>

                {/* Doğum Tarihi / Hakkımda */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <FormLabel htmlFor="birthDate">Doğum Tarihi</FormLabel>
                    <div className="relative">
                      <InputBase
                        id="birthDate"
                        type="date"
                        value={birthDate}
                        onChange={(e) => setBirthDate(e.target.value)}
                        max={new Date(Date.now() - 13 * 365 * 86400000).toISOString().split('T')[0]}
                        className="[color-scheme:light]"
                      />
                    </div>
                  </div>
                  <div>
                    <div className="mb-1.5 flex items-center justify-between">
                      <FormLabel htmlFor="hakkinda">Hakkımda</FormLabel>
                      <span className={`text-[11px] font-[700] ${hakkinda.length > HAKKINDA_MAX * 0.9 ? 'text-warning' : 'text-muted'}`}>
                        {hakkinda.length}/{HAKKINDA_MAX}
                      </span>
                    </div>
                    <textarea
                      id="hakkinda"
                      value={hakkinda}
                      onChange={(e) => setHakkinda(e.target.value.slice(0, HAKKINDA_MAX))}
                      rows={3}
                      placeholder="Kendinizden kısaca bahsedin..."
                      className="w-full resize-none rounded-xl border border-border bg-bg px-4 py-3 text-[14px] font-[700] text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                    />
                    <p className="mt-0.5 text-[11px] font-[700] text-muted">Maks. {HAKKINDA_MAX} karakter</p>
                  </div>
                </div>

                {saveError && (
                  <div className="rounded-xl border border-danger/25 bg-danger/[0.08] px-4 py-3 text-[13px] font-[700] text-danger">
                    {saveError}
                  </div>
                )}
              </form>
            </SectionCard>

            {/* ── Tercihlerim ──────────────────────────────────────── */}
            <SectionCard title="Tercihlerim">
              <div className="space-y-5">
                {/* Favori Mutfaklar / Diyet Tercihleri */}
                <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                  <div>
                    <FormLabel>Favori Mutfaklar</FormLabel>
                    <div className="flex min-h-[46px] flex-wrap gap-2 rounded-xl border border-border bg-bg p-2.5">
                      {favMutfaklar.map((m) => (
                        <ChipTag key={m} label={m} onRemove={() => setFavMutfaklar((p) => p.filter((x) => x !== m))} />
                      ))}
                      <select
                        value=""
                        onChange={(e) => { if (e.target.value && !favMutfaklar.includes(e.target.value)) setFavMutfaklar((p) => [...p, e.target.value]); }}
                        className="h-8 min-w-[90px] cursor-pointer rounded-lg border border-dashed border-border bg-transparent px-2 text-[12px] font-[700] text-muted focus:outline-none">
                        <option value="">+ Ekle</option>
                        {MUTFAKLAR.filter((m) => !favMutfaklar.includes(m)).map((m) => <option key={m} value={m}>{m}</option>)}
                      </select>
                    </div>
                  </div>
                  <div>
                    <FormLabel>Diyet Tercihleri</FormLabel>
                    <div className="flex min-h-[46px] flex-wrap gap-2 rounded-xl border border-border bg-bg p-2.5">
                      {diyetTercihleri.map((d) => (
                        <ChipTag key={d} label={d} onRemove={() => setDiyetTercihleri((p) => p.filter((x) => x !== d))} />
                      ))}
                      <select
                        value=""
                        onChange={(e) => { if (e.target.value && !diyetTercihleri.includes(e.target.value)) setDiyetTercihleri((p) => [...p, e.target.value]); }}
                        className="h-8 min-w-[90px] cursor-pointer rounded-lg border border-dashed border-border bg-transparent px-2 text-[12px] font-[700] text-muted focus:outline-none">
                        <option value="">+ Ekle</option>
                        {DIYET_SECENEKLERI.filter((d) => !diyetTercihleri.includes(d)).map((d) => <option key={d} value={d}>{d}</option>)}
                      </select>
                    </div>
                  </div>
                </div>

                {/* Fiyat Tercihi / Bildirim */}
                <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                  <div>
                    <FormLabel>Fiyat Tercihi</FormLabel>
                    <div className="flex gap-2">
                      {FIYAT_SEVIYELERI.map((f) => (
                        <button
                          key={f}
                          type="button"
                          onClick={() => setFiyatTercihi(f === fiyatTercihi ? '' : f)}
                          className={`flex h-11 flex-1 items-center justify-center rounded-xl border text-[14px] font-[900] transition ${
                            fiyatTercihi === f
                              ? 'border-primary bg-primary text-white shadow-sm'
                              : 'border-border bg-bg text-textStrong hover:border-primary/30'
                          }`}>
                          {f}
                        </button>
                      ))}
                    </div>
                  </div>
                  <div>
                    <FormLabel>Bildirim Tercihleri</FormLabel>
                    <label className="flex cursor-pointer items-start gap-3 rounded-xl border border-border bg-bg p-3.5 transition hover:border-primary/30">
                      <input
                        type="checkbox"
                        checked={bildirimAktif}
                        onChange={(e) => setBildirimAktif(e.target.checked)}
                        className="mt-0.5 h-4 w-4 shrink-0 accent-primary"
                      />
                      <span className="text-[13px] font-[700] leading-snug text-textStrong">
                        Kampanya, duyuru ve yeni mekan bildirimleri almak istiyorum.
                      </span>
                    </label>
                  </div>
                </div>
              </div>
            </SectionCard>

            {/* ── Şifre Değiştir ───────────────────────────────────── */}
            <SectionCard title="Şifre Değiştir">
              <div className="space-y-4">
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                  {/* Mevcut Şifre */}
                  <div>
                    <FormLabel htmlFor="currentPass">Mevcut Şifre</FormLabel>
                    <InputBase
                      id="currentPass"
                      type={showPass.current ? 'text' : 'password'}
                      value={currentPass}
                      onChange={(e) => setCurrentPass(e.target.value)}
                      placeholder="Mevcut şifreyi gir"
                    />
                  </div>
                  {/* Yeni Şifre */}
                  <div>
                    <FormLabel htmlFor="newPass">Yeni Şifre</FormLabel>
                    <div className="relative">
                      <InputBase
                        id="newPass"
                        type={showPass.new ? 'text' : 'password'}
                        value={newPass}
                        onChange={(e) => setNewPass(e.target.value)}
                        placeholder="Yeni şifreyi gir"
                        className="pr-10"
                      />
                      <button type="button" onClick={() => setShowPass((p) => ({ ...p, new: !p.new }))}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong">
                        <EyeIcon open={showPass.new} />
                      </button>
                    </div>
                  </div>
                  {/* Yeni Şifre Tekrar */}
                  <div>
                    <FormLabel htmlFor="newPassConfirm">Yeni Şifre (Tekrar)</FormLabel>
                    <div className="relative">
                      <InputBase
                        id="newPassConfirm"
                        type={showPass.confirm ? 'text' : 'password'}
                        value={newPassConfirm}
                        onChange={(e) => setNewPassConfirm(e.target.value)}
                        placeholder="Yeni şifreyi tekrar gir"
                        className="pr-10"
                      />
                      <button type="button" onClick={() => setShowPass((p) => ({ ...p, confirm: !p.confirm }))}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-textStrong">
                        <EyeIcon open={showPass.confirm} />
                      </button>
                    </div>
                  </div>
                </div>

                {passError && (
                  <p className="text-[13px] font-[700] text-danger">{passError}</p>
                )}

                <div className="flex items-center gap-3">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0 text-muted" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  <p className="text-[12px] font-[700] text-muted">
                    Şifren en az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir.
                  </p>
                </div>

                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={handlePasswordChange}
                    disabled={passSaving || !currentPass || !newPass || !newPassConfirm}
                    className="flex h-10 items-center rounded-xl bg-primary px-5 text-[14px] font-[900] text-white shadow-sm transition hover:brightness-110 disabled:opacity-40">
                    {passSaving ? 'Güncelleniyor…' : 'Şifreyi Güncelle'}
                  </button>
                </div>
              </div>
            </SectionCard>

            {/* ── Hesabımı Sil ─────────────────────────────────────── */}
            <div className="flex items-center justify-between gap-6 rounded-2xl border border-border bg-card p-6 shadow-yd1">
              <div>
                <h2 className="text-[15px] font-[900] text-textStrong">Hesabımı Sil</h2>
                <p className="mt-0.5 text-[13px] font-[700] text-muted">Hesabını silmek istediğinde tüm verilerin kalıcı olarak silinir.</p>
                {deleteError && <p className="mt-2 text-[13px] font-[700] text-danger">{deleteError}</p>}
                {deletePhase === 'done' && <p className="mt-2 text-[13px] font-[700] text-success">Hesabınız silindi. Yönlendiriliyorsunuz…</p>}
              </div>

              {deletePhase === 'idle' && (
                <button
                  type="button"
                  onClick={() => setDeletePhase('confirm')}
                  className="shrink-0 flex h-10 items-center rounded-xl border border-danger/30 bg-white px-5 text-[14px] font-[900] text-danger shadow-sm transition hover:bg-danger/5">
                  Hesabımı Sil
                </button>
              )}
              {deletePhase === 'confirm' && (
                <div className="flex shrink-0 flex-col items-end gap-2">
                  <p className="text-right text-[13px] font-[800] text-danger">Bu işlem geri alınamaz. Emin misin?</p>
                  <div className="flex gap-2">
                    <button onClick={() => { setDeletePhase('idle'); setDeleteError(''); }}
                      className="flex h-9 items-center rounded-xl border border-border bg-card px-4 text-[13px] font-[700] text-textStrong hover:bg-cardAlt">
                      Vazgeç
                    </button>
                    <button onClick={handleDeleteAccount}
                      className="flex h-9 items-center rounded-xl bg-danger px-4 text-[13px] font-[800] text-white hover:brightness-95">
                      Evet, Sil
                    </button>
                  </div>
                </div>
              )}
              {deletePhase === 'deleting' && (
                <p className="shrink-0 text-[13px] font-[700] text-muted">Siliniyor…</p>
              )}
            </div>

          </div>
        </div>
      </div>
    </main>
  );
}

// ── Göz ikonu ────────────────────────────────────────────────────────────────

function EyeIcon({ open }: { open: boolean }) {
  return open ? (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/>
    </svg>
  ) : (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
    </svg>
  );
}
