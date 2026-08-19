import { YeedoyLogo } from '@/src/ui/marka/yeedoy-logo';

interface Props {
  eyebrow: string;
  titleLine1: string;
  titleLine2: string;
  description: string;
  features: Array<{ icon: React.ReactNode; title: string; desc: string }>;
}

/** Giriş/kayıt sayfalarının sağ panelinde gösterilen, statik/dekoratif sahip paneli önizlemesi. */
export function IsletmePanelOnizleme({ eyebrow, titleLine1, titleLine2, description, features }: Props) {
  return (
    <div
      className="relative hidden flex-1 flex-col items-center justify-center gap-8 overflow-hidden px-10 py-14 lg:flex"
      style={{ background: 'linear-gradient(135deg, #fff5f5 0%, #fef2f2 50%, #fff8f0 100%)' }}
    >
      <div className="pointer-events-none absolute right-[-100px] top-[-100px] h-[420px] w-[420px] rounded-full bg-primary/5" />
      <div className="pointer-events-none absolute bottom-[-80px] left-[-80px] h-[320px] w-[320px] rounded-full bg-primary/4" />

      <div className="relative z-10 w-full max-w-[720px] text-center">
        <p className="text-xs font-extrabold uppercase tracking-[0.2em] text-muted">{eyebrow}</p>
        <h2 className="mt-3 text-3xl font-black leading-tight text-textStrong">
          {titleLine1}
          <br />
          <span className="text-primary">{titleLine2}</span>
        </h2>
        <p className="mx-auto mt-3 max-w-md text-sm leading-relaxed text-muted">{description}</p>
      </div>

      {/* Statik panel mockup'ı */}
      <div className="relative z-10 w-full max-w-[720px] overflow-hidden rounded-2xl border border-border bg-card shadow-yd3">
        {/* Mini topbar */}
        <div className="flex items-center gap-3 border-b border-border px-4 py-2.5">
          <YeedoyLogo size={16} />
          <span className="flex items-center gap-1 rounded-md border border-border bg-bg px-2 py-1 text-[10px] font-extrabold text-textStrong">
            No 18 Coffee Co. <ChevDown />
          </span>
          <span className="rounded-full bg-green-50 px-2 py-1 text-[9px] font-extrabold text-green-700">Onaylı İşletme</span>
          <div className="ml-auto flex items-center gap-2">
            <span className="hidden rounded-md border border-border px-2 py-1 text-[9px] font-extrabold text-textStrong sm:inline-flex">İşletme Sayfasını Gör</span>
            <span className="relative flex h-5 w-5 items-center justify-center rounded-md text-muted">
              <BellMini />
              <span className="absolute -right-0.5 -top-0.5 flex h-3 w-3 items-center justify-center rounded-full bg-primary text-[7px] font-black text-white">3</span>
            </span>
            <span className="h-5 w-5 rounded-full bg-primary/20" />
          </div>
        </div>

        <div className="flex">
          {/* Mini sidebar */}
          <div className="hidden w-[110px] shrink-0 border-r border-border p-2.5 sm:block">
            <div className="mb-2 flex items-center gap-1.5">
              <span className="h-6 w-6 shrink-0 rounded-md bg-primary/15" />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[8px] font-black text-textStrong">No 18 Coffee</span>
                <span className="block text-[7px] font-bold text-muted">Kafe</span>
              </span>
            </div>
            <div className="space-y-1">
              <div className="rounded bg-primary/10 px-1.5 py-1 text-[7px] font-extrabold text-primary">Genel Bakış</div>
              {['İşletme Bilgileri', 'Menü Yönetimi', 'Yorumlar', 'Ayarlar'].map((s) => (
                <div key={s} className="px-1.5 py-1 text-[7px] font-bold text-muted">{s}</div>
              ))}
            </div>
          </div>

          {/* Mini içerik */}
          <div className="flex-1 p-3">
            <p className="text-[10px] font-black text-textStrong">Merhaba Mustafa! 👋</p>
            <div className="mt-2 grid grid-cols-5 gap-1.5">
              {[
                { n: '12.480', l: 'Görüntülenme', c: 'bg-blue-50 text-blue-500' },
                { n: '1.248', l: 'Favori', c: 'bg-rose-50 text-rose-500' },
                { n: '86', l: 'Yorum', c: 'bg-violet-50 text-violet-500' },
                { n: '642', l: 'Yol Tarifi', c: 'bg-emerald-50 text-emerald-500' },
                { n: '312', l: 'Arama', c: 'bg-amber-50 text-amber-500' },
              ].map((s) => (
                <div key={s.l} className="rounded-lg border border-border p-1.5">
                  <span className={`mb-1 inline-block h-3 w-3 rounded ${s.c}`} />
                  <p className="text-[9px] font-black text-textStrong">{s.n}</p>
                  <p className="truncate text-[6px] font-bold text-muted">{s.l}</p>
                </div>
              ))}
            </div>
            <div className="mt-2 grid grid-cols-3 gap-1.5">
              <div className="col-span-2 rounded-lg border border-border p-2">
                <p className="mb-1 text-[7px] font-black text-textStrong">Görüntülenme Grafiği</p>
                <svg viewBox="0 0 200 40" className="h-8 w-full" preserveAspectRatio="none">
                  <polyline
                    points="0,30 30,18 60,24 90,10 120,20 150,8 180,14 200,4"
                    fill="none"
                    stroke="#dc2626"
                    strokeWidth="2"
                  />
                </svg>
              </div>
              <div className="rounded-lg border border-border p-2">
                <p className="mb-1 text-[7px] font-black text-textStrong">Son Aktiviteler</p>
                <div className="space-y-1">
                  <div className="h-1 w-full rounded bg-bg" />
                  <div className="h-1 w-4/5 rounded bg-bg" />
                  <div className="h-1 w-full rounded bg-bg" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Özellikler */}
      <div className="relative z-10 grid w-full max-w-[720px] grid-cols-3 gap-6">
        {features.map((f) => (
          <div key={f.title} className="flex items-start gap-3">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
              {f.icon}
            </span>
            <div>
              <p className="text-sm font-extrabold text-textStrong">{f.title}</p>
              <p className="mt-0.5 text-xs leading-relaxed text-muted">{f.desc}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function ChevDown() {
  return (
    <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9" /></svg>
  );
}

function BellMini() {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}
