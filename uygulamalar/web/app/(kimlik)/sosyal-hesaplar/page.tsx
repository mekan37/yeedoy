'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

// ── Platform definitions ──────────────────────────────────────────────────────
// Keys match social_links JSONB column in user_profiles
// (migration: 20260603000011_user_profiles_social_links.sql)

type SocialKey = 'instagram' | 'x' | 'tiktok' | 'youtube' | 'linkedin' | 'website';

type SocialLinks = Partial<Record<SocialKey, string>>;

const PLATFORMS: Array<{
  key: SocialKey;
  label: string;
  placeholder: string;
  color: string;
}> = [
  {
    key: 'instagram',
    label: 'Instagram',
    placeholder: 'https://instagram.com/kullanici_adi',
    color: '#E1306C',
  },
  {
    key: 'x',
    label: 'X (Twitter)',
    placeholder: 'https://x.com/kullanici_adi',
    color: '#000000',
  },
  {
    key: 'tiktok',
    label: 'TikTok',
    placeholder: 'https://tiktok.com/@kullanici_adi',
    color: '#010101',
  },
  {
    key: 'youtube',
    label: 'YouTube',
    placeholder: 'https://youtube.com/@kanal_adi',
    color: '#FF0000',
  },
  {
    key: 'linkedin',
    label: 'LinkedIn',
    placeholder: 'https://linkedin.com/in/kullanici_adi',
    color: '#0A66C2',
  },
  {
    key: 'website',
    label: 'Web Sitesi',
    placeholder: 'https://sizin-siteniz.com',
    color: '#7F1D1D',
  },
];

// ── Platform icon ─────────────────────────────────────────────────────────────

function PlatformDot({ color }: { color: string }) {
  return (
    <span
      className="inline-block h-2.5 w-2.5 shrink-0 rounded-full"
      style={{ backgroundColor: color }}
      aria-hidden="true"
    />
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

type ProfileRow = { social_links: SocialLinks | null };

export default function SosyalHesaplarPage() {
  const [userId, setUserId] = useState<string | null>(null);
  const [links, setLinks] = useState<SocialLinks>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setUserId(user.id);
      (supabase as any)
        .from('user_profiles')
        .select('social_links')
        .eq('user_id', user.id)
        .maybeSingle()
        .then(({ data }: { data: ProfileRow | null }) => {
          if (data?.social_links) {
            setLinks(data.social_links);
          }
          setLoading(false);
        });
    });
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!userId) return;
    setSaving(true);
    try {
      // Strip empty/whitespace-only values before saving
      const cleaned: SocialLinks = {};
      for (const key of Object.keys(links) as SocialKey[]) {
        const val = links[key]?.trim();
        if (val) cleaned[key] = val;
      }
      const supabase = createSupabaseBrowserClient();
      const { error } = await (supabase as any)
        .from('user_profiles')
        .update({ social_links: cleaned, updated_at: new Date().toISOString() })
        .eq('user_id', userId);
      if (error) throw error;
      setLinks(cleaned);
      toast('Sosyal hesaplar kaydedildi', 'success');
    } catch (err: unknown) {
      toast(err instanceof Error ? err.message : 'Kayıt başarısız', 'danger');
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto flex max-w-xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            href="/profil"
            className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary"
          >
            ← Profilime Dön
          </Link>
          <h1 className="text-xl font-black text-textStrong">Bağlı Sosyal Hesaplar</h1>
          <p className="mt-1 text-sm text-muted">
            Sosyal medya profillerinizi ekleyerek sayfanızı zenginleştirin.
          </p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <span className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
          </div>
        ) : (
          <form onSubmit={handleSave} className="flex flex-col gap-4">
            <div className="flex flex-col gap-4 rounded-2xl border border-border bg-card p-5">
              {PLATFORMS.map((platform) => (
                <div key={platform.key}>
                  <label
                    htmlFor={`social-${platform.key}`}
                    className="mb-1.5 flex items-center gap-2 text-sm font-black text-textStrong"
                  >
                    <PlatformDot color={platform.color} />
                    {platform.label}
                  </label>
                  <input
                    id={`social-${platform.key}`}
                    type="url"
                    value={links[platform.key] ?? ''}
                    onChange={(e) =>
                      setLinks((prev) => ({ ...prev, [platform.key]: e.target.value }))
                    }
                    placeholder={platform.placeholder}
                    className="w-full rounded-2xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                  />
                </div>
              ))}
            </div>

            <button
              type="submit"
              disabled={saving}
              className="inline-flex min-h-[52px] items-center justify-center rounded-2xl text-sm font-black text-white disabled:opacity-60"
              style={{ background: 'var(--yd-gradient-primary)' }}
            >
              {saving ? 'Kaydediliyor…' : 'Kaydet'}
            </button>
          </form>
        )}

        <div className="rounded-2xl border border-border bg-card px-5 py-4">
          <p className="text-xs leading-relaxed text-muted">
            Sosyal medya bağlantılarınız profilinizde görünür. Boş bıraktığınız alanlar
            kaydedilmez. Bilgileriniz üçüncü taraflarla paylaşılmaz.
          </p>
        </div>
      </div>
    </main>
  );
}
