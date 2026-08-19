'use client';

import Link from 'next/link';
import { useState } from 'react';
import { clsx } from 'clsx';
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';
import { SadakatKurulumIstemcisi, type SadakatProgram } from './sadakat-kurulum-istemcisi';
import { SadakatTaramaIstemcisi } from './sadakat-tarama-istemcisi';
import { UyeListesi, type SadakatUyesi } from './uye-listesi';
import { ProgramOnizleme } from './program-onizleme';

type Sekme = 'ayarlar' | 'tarama' | 'uyeler';

interface Stats {
  aktifUye: number;
  toplamPuanVeyaDamga: number;
  kullanilanOdul: number;
  aktifKampanyaSayisi: number;
}

interface UyeDagilimi {
  tamamlayanlar: number;
  devamEdenler: number;
  aktifOlmayanlar: number;
}

const RENKLER = ['#059669', '#2563eb', '#d1d5db'];

export function SadakatIstemcisi({
  businessId,
  program,
  uyeler,
  stats,
  uyeDagilimi,
}: {
  businessId: string;
  program: SadakatProgram | null;
  uyeler: SadakatUyesi[];
  stats: Stats;
  uyeDagilimi: UyeDagilimi;
}) {
  const [sekme, setSekme] = useState<Sekme>('ayarlar');

  if (!program) {
    return (
      <div className="flex flex-col gap-6">
        <Baslik />
        <div className="max-w-lg rounded-2xl border border-border bg-card p-5">
          <SadakatKurulumIstemcisi businessId={businessId} program={null} />
        </div>
      </div>
    );
  }

  const dagilimVerisi = [
    { key: 'tamamlayanlar', label: 'Tamamlayanlar', count: uyeDagilimi.tamamlayanlar },
    { key: 'devamEdenler', label: 'Devam Edenler', count: uyeDagilimi.devamEdenler },
    { key: 'aktifOlmayanlar', label: 'Henüz Başlamayanlar', count: uyeDagilimi.aktifOlmayanlar },
  ];

  return (
    <div className="flex flex-col gap-6">
      <Baslik />

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatKart tone="red" icon={<UsersIcon />} label="Aktif Üye" value={String(stats.aktifUye)} />
        <StatKart tone="blue" icon={<StarIcon />} label={program.mode === 'points' ? 'Toplam Puan' : 'Toplam Damga'} value={stats.toplamPuanVeyaDamga.toLocaleString('tr-TR')} />
        <StatKart tone="green" icon={<GiftIcon />} label="Kullanılan Ödül" value={String(stats.kullanilanOdul)} />
        <StatKart tone="orange" icon={<MegaphoneIcon />} label="Aktif Kampanya" value={String(stats.aktifKampanyaSayisi)} />
      </div>

      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
        <div className="flex min-w-0 flex-1 flex-col gap-4">
          <div className="flex gap-1 border-b border-border">
            <TabButon active={sekme === 'ayarlar'} onClick={() => setSekme('ayarlar')}>Program Ayarları</TabButon>
            <TabButon active={sekme === 'tarama'} onClick={() => setSekme('tarama')}>QR Tarama</TabButon>
            <TabButon active={sekme === 'uyeler'} onClick={() => setSekme('uyeler')}>Üyeler ({uyeler.length})</TabButon>
          </div>

          {sekme === 'ayarlar' && (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <ProgramOnizleme program={program} />
              <div className="flex flex-col gap-4">
                <div className="rounded-2xl border border-border bg-card p-4">
                  <h3 className="mb-3 text-sm font-black text-textStrong">Program Bilgileri</h3>
                  <dl className="flex flex-col divide-y divide-border text-sm">
                    <DetayRow label="Program Adı" value={program.name} />
                    <DetayRow label="Tür" value={program.mode === 'stamp' ? 'Damga Kartı' : 'Puan Sistemi'} />
                    <DetayRow label="Hedef" value={program.mode === 'stamp' ? `${program.reward_threshold} damga` : `${program.reward_threshold} puan`} />
                    <DetayRow label="Ödül" value={program.reward_desc} />
                    <DetayRow label="Katılım Yöntemi" value="QR kod ile katılım" />
                  </dl>
                </div>
                <div className="rounded-2xl border border-border bg-card p-4">
                  <SadakatKurulumIstemcisi businessId={businessId} program={program} />
                </div>
              </div>
            </div>
          )}

          {sekme === 'tarama' && (
            <div className="max-w-md rounded-2xl border border-border bg-card p-4">
              <SadakatTaramaIstemcisi businessId={businessId} program={{ is_active: program.is_active, mode: program.mode }} />
            </div>
          )}

          {sekme === 'uyeler' && (
            <div className="rounded-2xl border border-border bg-card p-4">
              <UyeListesi members={uyeler} threshold={program.reward_threshold} />
            </div>
          )}

          <div
            className="flex flex-col items-center gap-3 rounded-2xl border border-border p-6 text-center sm:flex-row sm:justify-between sm:text-left"
            style={{ background: 'linear-gradient(135deg, rgba(127,29,29,0.06), rgba(220,38,38,0.03))' }}
          >
            <div>
              <p className="font-black text-textStrong">Sadakat programları, sadık müşteriler yaratmanın en etkili yoludur!</p>
              <p className="text-sm text-muted">Düzenli ödüller ve kolay katılım ile müşterilerinizin tekrar ziyaret etme olasılığını artırın.</p>
            </div>
            <Link
              href="/sahip/destek"
              className="inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-extrabold text-white shadow-[0_4px_16px_rgba(127,29,29,0.28)] transition-all hover:-translate-y-px"
              style={{ background: 'linear-gradient(135deg, #7f1d1d, #dc2626)' }}
            >
              Yardım Al →
            </Link>
          </div>
        </div>

        <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Üye Dağılımı</h3>
            {uyeler.length === 0 ? (
              <p className="text-xs text-muted">Henüz üye yok.</p>
            ) : (
              <>
                <div className="relative mx-auto h-32 w-32">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={dagilimVerisi} dataKey="count" nameKey="label" innerRadius={40} outerRadius={58} paddingAngle={2} stroke="none">
                        {dagilimVerisi.map((entry, i) => (
                          <Cell key={entry.key} fill={RENKLER[i % RENKLER.length]} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-xl font-black text-textStrong">{uyeler.length}</span>
                    <span className="text-[10px] font-bold text-muted">Toplam Üye</span>
                  </div>
                </div>
                <div className="mt-4 flex flex-col gap-1.5">
                  {dagilimVerisi.map((item, i) => (
                    <div key={item.key} className="flex items-center justify-between gap-2 text-sm">
                      <span className="flex items-center gap-1.5 text-textStrong">
                        <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: RENKLER[i % RENKLER.length] }} />
                        {item.label}
                      </span>
                      <span className="text-xs font-bold text-muted">{item.count}</span>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>

          <div className="rounded-2xl border border-border bg-card p-4">
            <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
            <div className="flex flex-col gap-1">
              <button
                type="button"
                onClick={() => setSekme('uyeler')}
                className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 text-left transition-colors hover:bg-black/4"
              >
                <span className="text-xs font-extrabold text-textStrong">Üye Listesini Görüntüle</span>
                <ChevronRightIcon />
              </button>
              <Link href="/sahip/pazarlama/kampanyalar" className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4">
                <span className="text-xs font-extrabold text-textStrong">Kampanyaları Yönet</span>
                <ChevronRightIcon />
              </Link>
              <Link href="/sahip/analitik" className="flex items-center justify-between gap-2 rounded-xl px-2.5 py-2 transition-colors hover:bg-black/4">
                <span className="text-xs font-extrabold text-textStrong">İstatistikleri Görüntüle</span>
                <ChevronRightIcon />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Baslik() {
  return (
    <div>
      <h1 className="text-2xl font-black tracking-tight text-textStrong">Sadakat Programı</h1>
      <p className="mt-1 text-sm text-muted">Müşterilerinize damga kartı veya puan sistemi sunun, tekrar ziyaretleri artırın.</p>
    </div>
  );
}

function DetayRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-3 py-2 first:pt-0 last:pb-0">
      <span className="text-xs font-bold text-muted">{label}</span>
      <span className="text-right text-xs font-bold text-textStrong">{value}</span>
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

function StatKart({ tone, icon, label, value }: { tone: 'red' | 'blue' | 'green' | 'orange'; icon: React.ReactNode; label: string; value: string }) {
  const TONE_CLASSES: Record<string, string> = {
    red: 'bg-red-50 text-red-600',
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-emerald-50 text-emerald-600',
    orange: 'bg-orange-50 text-orange-600',
  };
  return (
    <div className="rounded-2xl border border-border bg-card p-4 shadow-xs">
      <div className={`mb-2 flex h-9 w-9 items-center justify-center rounded-xl ${TONE_CLASSES[tone]}`}>{icon}</div>
      <p className="text-2xl font-black text-textStrong">{value}</p>
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
    </div>
  );
}

function UsersIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function StarIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" /></svg>;
}
function GiftIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 12 20 22 4 22 4 12" /><rect x="2" y="7" width="20" height="5" /><line x1="12" y1="22" x2="12" y2="7" /><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" /><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" /></svg>;
}
function MegaphoneIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11l18-5v12L3 13v-2z" /><path d="M11.6 16.8a3 3 0 0 1-5.8-1.6" /></svg>;
}
function ChevronRightIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-muted"><path d="m9 18 6-6-6-6" /></svg>;
}
