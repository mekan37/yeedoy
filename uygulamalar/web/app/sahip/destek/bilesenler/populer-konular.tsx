import Link from 'next/link';
import type { ReactNode } from 'react';
import { POPULER_KONULAR } from '../destek-yardimcilari';

const TONE_CLASSES = {
  red: 'bg-red-50 text-red-600',
  green: 'bg-emerald-50 text-emerald-600',
  teal: 'bg-teal-50 text-teal-600',
  purple: 'bg-violet-50 text-violet-600',
  blue: 'bg-blue-50 text-blue-600',
} as const;

const TONE_ICON: Record<(typeof POPULER_KONULAR)[number]['tone'], ReactNode> = {
  red: <ProfileIcon />,
  green: <MenuIcon />,
  teal: <QrIcon />,
  purple: <ChartIcon />,
  blue: <ChatIcon />,
};

export function PopulerKonular() {
  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="text-sm font-black text-textStrong">Popüler Konular</h2>
        <Link href="/destek" className="text-xs font-extrabold text-primary hover:underline">
          Tüm konuları görüntüle →
        </Link>
      </div>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {POPULER_KONULAR.map((konu) => (
          <Link
            key={konu.href}
            href={konu.href}
            className="group flex flex-col gap-2.5 rounded-2xl border border-border bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-md"
          >
            <span className={`flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES[konu.tone]}`}>
              {TONE_ICON[konu.tone]}
            </span>
            <div>
              <p className="text-sm font-bold text-textStrong">{konu.title}</p>
              <p className="mt-0.5 text-xs text-muted">{konu.description}</p>
            </div>
            <span className="mt-auto text-xs font-bold text-muted transition-colors group-hover:text-primary">→</span>
          </Link>
        ))}
      </div>
    </div>
  );
}

function ProfileIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /></svg>;
}
function MenuIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" /><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" /></svg>;
}
function QrIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><line x1="17" y1="17" x2="17" y2="17" /></svg>;
}
function ChartIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3v18h18" /><path d="M7 16v-4M12 16V8M17 16v-7" /></svg>;
}
function ChatIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></svg>;
}
