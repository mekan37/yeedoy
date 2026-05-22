'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

const STEPS = ['İşletme Seç', 'Detaylar', 'Gönder'];

export default function GroupRequestNewPage() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [businessSlug, setBusinessSlug] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [targetDate, setTargetDate] = useState('');
  const [minParticipants, setMinParticipants] = useState('4');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    if (!businessSlug.trim() || !title.trim()) { setError('İşletme ve başlık zorunludur'); return; }
    setLoading(true); setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Oturum bulunamadı');
      const { data: biz } = await (supabase as any).from('businesses').select('id').eq('slug', businessSlug.trim()).single() as { data: { id: string } | null };
      if (!biz) throw new Error('İşletme bulunamadı');
      const { data: req, error: err } = await (supabase as any).from('group_requests').insert({
        creator_id: user.id, business_id: biz.id, title: title.trim(),
        description: description.trim() || null, target_date: targetDate || null,
        min_participants: parseInt(minParticipants) || 4, status: 'open', participant_count: 1,
      }).select('id').single() as { data: { id: string } | null; error: any };
      if (err) throw err;
      router.push(`/grup-istekleri/${req!.id}`);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally { setLoading(false); }
  }

  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/grup-istekleri" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Geri</Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Yeni Grup İsteği</h1>

        <div className="flex gap-2 mb-8">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center gap-2">
              <div className={`h-6 w-6 rounded-full flex items-center justify-center text-[11px] font-[900] ${i <= step ? 'bg-primary text-white' : 'bg-border text-muted'}`}>{i + 1}</div>
              {i < STEPS.length - 1 && <div className={`h-0.5 w-8 ${i < step ? 'bg-primary' : 'bg-border'}`} />}
            </div>
          ))}
        </div>

        <div className="rounded-2xl border border-border bg-card p-6">
          {step === 0 && (
            <div className="flex flex-col gap-4">
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">İşletme Slug <span className="text-red-500">*</span></label>
                <input value={businessSlug} onChange={e => setBusinessSlug(e.target.value)} placeholder="ör: kebapci-mehmet"
                  className="w-full rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
                <p className="mt-1 text-[11px] text-muted">İşletmenin Yeedoy URL&apos;sindeki slug&apos;ını girin</p>
              </div>
              <button onClick={() => { if (!businessSlug.trim()) { setError('İşletme slug zorunludur'); return; } setError(null); setStep(1); }}
                className="rounded-xl bg-primary py-3 text-sm font-[700] text-white cursor-pointer">Devam</button>
            </div>
          )}
          {step === 1 && (
            <div className="flex flex-col gap-4">
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">Başlık <span className="text-red-500">*</span></label>
                <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Ör: Cuma öğle yemeği organizasyonu"
                  className="w-full rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-[700] text-textStrong">Açıklama</label>
                <textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} placeholder="Detaylar…"
                  className="w-full rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30 resize-none" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1.5 block text-sm font-[700] text-textStrong">Hedef Tarih</label>
                  <input type="date" value={targetDate} onChange={e => setTargetDate(e.target.value)}
                    className="w-full rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30" />
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-[700] text-textStrong">Min. Katılımcı</label>
                  <input type="number" min="2" value={minParticipants} onChange={e => setMinParticipants(e.target.value)}
                    className="w-full rounded-xl border border-border bg-bg px-4 py-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30" />
                </div>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setStep(0)} className="rounded-xl border border-border px-4 py-3 text-sm font-[700] text-textStrong cursor-pointer">Geri</button>
                <button onClick={() => { setStep(2); submit(); }} disabled={loading || !title.trim()} className="flex-1 rounded-xl bg-primary py-3 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">
                  {loading ? 'Oluşturuluyor…' : 'Oluştur'}
                </button>
              </div>
            </div>
          )}
          {step === 2 && !error && (
            <div className="text-center py-4">
              <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full border border-green-200 bg-green-50 text-green-600"><svg viewBox="0 0 24 24" className="h-6 w-6 fill-none stroke-current" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg></div>
              <p className="font-[700] text-textStrong">Grup isteği oluşturuluyor…</p>
            </div>
          )}
          {error && <p className="text-sm text-red-600 mt-2">{error}</p>}
        </div>
      </div>
    </main>
  );
}

