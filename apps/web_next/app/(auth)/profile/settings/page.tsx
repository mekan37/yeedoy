'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { createClient } from '@supabase/supabase-js';

function getSupabase() {
  return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
}

export default function ProfileSettingsPage() {
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [userId, setUserId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = getSupabase();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setEmail(user.email ?? '');
      setUserId(user.id);
      (supabase as any).from('user_profiles').select('display_name').eq('user_id', user.id).single()
        .then(({ data }: { data: { display_name: string | null } | null }) => {
          if (data?.display_name) setDisplayName(data.display_name);
        });
    });
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!userId) return;
    setSaving(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { error: err } = await (supabase as any).from('user_profiles').update({ display_name: displayName }).eq('user_id', userId);
      if (err) throw err;
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profile" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Profilime Dön</Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Profil Ayarları</h1>

        <form onSubmit={handleSave} className="flex flex-col gap-5 rounded-2xl border border-border bg-card p-6">
          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-[700] text-textStrong">Görünen Ad</label>
            <input
              type="text" value={displayName} onChange={(e) => setDisplayName(e.target.value)}
              placeholder="Adınız"
              className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-[700] text-muted">E-posta (değiştirilemez)</label>
            <input type="email" value={email} readOnly className="rounded-xl border border-border bg-bg px-4 py-3 text-sm text-muted cursor-not-allowed" />
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          {saved && <p className="text-sm font-[700] text-green-600">Kaydedildi!</p>}
          <button type="submit" disabled={saving} className="rounded-xl bg-primary px-4 py-3 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">
            {saving ? 'Kaydediliyor…' : 'Kaydet'}
          </button>
        </form>
      </div>
    </main>
  );
}
