'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/supabase/client';
import { YeedoyLogo } from '@/src/ui/brand/yeedoy-logo';

type Props = { redirectTo: string };
type ActiveTab = 'login' | 'register';

// ── Icons ────────────────────────────────────────────────────────────────────

function LockIcon() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
      <path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}

function StoreIcon() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}

function EyeIcon({ off }: { off?: boolean }) {
  if (off) {
    return (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
        <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
        <line x1="1" y1="1" x2="23" y2="23" />
      </svg>
    );
  }
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
      <polyline points="22,6 12,13 2,6" />
    </svg>
  );
}

function PhoneSmIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.44 2 2 0 0 1 3.6 1.27h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L7.91 8.91a16 16 0 0 0 6.18 6.18l.91-.91a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2z" />
    </svg>
  );
}

function PhoneRedIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.44 2 2 0 0 1 3.6 1.27h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L7.91 8.91a16 16 0 0 0 6.18 6.18l.91-.91a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2z" />
    </svg>
  );
}

function PersonIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

function BuildingIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  );
}

function LockSmIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
      <path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      <polyline points="9 12 11 14 15 10" />
    </svg>
  );
}

function GoogleIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
    </svg>
  );
}

// ── Mini dashboard preview ────────────────────────────────────────────────────

function MiniDashboard() {
  const navItems = ['Genel Bakış', 'İşletme Bilgileri', 'Menü Yönetimi', 'Fotoğraf & Video', 'Yorumlar', 'Mesajlar', 'Rezervasyonlar', 'İstatistikler', 'Kampanyalar', 'GR Menü & QR Kod', 'Bildirimler', 'Ayarlar'];
  const stats = [
    { label: 'Görüntüleme', value: '12.480', change: '+%16,4', color: '#3b82f6', bg: '#eff6ff' },
    { label: 'Favori Ekleme', value: '1.248', change: '+%21,4', color: '#ef4444', bg: '#fef2f2' },
    { label: 'Yorum', value: '86', change: '+%12,2', color: '#a855f7', bg: '#faf5ff' },
    { label: 'Yol Tarifi İsteği', value: '642', change: '+%16,6', color: '#22c55e', bg: '#f0fdf4' },
    { label: 'Arama', value: '312', change: '+%8,3', color: '#f97316', bg: '#fff7ed' },
  ];
  const chartPoints = [30, 45, 35, 60, 50, 75, 65, 90];
  const maxPt = 90;
  const chartW = 200;
  const chartH = 60;
  const pts = chartPoints.map((v, i) => {
    const x = (i / (chartPoints.length - 1)) * chartW;
    const y = chartH - (v / maxPt) * chartH;
    return `${x},${y}`;
  });
  const polyline = pts.join(' ');
  const area = `0,${chartH} ${polyline} ${chartW},${chartH}`;

  return (
    <div className="relative overflow-hidden rounded-2xl border border-[#e5e7eb] bg-white shadow-[0_8px_32px_rgba(0,0,0,0.10)]" style={{ fontSize: 9 }}>
      {/* Topbar */}
      <div className="flex items-center gap-2 border-b border-[#f3f4f6] px-3 py-2">
        <span className="font-[900] text-[#dc2626]" style={{ fontSize: 11, letterSpacing: -0.3 }}>Yeedoy</span>
        <span className="ml-auto rounded border border-[#e5e7eb] px-1.5 py-0.5 text-[7px] font-[600] text-[#374151]">İşletme Sayfasını Gör ↗</span>
        <div className="relative">
          <div className="flex h-5 w-5 items-center justify-center rounded-full bg-[#f3f4f6]">
            <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth="2.5"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" /></svg>
          </div>
          <span className="absolute -right-0.5 -top-0.5 flex h-2.5 w-2.5 items-center justify-center rounded-full bg-[#dc2626] text-[5px] font-[900] text-white">3</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="flex h-5 w-5 items-center justify-center rounded-full bg-[#7f1d1d] text-[7px] font-[900] text-white">M</div>
          <div>
            <div className="text-[7px] font-[700] text-[#374151]">Mustafa Çelik</div>
            <div className="text-[6px] text-[#6b7280]">İşletme Sahibi</div>
          </div>
          <span className="text-[6px] text-[#6b7280]">▾</span>
        </div>
      </div>

      {/* Body */}
      <div className="flex" style={{ height: 210 }}>
        {/* Sidebar */}
        <div className="flex w-[88px] flex-shrink-0 flex-col gap-0.5 border-r border-[#f3f4f6] p-1.5 overflow-hidden">
          <div className="mb-1 flex items-center gap-1 rounded-lg bg-[#fef2f2] p-1">
            <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-lg bg-[#dc2626] text-[7px] font-[900] text-white">N</div>
            <div className="overflow-hidden">
              <div className="truncate text-[7px] font-[800] leading-tight text-[#111827]">No 18 Coffee Co.</div>
              <div className="text-[6px] font-[600] text-[#6b7280]">Kafe</div>
              <div className="text-[5.5px] font-[700] text-[#10b981]">Onaylı İşletme</div>
            </div>
          </div>
          {navItems.map((item, i) => (
            <div
              key={item}
              className="flex items-center gap-1 truncate rounded px-1.5 py-0.5 text-[6.5px] font-[600]"
              style={{
                color: i === 0 ? '#dc2626' : '#6b7280',
                background: i === 0 ? '#fef2f2' : 'transparent',
                borderLeft: i === 0 ? '2px solid #dc2626' : '2px solid transparent',
              }}
            >
              {item}
              {item === 'Yorumlar' && <span className="ml-auto rounded-full bg-[#dc2626] px-1 text-[4.5px] font-[900] text-white">41</span>}
              {item === 'Mesajlar' && <span className="ml-auto rounded-full bg-[#3b82f6] px-1 text-[4.5px] font-[900] text-white">6</span>}
              {item === 'Rezervasyonlar' && <span className="ml-auto rounded-full bg-[#f97316] px-0.5 text-[4.5px] font-[900] text-white">Yeni</span>}
            </div>
          ))}
        </div>

        {/* Main */}
        <div className="flex-1 overflow-hidden p-2">
          <div className="mb-2 flex items-center justify-between">
            <div>
              <div className="text-[9px] font-[800] text-[#111827]">Merhaba Mustafa! 👋</div>
              <div className="text-[6.5px] text-[#6b7280]">İşletmenin son durumuna hızlıca göz at.</div>
            </div>
            <div className="rounded border border-[#e5e7eb] px-1.5 py-0.5 text-[6px] font-[700] text-[#374151]">Son 7 Gün ▾</div>
          </div>
          <div className="mb-2 flex gap-1">
            {stats.map((s) => (
              <div key={s.label} className="flex flex-1 flex-col gap-0.5 rounded-lg border border-[#f3f4f6] p-1.5">
                <div className="flex h-4 w-4 items-center justify-center rounded" style={{ background: s.bg }}>
                  <div className="h-2 w-2 rounded-sm" style={{ background: s.color }} />
                </div>
                <div className="text-[5.5px] font-[600] text-[#6b7280] leading-tight">{s.label}</div>
                <div className="text-[8px] font-[900] text-[#111827]">{s.value}</div>
                <div className="text-[5.5px] font-[700] text-[#16a34a]">{s.change}</div>
                <div className="text-[5px] text-[#9ca3af]">Önceki 7 güne göre</div>
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <div className="flex-1">
              <div className="mb-1 flex items-center justify-between">
                <span className="text-[7px] font-[800] text-[#111827]">Görüntüleme Grafiği</span>
                <span className="rounded border border-[#e5e7eb] px-1 py-0.5 text-[5px] font-[600] text-[#6b7280]">Günlük ▾</span>
              </div>
              <svg width="100%" height={chartH} viewBox={`0 0 ${chartW} ${chartH}`} preserveAspectRatio="none">
                <defs>
                  <linearGradient id="miniGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#dc2626" stopOpacity="0.15" />
                    <stop offset="100%" stopColor="#dc2626" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <polygon points={area} fill="url(#miniGrad)" />
                <polyline points={polyline} fill="none" stroke="#dc2626" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <div className="flex justify-between px-0.5 text-[4.5px] text-[#9ca3af]">
                {['31 May','1 Haz','2 Haz','3 Haz','4 Haz','5 Haz','6 Haz'].map(d => <span key={d}>{d}</span>)}
              </div>
            </div>
            <div className="w-[100px] flex-shrink-0">
              <div className="mb-1 text-[7px] font-[800] text-[#111827]">Son Aktiviteler</div>
              {[
                { dot: '#ef4444', label: 'Yeni yorum aldı', sub: '"Kahveler harika, ortam çok keyifli"', time: '5 dk önce' },
                { dot: '#3b82f6', label: 'Yeni mesaj geldi', sub: '"Merhaba, rezervasyon yapmak istiyorum"', time: '15 dk önce' },
                { dot: '#f97316', label: 'Menü güncellendi', sub: 'Yaz menüsü eklendi.', time: '2 saat önce' },
                { dot: '#22c55e', label: 'Fotoğraf eklendi', sub: '4 yeni fotoğraf yüklendi.', time: '4 saat önce' },
              ].map((a) => (
                <div key={a.label} className="flex items-start gap-1 py-0.5">
                  <div className="mt-1 h-1.5 w-1.5 flex-shrink-0 rounded-full" style={{ background: a.dot }} />
                  <div>
                    <div className="text-[6px] font-[700] text-[#374151] leading-tight">{a.label}</div>
                    <div className="text-[5px] text-[#9ca3af] leading-tight line-clamp-1">{a.sub}</div>
                    <div className="text-[5px] text-[#9ca3af]">{a.time}</div>
                  </div>
                </div>
              ))}
              <div className="mt-1 text-[6px] font-[700] text-[#dc2626]">Tüm Aktiviteler →</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Turkish cities + categories ───────────────────────────────────────────────

const CITIES = ['Adana','Ankara','Antalya','Bursa','Diyarbakır','Eskişehir','Gaziantep','İstanbul','İzmir','Kayseri','Konya','Mersin','Samsun','Trabzon','Şanlıurfa'];
const CATEGORIES = ['Kafe','Restoran','Fast Food','Pastane & Fırın','Pizza','Burger','Döner & Kebap','Deniz Ürünleri','Vejeteryan & Vegan','Dünya Mutfağı','Tatlı & Dondurma','Bar & Meyhane','Kahvaltı Salonu','Diğer'];

// ── Right-panel content per tab ───────────────────────────────────────────────

function RightPanel({ tab }: { tab: ActiveTab }) {
  const isRegister = tab === 'register';

  const heroIcon = isRegister ? (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
      <polyline points="17 6 23 6 23 12" />
    </svg>
  ) : (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  );

  const title = isRegister ? (
    <>Yeedoy ile işletmeni <span className="text-[#dc2626]">dijitalde güçlendir</span></>
  ) : (
    <>Yeedoy İşletme Paneli ile <span className="text-[#dc2626]">işletmeni büyüt</span></>
  );

  const subtitle = isRegister
    ? 'Menünü yönet, yorumları takip et, kampanyalar oluştur ve istatistiklerle işletmeni büyüt.'
    : 'Siparişlerinden yorumlara, istatistiklerden kampanyalara kadar tüm süreçleri tek panelden yönet.';

  const featureCards = isRegister ? [
    {
      bg: '#fef2f2',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 2h13l4 4v17H3z" /><path d="M7 6h6M7 10h6M7 14h4" />
        </svg>
      ),
      title: 'Menünü yönet',
      desc: 'Menü, fiyat ve içerikleri kolayca güncelle.',
    },
    {
      bg: '#faf5ff',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#a855f7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      ),
      title: 'Yorumları takip et',
      desc: 'Müşteri yorumlarını oku, yanıtla ve memnuniyeti artır.',
    },
    {
      bg: '#f0fdf4',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <line x1="18" y1="20" x2="18" y2="10" />
          <line x1="12" y1="20" x2="12" y2="4" />
          <line x1="6" y1="20" x2="6" y2="14" />
        </svg>
      ),
      title: 'İstatistiklerle büyü',
      desc: 'Detaylı raporlarla performansını analiz et, doğru kararlar al.',
    },
  ] : [
    {
      bg: '#fef2f2',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 2h13l4 4v17H3z" /><path d="M7 6h6M7 10h6M7 14h4" />
        </svg>
      ),
      title: 'Menünü yönet',
      desc: 'Ürünleri düzenle, fiyatları güncelle, görselleri yönet.',
    },
    {
      bg: '#faf5ff',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#a855f7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      ),
      title: 'Yorumları takip et',
      desc: 'Müşteri yorumlarını oku, yanıtla ve memnuniyeti artır.',
    },
    {
      bg: '#f0fdf4',
      icon: (
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <line x1="18" y1="20" x2="18" y2="10" />
          <line x1="12" y1="20" x2="12" y2="4" />
          <line x1="6" y1="20" x2="6" y2="14" />
        </svg>
      ),
      title: 'İstatistikleri gör',
      desc: 'Performansını analiz et, doğru kararlar al.',
    },
  ];

  return (
    <div className="hidden flex-1 flex-col justify-between bg-[#fafafa] px-10 py-10 lg:flex">
      <div>
        <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#fef2f2]">
          {heroIcon}
        </div>
        <h2 className="text-[28px] font-[900] leading-tight text-[#111827]">{title}</h2>
        <p className="mt-3 text-sm leading-relaxed text-[#6b7280]">{subtitle}</p>
        <div className="mt-7">
          <MiniDashboard />
        </div>
      </div>
      <div className="mt-7 grid grid-cols-3 gap-3">
        {featureCards.map((card) => (
          <div key={card.title} className="rounded-2xl border border-[#f0f0f0] bg-white p-4 shadow-sm">
            <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl" style={{ background: card.bg }}>
              {card.icon}
            </div>
            <p className="text-sm font-[800] text-[#111827]">{card.title}</p>
            <p className="mt-1 text-xs leading-relaxed text-[#6b7280]">{card.desc}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Security badge ────────────────────────────────────────────────────────────

function SecurityBadge({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-2.5 rounded-xl border border-[#d1fae5] bg-[#f0fdf4] px-4 py-3">
      <ShieldIcon />
      <div>
        <span className="text-sm font-[800] text-[#15803d]">{label}</span>
        <p className="text-xs text-[#16a34a]">Verileriniz 256-bit SSL şifreleme ile korunur.</p>
      </div>
    </div>
  );
}

// ── Field helper ──────────────────────────────────────────────────────────────

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-[700] text-[#374151]">{label}</label>
      {children}
    </div>
  );
}

const INPUT_CLS = 'h-11 w-full rounded-xl border border-[#e5e7eb] bg-[#fafafa] px-4 text-sm text-[#111827] placeholder:text-[#d1d5db] outline-none transition focus:border-[#dc2626] focus:bg-white focus:ring-2 focus:ring-[#dc2626]/10';
const ICON_INPUT_CLS = 'h-11 w-full rounded-xl border border-[#e5e7eb] bg-[#fafafa] pl-9 pr-10 text-sm text-[#111827] placeholder:text-[#d1d5db] outline-none transition focus:border-[#dc2626] focus:bg-white focus:ring-2 focus:ring-[#dc2626]/10';

// ── Main component ────────────────────────────────────────────────────────────

export function OwnerLoginPage({ redirectTo }: Props) {
  const router = useRouter();
  const [tab, setTab] = useState<ActiveTab>('login');

  // Login state
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [isPending, startTransition] = useTransition();

  // Register state
  const [bizName, setBizName] = useState('');
  const [ownerName, setOwnerName] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPhone, setRegPhone] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [regPassword2, setRegPassword2] = useState('');
  const [showRegPwd, setShowRegPwd] = useState(false);
  const [showRegPwd2, setShowRegPwd2] = useState(false);
  const [bizCategory, setBizCategory] = useState('');
  const [bizCity, setBizCity] = useState('');
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [acceptPrivacy, setAcceptPrivacy] = useState(false);
  const [regError, setRegError] = useState('');
  const [regSuccess, setRegSuccess] = useState(false);
  const [isRegPending, startRegTransition] = useTransition();

  function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoginError('');
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
      if (error) {
        setLoginError(
          error.message.includes('Invalid login') || error.message.includes('invalid_credentials')
            ? 'E-posta veya şifre hatalı.'
            : error.message,
        );
        return;
      }
      router.replace(redirectTo);
      router.refresh();
    });
  }

  function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    setRegError('');
    if (regPassword !== regPassword2) { setRegError('Şifreler eşleşmiyor.'); return; }
    if (!acceptTerms || !acceptPrivacy) { setRegError('Kullanım koşullarını ve gizlilik politikasını kabul etmelisiniz.'); return; }
    startRegTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signUp({
        email: regEmail.trim(),
        password: regPassword,
        options: {
          data: {
            display_name: ownerName.trim(),
            business_name: bizName.trim(),
            phone: regPhone.trim(),
            business_category: bizCategory,
            city: bizCity,
          },
        },
      });
      if (error) { setRegError(error.message); return; }
      setRegSuccess(true);
    });
  }

  async function handleGoogle() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent(redirectTo)}` },
    });
  }

  const selectCls = `${INPUT_CLS} cursor-pointer appearance-none`;

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <div className="flex flex-1">
        {/* ── Left panel ── */}
        <div className="flex w-full flex-col px-8 py-10 lg:w-[480px] lg:flex-shrink-0 lg:overflow-y-auto lg:border-r lg:border-[#f0f0f0] lg:px-12">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <Link href="/">
              <YeedoyLogo size={32} />
            </Link>
            <Link
              href="/owner/dashboard"
              className="flex items-center gap-1.5 rounded-full border border-[#e5e7eb] px-3 py-1 text-xs font-[700] text-[#374151] transition hover:border-[#dc2626]/30 hover:text-[#dc2626]"
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                <polyline points="15 3 21 3 21 9" />
                <line x1="10" y1="14" x2="21" y2="3" />
              </svg>
              İşletme Paneli
            </Link>
          </div>

          {/* Icon */}
          <div className="mt-10 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#fef2f2]">
            {tab === 'login' ? <LockIcon /> : <StoreIcon />}
          </div>

          {/* Title */}
          <h1 className="mt-5 text-[26px] font-[900] leading-tight text-[#111827]">
            {tab === 'login' ? 'İşletme Paneline Giriş Yap' : 'İşletme Paneline Kayıt Ol'}
          </h1>
          <p className="mt-2 text-sm text-[#6b7280]">
            {tab === 'login'
              ? 'İşletmenizi yönetmek için hesabınıza giriş yapın.'
              : 'İşletmeni yönetmek için hesabını oluştur.'}
          </p>

          {/* Tabs */}
          <div className="mt-6 flex border-b border-[#f0f0f0]">
            {(['login', 'register'] as const).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setTab(t)}
                className="relative pb-3 pr-6 text-sm font-[700] transition"
                style={{ color: tab === t ? '#dc2626' : '#6b7280' }}
              >
                {t === 'login' ? 'Giriş Yap' : 'Kayıt Ol'}
                {tab === t && <span className="absolute bottom-0 left-0 right-6 h-0.5 rounded-full bg-[#dc2626]" />}
              </button>
            ))}
          </div>

          {/* ── LOGIN FORM ── */}
          {tab === 'login' ? (
            <form className="mt-6 flex flex-col gap-4" onSubmit={handleLogin}>
              <Field label="E-posta">
                <div className="relative flex items-center">
                  <span className="pointer-events-none absolute left-3"><MailIcon /></span>
                  <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                    placeholder="ornek@isletme.com" required autoComplete="email"
                    className={ICON_INPUT_CLS} />
                </div>
              </Field>

              <Field label="Şifre">
                <div className="relative flex items-center">
                  <span className="pointer-events-none absolute left-3"><LockSmIcon /></span>
                  <input type={showPassword ? 'text' : 'password'} value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Şifrenizi girin" required autoComplete="current-password"
                    className={`${ICON_INPUT_CLS} pr-10`} />
                  <button type="button" tabIndex={-1} onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 text-[#9ca3af] hover:text-[#374151] transition">
                    <EyeIcon off={showPassword} />
                  </button>
                </div>
              </Field>

              <div className="flex items-center justify-between">
                <label className="flex cursor-pointer items-center gap-2 text-sm text-[#374151]">
                  <input type="checkbox" checked={rememberMe} onChange={(e) => setRememberMe(e.target.checked)}
                    className="h-4 w-4 cursor-pointer rounded border-[#e5e7eb] accent-[#dc2626]" />
                  <span className="font-[600]">Beni hatırla</span>
                </label>
                <Link href="/forgot-password" className="text-sm font-[700] text-[#dc2626] hover:underline">
                  Şifremi unuttum?
                </Link>
              </div>

              {loginError && <p className="rounded-lg bg-red-50 px-4 py-2.5 text-sm font-[600] text-red-600">{loginError}</p>}

              <button type="submit" disabled={isPending}
                className="mt-1 h-12 w-full rounded-xl bg-[#dc2626] text-sm font-[800] text-white shadow-[0_2px_8px_rgba(220,38,38,0.28)] transition hover:bg-[#b91c1c] active:scale-[0.98] disabled:opacity-60">
                {isPending ? 'Giriş yapılıyor…' : 'Giriş Yap'}
              </button>

              {/* Social */}
              <div className="relative flex items-center">
                <div className="flex-1 border-t border-[#f0f0f0]" />
                <span className="mx-3 text-xs text-[#9ca3af]">veya</span>
                <div className="flex-1 border-t border-[#f0f0f0]" />
              </div>
              <div className="flex flex-col gap-3">
                <button type="button" onClick={handleGoogle}
                  className="flex h-12 w-full items-center justify-center gap-2.5 rounded-xl border border-[#e5e7eb] bg-white text-sm font-[700] text-[#374151] transition hover:bg-[#f9fafb] hover:border-[#d1d5db] active:scale-[0.98]">
                  <GoogleIcon /> Google ile devam et
                </button>
                <button type="button"
                  className="flex h-12 w-full items-center justify-center gap-2.5 rounded-xl border border-[#e5e7eb] bg-white text-sm font-[700] text-[#374151] transition hover:bg-[#f9fafb] hover:border-[#d1d5db] active:scale-[0.98]">
                  <PhoneRedIcon /> Telefon ile giriş
                </button>
              </div>

              <SecurityBadge label="Güvenli giriş" />

              <p className="text-center text-sm text-[#6b7280]">
                Henüz işletme hesabın yok mu?{' '}
                <button type="button" onClick={() => setTab('register')} className="font-[800] text-[#dc2626] hover:underline">
                  Kayıt ol
                </button>{' '}
                <span className="text-[#dc2626]">›</span>
              </p>
            </form>
          ) : (
            /* ── REGISTER FORM ── */
            regSuccess ? (
              <div className="mt-6 rounded-2xl bg-green-50 p-6 text-center">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                </div>
                <p className="text-base font-[900] text-green-800">Hesabınız oluşturuldu!</p>
                <p className="mt-2 text-sm text-green-700">
                  Doğrulama e-postası gönderildi. Gelen kutunuzu kontrol edin, ardından giriş yapın.
                </p>
                <button type="button" onClick={() => setTab('login')}
                  className="mt-4 inline-block rounded-xl bg-[#dc2626] px-6 py-2.5 text-sm font-[800] text-white">
                  Giriş Yap →
                </button>
              </div>
            ) : (
              <form className="mt-5 flex flex-col gap-3.5" onSubmit={handleRegister}>
                {/* İşletme Adı */}
                <Field label="İşletme Adı">
                  <div className="relative flex items-center">
                    <span className="pointer-events-none absolute left-3"><BuildingIcon /></span>
                    <input type="text" value={bizName} onChange={(e) => setBizName(e.target.value)}
                      placeholder="İşletme adınızı girin" required
                      className={ICON_INPUT_CLS} />
                  </div>
                </Field>

                {/* Yetkili Ad Soyad */}
                <Field label="Yetkili Ad Soyad">
                  <div className="relative flex items-center">
                    <span className="pointer-events-none absolute left-3"><PersonIcon /></span>
                    <input type="text" value={ownerName} onChange={(e) => setOwnerName(e.target.value)}
                      placeholder="Adınız ve soyadınız" required
                      className={ICON_INPUT_CLS} />
                  </div>
                </Field>

                {/* E-posta + Telefon */}
                <div className="grid grid-cols-2 gap-3">
                  <Field label="E-posta">
                    <div className="relative flex items-center">
                      <span className="pointer-events-none absolute left-3"><MailIcon /></span>
                      <input type="email" value={regEmail} onChange={(e) => setRegEmail(e.target.value)}
                        placeholder="ornek@isletme.com" required autoComplete="email"
                        className={`${ICON_INPUT_CLS} pr-3`} />
                    </div>
                  </Field>
                  <Field label="Telefon">
                    <div className="relative flex items-center">
                      <span className="pointer-events-none absolute left-3"><PhoneSmIcon /></span>
                      <input type="tel" value={regPhone} onChange={(e) => setRegPhone(e.target.value)}
                        placeholder="5XX XXX XX XX"
                        className={`${ICON_INPUT_CLS} pr-3`} />
                    </div>
                  </Field>
                </div>

                {/* Şifre + Şifre Tekrar */}
                <div className="grid grid-cols-2 gap-3">
                  <Field label="Şifre">
                    <div className="relative flex items-center">
                      <span className="pointer-events-none absolute left-3"><LockSmIcon /></span>
                      <input type={showRegPwd ? 'text' : 'password'} value={regPassword}
                        onChange={(e) => setRegPassword(e.target.value)}
                        placeholder="En az 8 karakter" required minLength={8} autoComplete="new-password"
                        className={`${ICON_INPUT_CLS} pr-8`} />
                      <button type="button" tabIndex={-1} onClick={() => setShowRegPwd((v) => !v)}
                        className="absolute right-2.5 text-[#9ca3af] hover:text-[#374151] transition">
                        <EyeIcon off={showRegPwd} />
                      </button>
                    </div>
                  </Field>
                  <Field label="Şifre Tekrar">
                    <div className="relative flex items-center">
                      <span className="pointer-events-none absolute left-3"><LockSmIcon /></span>
                      <input type={showRegPwd2 ? 'text' : 'password'} value={regPassword2}
                        onChange={(e) => setRegPassword2(e.target.value)}
                        placeholder="Şifrenizi tekrar girin" required autoComplete="new-password"
                        className={`${ICON_INPUT_CLS} pr-8`} />
                      <button type="button" tabIndex={-1} onClick={() => setShowRegPwd2((v) => !v)}
                        className="absolute right-2.5 text-[#9ca3af] hover:text-[#374151] transition">
                        <EyeIcon off={showRegPwd2} />
                      </button>
                    </div>
                  </Field>
                </div>

                {/* Kategori + Şehir */}
                <div className="grid grid-cols-2 gap-3">
                  <Field label="İşletme Kategorisi">
                    <div className="relative">
                      <select value={bizCategory} onChange={(e) => setBizCategory(e.target.value)}
                        className={`${selectCls} pr-8`}>
                        <option value="">Kategori seçin</option>
                        {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                      </select>
                      <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[#9ca3af]">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9" /></svg>
                      </span>
                    </div>
                  </Field>
                  <Field label="Şehir">
                    <div className="relative">
                      <select value={bizCity} onChange={(e) => setBizCity(e.target.value)}
                        className={`${selectCls} pr-8`}>
                        <option value="">Şehir seçin</option>
                        {CITIES.map((c) => <option key={c} value={c}>{c}</option>)}
                      </select>
                      <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[#9ca3af]">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9" /></svg>
                      </span>
                    </div>
                  </Field>
                </div>

                {/* Checkboxes */}
                <div className="flex flex-col gap-2">
                  <label className="flex cursor-pointer items-center gap-2.5 text-sm text-[#374151]">
                    <input type="checkbox" checked={acceptTerms} onChange={(e) => setAcceptTerms(e.target.checked)}
                      className="h-4 w-4 cursor-pointer rounded border-[#e5e7eb] accent-[#dc2626] flex-shrink-0" />
                    <span className="font-[600]">
                      <Link href="/legal" target="_blank" className="font-[700] text-[#dc2626] hover:underline">Kullanım koşullarını</Link> kabul ediyorum.
                    </span>
                  </label>
                  <label className="flex cursor-pointer items-center gap-2.5 text-sm text-[#374151]">
                    <input type="checkbox" checked={acceptPrivacy} onChange={(e) => setAcceptPrivacy(e.target.checked)}
                      className="h-4 w-4 cursor-pointer rounded border-[#e5e7eb] accent-[#dc2626] flex-shrink-0" />
                    <span className="font-[600]">
                      <Link href="/legal" target="_blank" className="font-[700] text-[#dc2626] hover:underline">Gizlilik politikasını</Link> okudum.
                    </span>
                  </label>
                </div>

                {regError && <p className="rounded-lg bg-red-50 px-4 py-2.5 text-sm font-[600] text-red-600">{regError}</p>}

                {/* Submit */}
                <button type="submit" disabled={isRegPending}
                  className="h-12 w-full rounded-xl bg-[#dc2626] text-sm font-[800] text-white shadow-[0_2px_8px_rgba(220,38,38,0.28)] transition hover:bg-[#b91c1c] active:scale-[0.98] disabled:opacity-60">
                  {isRegPending ? 'Kaydediliyor…' : 'Kayıt Ol'}
                </button>

                {/* Already have account */}
                <button type="button" onClick={() => setTab('login')}
                  className="flex h-11 w-full items-center justify-center rounded-xl border border-[#e5e7eb] text-sm font-[700] text-[#374151] transition hover:bg-[#f9fafb]">
                  Zaten hesabın var mı?{' '}
                  <span className="ml-1 font-[800] text-[#dc2626]">Giriş yap</span>
                </button>

                <SecurityBadge label="Güvenli kayıt" />
              </form>
            )
          )}
        </div>

        {/* ── Right panel ── */}
        <RightPanel tab={tab} />
      </div>

      {/* ── Footer ── */}
      <footer className="border-t border-[#f0f0f0] px-8 py-5">
        <div className="flex flex-wrap items-center justify-between gap-4 text-xs text-[#9ca3af]">
          <span>© 2024 Yeedoy. Tüm hakları saklıdır.</span>
          <div className="flex gap-5">
            <Link href="/legal" className="hover:text-[#374151] transition">Kullanım Koşulları</Link>
            <Link href="/legal" className="hover:text-[#374151] transition">Gizlilik Politikası</Link>
            <a href="#" className="hover:text-[#374151] transition">Yardım Merkezi</a>
          </div>
        </div>
      </footer>
    </div>
  );
}
