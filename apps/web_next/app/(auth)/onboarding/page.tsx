'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@supabase/supabase-js';

const DIET_OPTIONS = ['Vegan', 'Vejetaryen', 'Glutensiz', 'Laktozsuz', 'Helal', 'Kısıtlama Yok'];
const CUISINE_OPTIONS = ['Türk Mutfağı', 'İtalyan', 'Uzak Doğu', 'Fast Food', 'Kahvaltı', 'Deniz Ürünleri', 'Et Dünyası', 'Vegan/Vejetaryen'];

const STEPS = ['Hoş Geldiniz', 'Diyet Tercihleri', 'Mutfak Tercihleri', 'Tamamlandı'];

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [diet, setDiet] = useState<string[]>([]);
  const [cuisines, setCuisines] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  function toggle<T>(arr: T[], item: T): T[] {
    return arr.includes(item) ? arr.filter(x => x !== item) : [...arr, item];
  }

  async function finish() {
    setSaving(true);
    try {
      const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await (supabase as any).from('user_preferences').upsert({ user_id: user.id, diet_labels: diet, preferred_cuisines: cuisines });
      }
      router.push('/discover');
    } catch { router.push('/discover'); }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-bg px-4">
      <div className="w-full max-w-lg">
        {/* Progress */}
        <div className="mb-8 flex items-center gap-2">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center gap-2">
              <div className={`h-7 w-7 rounded-full flex items-center justify-center text-xs font-[900] ${i <= step ? 'bg-primary text-white' : 'bg-border text-muted'}`}>{i + 1}</div>
              {i < STEPS.length - 1 && <div className={`h-0.5 w-8 ${i < step ? 'bg-primary' : 'bg-border'}`} />}
            </div>
          ))}
        </div>

        <div className="rounded-2xl border border-border bg-card p-8">
          {step === 0 && (
            <div className="text-center">
              <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-[var(--yd-color-primary-soft)]"><svg viewBox="0 0 24 24" className="h-7 w-7 text-primary" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M18 20V10"/><path d="M12 20V4"/><path d="M6 20v-6"/></svg></div>
              <h1 className="mb-2 text-2xl font-[900] text-textStrong">Yeedoy&apos;a Hoş Geldiniz!</h1>
              <p className="mb-8 text-sm text-muted">Size özel öneriler sunabilmemiz için birkaç tercih soracağız. 1 dakika sürer.</p>
              <button onClick={() => setStep(1)} className="rounded-xl bg-primary px-8 py-3 text-sm font-[700] text-white cursor-pointer">Başlayalım</button>
            </div>
          )}

          {step === 1 && (
            <div>
              <h2 className="mb-2 text-xl font-[900] text-textStrong">Diyet Tercihleriniz</h2>
              <p className="mb-6 text-sm text-muted">Uygulayan varsa seçin (birden fazla seçebilirsiniz)</p>
              <div className="flex flex-wrap gap-2 mb-8">
                {DIET_OPTIONS.map(d => (
                  <button key={d} onClick={() => setDiet(toggle(diet, d))}
                    className={`rounded-full px-4 py-2 text-sm font-[700] border transition-colors cursor-pointer ${diet.includes(d) ? 'bg-primary border-primary text-white' : 'bg-bg border-border text-textStrong hover:border-primary/30'}`}>
                    {d}
                  </button>
                ))}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setStep(0)} className="rounded-xl border border-border px-4 py-2.5 text-sm font-[700] text-textStrong cursor-pointer">Geri</button>
                <button onClick={() => setStep(2)} className="flex-1 rounded-xl bg-primary py-2.5 text-sm font-[700] text-white cursor-pointer">Devam</button>
              </div>
            </div>
          )}

          {step === 2 && (
            <div>
              <h2 className="mb-2 text-xl font-[900] text-textStrong">Favori Mutfaklarınız</h2>
              <p className="mb-6 text-sm text-muted">En çok hangi mutfakları seversiniz?</p>
              <div className="flex flex-wrap gap-2 mb-8">
                {CUISINE_OPTIONS.map(c => (
                  <button key={c} onClick={() => setCuisines(toggle(cuisines, c))}
                    className={`rounded-full px-4 py-2 text-sm font-[700] border transition-colors cursor-pointer ${cuisines.includes(c) ? 'bg-primary border-primary text-white' : 'bg-bg border-border text-textStrong hover:border-primary/30'}`}>
                    {c}
                  </button>
                ))}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setStep(1)} className="rounded-xl border border-border px-4 py-2.5 text-sm font-[700] text-textStrong cursor-pointer">Geri</button>
                <button onClick={() => { setStep(3); finish(); }} disabled={saving} className="flex-1 rounded-xl bg-primary py-2.5 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">Tamamla</button>
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="text-center">
              <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full border border-green-200 bg-green-50 text-green-600"><svg viewBox="0 0 24 24" className="h-7 w-7 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg></div>
              <h2 className="mb-2 text-xl font-[900] text-textStrong">Her şey hazır!</h2>
              <p className="text-sm text-muted">Tercihleriniz kaydedildi. Keşfetmeye başlayabilirsiniz.</p>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
