'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { updateReservationStatus } from './actions';

// ── DB type (from owner_list_reservations_v1) ─────────────────────────────────

export interface DbReservation {
  id: string;
  reservation_no: string;
  guest_name: string;
  guest_phone: string;
  guest_email: string | null;
  party_size: number;
  reservation_date: string;  // "2026-07-15"
  reservation_time: string;  // "19:30:00"
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  channel: 'web' | 'mobile' | 'phone' | 'yeedoy_app';
  table_preference: string | null;
  special_request: string | null;
  owner_note: string | null;
  created_at: string;
  updated_at: string;
}

interface Props {
  businessId: string;
  initialReservations: DbReservation[];
  total: number;
}

// ── Internal types ─────────────────────────────────────────────────────────────

type Status = 'Bekliyor' | 'Onaylandı' | 'İptal Edildi' | 'Tamamlandı';
type Channel = 'Yeedoy App' | 'Web Sitesi' | 'Telefon';

interface Reservation {
  id: string;
  no: string;
  guest: { name: string; phone: string; initials: string; color: string; };
  dateStr: string;
  day: string;
  time: string;
  people: number;
  status: Status;
  channel: Channel;
  hasNote: boolean;
  note?: string;
  tablePreference?: string;
  specialRequest?: string;
  createdAt: string;
}

// ── Converter helpers ─────────────────────────────────────────────────────────

const TR_MONTHS = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
const TR_DAYS   = ['Pazar','Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi'];
const GUEST_COLORS = ['#7c3aed','#2563eb','#db2777','#059669','#16a34a','#0891b2','#9333ea','#d97706','#dc2626','#0284c7'];

const STATUS_MAP: Record<DbReservation['status'], Status> = {
  pending:   'Bekliyor',
  confirmed: 'Onaylandı',
  cancelled: 'İptal Edildi',
  completed: 'Tamamlandı',
};

const CHANNEL_MAP: Record<DbReservation['channel'], Channel> = {
  web:        'Web Sitesi',
  mobile:     'Yeedoy App',
  phone:      'Telefon',
  yeedoy_app: 'Yeedoy App',
};

function toReservation(r: DbReservation): Reservation {
  // Parse date parts without timezone ambiguity
  const [year, month, day] = r.reservation_date.split('-').map(Number);
  const dateObj = new Date(year, month - 1, day);
  const dateStr = `${day} ${TR_MONTHS[month - 1]} ${year}`;
  const dayName = TR_DAYS[dateObj.getDay()];
  const time = r.reservation_time.slice(0, 5); // "19:30:00" → "19:30"

  // Guest initials
  const parts = r.guest_name.trim().split(/\s+/);
  const initials = parts.length >= 2
    ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    : r.guest_name.slice(0, 2).toUpperCase();

  // Guest avatar color — deterministic based on first char
  const color = GUEST_COLORS[r.guest_name.charCodeAt(0) % GUEST_COLORS.length];

  // Created-at label
  const ca = new Date(r.created_at);
  const createdAt = `${ca.getDate()} ${TR_MONTHS[ca.getMonth()]} ${ca.getFullYear()}, ${String(ca.getHours()).padStart(2, '0')}:${String(ca.getMinutes()).padStart(2, '0')}`;

  return {
    id: r.id,
    no: r.reservation_no,
    guest: { name: r.guest_name, phone: r.guest_phone, initials, color },
    dateStr,
    day: dayName,
    time,
    people: r.party_size,
    status: STATUS_MAP[r.status] ?? 'Bekliyor',
    channel: CHANNEL_MAP[r.channel] ?? 'Yeedoy App',
    hasNote: !!(r.owner_note || r.special_request),
    note: r.owner_note ?? undefined,
    tablePreference: r.table_preference ?? undefined,
    specialRequest: r.special_request ?? undefined,
    createdAt,
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const STATUS_STYLES: Record<Status, string> = {
  'Bekliyor':     'bg-amber-100 text-amber-700',
  'Onaylandı':    'bg-green-100 text-green-700',
  'İptal Edildi': 'bg-red-100 text-red-600',
  'Tamamlandı':   'bg-slate-100 text-slate-500',
};

const TABS = [
  { key: 'all',       label: 'Tümü',         filter: (_: Reservation) => true },
  { key: 'pending',   label: 'Bekleyen',      filter: (r: Reservation) => r.status === 'Bekliyor' },
  { key: 'confirmed', label: 'Onaylanan',     filter: (r: Reservation) => r.status === 'Onaylandı' },
  { key: 'cancelled', label: 'İptal Edilen',  filter: (r: Reservation) => r.status === 'İptal Edildi' },
  { key: 'completed', label: 'Tamamlanan',    filter: (r: Reservation) => r.status === 'Tamamlandı' },
] as const;

type TabKey = typeof TABS[number]['key'];

// ── Main ──────────────────────────────────────────────────────────────────────

export function ReservationsClient({ businessId, initialReservations, total }: Props) {
  const [all, setAll] = useState<Reservation[]>(() => initialReservations.map(toReservation));
  const [selectedId, setSelectedId] = useState<string | undefined>(
    initialReservations.length > 0 ? initialReservations[0].id : undefined,
  );
  const [tab, setTab] = useState<TabKey>('all');
  const [search, setSearch] = useState('');
  const [channel, setChannel] = useState('all');

  const selected = useMemo(
    () => (selectedId ? all.find((r) => r.id === selectedId) ?? all[0] : all[0]),
    [all, selectedId],
  );

  const filtered = useMemo(() => {
    const tabFn = TABS.find((t) => t.key === tab)?.filter ?? (() => true);
    return all
      .filter(tabFn)
      .filter((r) => {
        if (search) {
          const q = search.toLowerCase();
          return r.guest.name.toLowerCase().includes(q) || r.guest.phone.includes(q) || r.no.toLowerCase().includes(q);
        }
        return true;
      })
      .filter((r) => channel === 'all' || r.channel === channel);
  }, [all, tab, search, channel]);

  async function handleCancel(id: string) {
    // Optimistic update
    setAll((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status: 'İptal Edildi' as Status } : r)),
    );
    // Persist to DB
    const result = await updateReservationStatus(id, businessId, 'cancelled');
    if (result.error) {
      // Revert optimistic update on failure
      setAll((prev) =>
        prev.map((r) => (r.id === id ? { ...r, status: 'Bekliyor' as Status } : r)),
      );
      console.error('Rezervasyon iptal edilemedi:', result.error);
    }
  }

  // Stats — compare reservation date string to today's formatted date
  const todayDate = new Date();
  const todayStr = `${todayDate.getDate()} ${TR_MONTHS[todayDate.getMonth()]} ${todayDate.getFullYear()}`;
  const today = all.filter((r) => r.dateStr === todayStr);
  const todayPeople = today.reduce((s, r) => s + r.people, 0);
  const pending = all.filter((r) => r.status === 'Bekliyor');
  const pendingPeople = pending.reduce((s, r) => s + r.people, 0);
  const confirmed = all.filter((r) => r.status === 'Onaylandı');
  const confirmedPeople = confirmed.reduce((s, r) => s + r.people, 0);
  const cancelled = all.filter((r) => r.status === 'İptal Edildi');
  const cancelledPeople = cancelled.reduce((s, r) => s + r.people, 0);

  return (
    <div className="mx-auto max-w-[1300px] p-6">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-[26px] font-[900] text-[#1a1a2e]">Rezervasyonlar</h1>
        <p className="mt-1 text-sm text-[#64748b]">Tüm rezervasyonlarınızı görüntüleyin, durumlarını yönetin ve detaylarını inceleyin.</p>
      </div>

      {/* Stats row */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard icon={<CalendarStatIcon />} color="text-blue-500" bg="bg-blue-50"
          label="Bugünkü Rezervasyon" value={today.length} sub={`Toplam ${todayPeople} kişi`} />
        <StatCard icon={<ClockIcon />} color="text-amber-500" bg="bg-amber-50"
          label="Bekleyen" value={pending.length} sub={`Toplam ${pendingPeople} kişi`} />
        <StatCard icon={<CheckCircleIcon />} color="text-green-500" bg="bg-green-50"
          label="Onaylanan" value={confirmed.length} sub={`Toplam ${confirmedPeople} kişi`} />
        <StatCard icon={<XCircleIcon />} color="text-red-500" bg="bg-red-50"
          label="İptal Edilen" value={cancelled.length} sub={`Toplam ${cancelledPeople} kişi`} />
        <StatCard icon={<WalletIcon />} color="text-purple-500" bg="bg-purple-50"
          label="Bu Ayın Cirosu" value="₺48.750" sub="Rezervasyonlardan" />
      </div>

      {/* Tabs */}
      <div className="mb-4 flex items-center gap-1 border-b border-[#f0f0f0]">
        {TABS.map((t) => {
          const count = all.filter(t.filter).length;
          const active = tab === t.key;
          return (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`relative pb-3 pt-1 px-3 text-[13px] font-[800] transition-colors ${
                active ? 'text-[#dc2626]' : 'text-[#64748b] hover:text-[#1a1a2e]'
              }`}
            >
              {t.label}
              <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-[10px] font-[900] ${
                active ? 'bg-[#dc2626] text-white' : 'bg-[#f1f5f9] text-[#64748b]'
              }`}>
                {count}
              </span>
              {active && <span className="absolute bottom-0 left-0 right-0 h-[2px] rounded-full bg-[#dc2626]" />}
            </button>
          );
        })}
      </div>

      {/* Two-column layout */}
      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[1fr_340px]">
        {/* ── Left: table ──────────────────────────────────────────── */}
        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-[#f0f0f0] bg-white shadow-sm">
            {/* Search + filters */}
            <div className="flex flex-wrap items-center gap-2 border-b border-[#f0f0f0] px-4 py-3">
              <div className="relative min-w-0 flex-1">
                <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#94a3b8]" />
                <input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Misafir adı, telefon veya rezervasyon no ile ara..."
                  className="w-full rounded-xl border border-[#e2e8f0] bg-[#f8fafc] py-2 pl-9 pr-3 text-sm text-[#1a1a2e] placeholder:text-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20"
                />
              </div>
              <button className="flex items-center gap-1.5 rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2 text-[12px] font-[700] text-[#475569] hover:bg-[#f1f5f9]">
                <CalendarSmIcon className="h-4 w-4" /> Tarih Seçin
              </button>
              <select
                value={channel}
                onChange={(e) => setChannel(e.target.value)}
                className="rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2 text-[12px] font-[700] text-[#475569] focus:outline-none focus:ring-2 focus:ring-[#dc2626]/20"
              >
                <option value="all">Tüm Kanallar</option>
                <option value="Yeedoy App">Yeedoy App</option>
                <option value="Web Sitesi">Web Sitesi</option>
                <option value="Telefon">Telefon</option>
              </select>
              <button className="flex items-center gap-1.5 rounded-xl border border-[#e2e8f0] bg-[#f8fafc] px-3 py-2 text-[12px] font-[700] text-[#475569] hover:bg-[#f1f5f9]">
                <FilterIcon className="h-4 w-4" /> Filtrele
              </button>
            </div>

            {/* Table */}
            <div className="overflow-x-auto">
              <table className="w-full min-w-[700px]">
                <thead>
                  <tr className="border-b border-[#f0f0f0] bg-[#fafafa]">
                    {['Misafir', 'Tarih & Saat', 'Kişi', 'Durum', 'Kanal', 'Not', 'İşlemler'].map((h) => (
                      <th key={h} className="px-4 py-3 text-left text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#f0f0f0]">
                  {filtered.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-16 text-center text-sm text-[#94a3b8]">Rezervasyon bulunamadı.</td>
                    </tr>
                  ) : (
                    filtered.map((r) => (
                      <tr
                        key={r.id}
                        onClick={() => setSelectedId(r.id)}
                        className={`cursor-pointer transition-colors ${selectedId === r.id ? 'bg-[#fff5f5]' : 'hover:bg-[#fafafa]'}`}
                      >
                        {/* Misafir */}
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <GuestAvatar initials={r.guest.initials} color={r.guest.color} />
                            <div>
                              <p className="text-[13px] font-[800] text-[#1a1a2e]">{r.guest.name}</p>
                              <p className="text-[11px] text-[#94a3b8]">{r.guest.phone}</p>
                            </div>
                          </div>
                        </td>
                        {/* Tarih & Saat */}
                        <td className="px-4 py-3">
                          <p className="text-[13px] font-[700] text-[#1a1a2e]">{r.dateStr}</p>
                          <p className="text-[12px] text-[#64748b]">{r.time}</p>
                        </td>
                        {/* Kişi */}
                        <td className="px-4 py-3 text-[13px] font-[700] text-[#1a1a2e]">{r.people} Kişi</td>
                        {/* Durum */}
                        <td className="px-4 py-3">
                          <span className={`rounded-full px-2.5 py-1 text-[11px] font-[800] ${STATUS_STYLES[r.status]}`}>
                            {r.status}
                          </span>
                        </td>
                        {/* Kanal */}
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1.5">
                            <ChannelIcon channel={r.channel} />
                            <span className="text-[12px] font-[700] text-[#475569]">{r.channel}</span>
                          </div>
                        </td>
                        {/* Not */}
                        <td className="px-4 py-3">
                          {r.hasNote ? (
                            <span className="text-[#64748b]"><NoteIcon className="h-4 w-4" /></span>
                          ) : (
                            <span className="text-[#e2e8f0]"><NoteIcon className="h-4 w-4" /></span>
                          )}
                        </td>
                        {/* İşlemler */}
                        <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
                          <button className="flex h-7 w-7 items-center justify-center rounded-lg text-[#94a3b8] hover:bg-[#f1f5f9]">
                            <DotsIcon className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between border-t border-[#f0f0f0] px-5 py-3">
              <span className="text-xs text-[#94a3b8]">Toplam {total} rezervasyon</span>
              <div className="flex items-center gap-1">
                <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#e2e8f0] text-[#94a3b8] hover:bg-[#f8fafc]">
                  <ChevLeftIcon className="h-3.5 w-3.5" />
                </button>
                <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#dc2626] bg-[#dc2626] text-[11px] font-[900] text-white">1</button>
                <button className="flex h-7 w-7 items-center justify-center rounded-lg border border-[#e2e8f0] text-[#64748b] hover:bg-[#f8fafc]">
                  <ChevRightIcon className="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* ── Right: Detail panel ────────────────────────────────── */}
        {selected && (
          <div className="flex flex-col gap-4">
            <div className="rounded-2xl border border-[#f0f0f0] bg-white shadow-sm">
              {/* Detail header */}
              <div className="flex items-center justify-between border-b border-[#f0f0f0] px-4 py-3">
                <span className="text-[13px] font-[800] text-[#1a1a2e]">Rezervasyon Detayı</span>
                <span className={`rounded-full px-2.5 py-1 text-[11px] font-[800] ${STATUS_STYLES[selected.status]}`}>
                  {selected.status}
                </span>
              </div>

              <div className="p-5">
                {/* Guest info */}
                <div className="flex items-center gap-3">
                  <GuestAvatar initials={selected.guest.initials} color={selected.guest.color} size={48} />
                  <div>
                    <p className="text-[15px] font-[900] text-[#1a1a2e]">{selected.guest.name}</p>
                    <p className="text-[13px] text-[#64748b]">{selected.guest.phone}</p>
                  </div>
                </div>

                {/* Quick actions */}
                <div className="mt-4 grid grid-cols-3 gap-2">
                  <a href={`tel:${selected.guest.phone.replace(/\s/g,'')}`}
                    className="flex flex-col items-center gap-1 rounded-xl border border-[#e2e8f0] py-2.5 text-[11px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors">
                    <PhoneIcon className="h-4 w-4 text-[#64748b]" /> Ara
                  </a>
                  <button className="flex flex-col items-center gap-1 rounded-xl border border-[#e2e8f0] py-2.5 text-[11px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors">
                    <MessageIcon className="h-4 w-4 text-[#64748b]" /> Mesaj
                  </button>
                  <button className="flex flex-col items-center gap-1 rounded-xl border border-[#e2e8f0] py-2.5 text-[11px] font-[800] text-[#475569] hover:bg-[#f8fafc] transition-colors">
                    <MailIcon className="h-4 w-4 text-[#64748b]" /> E-posta
                  </button>
                </div>

                {/* Detail rows */}
                <div className="mt-5 space-y-3 border-t border-[#f0f0f0] pt-4">
                  <DetailRow icon={<HashIcon className="h-4 w-4" />} label="Rezervasyon No" value={selected.no} mono />
                  <DetailRow icon={<CalendarSmIcon className="h-4 w-4" />} label="Tarih & Saat"
                    value={`${selected.dateStr}, ${selected.day} ${selected.time}`} />
                  <DetailRow icon={<UsersIcon className="h-4 w-4" />} label="Kişi Sayısı" value={`${selected.people} Kişi`} />
                  <DetailRow icon={<ChannelIcon channel={selected.channel} />} label="Kanal" value={selected.channel} />
                  <DetailRow icon={<ClockSmIcon className="h-4 w-4" />} label="Oluşturma" value={selected.createdAt} />
                </div>

                {/* Note */}
                {selected.note && (
                  <div className="mt-4 border-t border-[#f0f0f0] pt-4">
                    <p className="mb-1.5 text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">Not</p>
                    <div className="flex items-start gap-2">
                      <NoteIcon className="mt-0.5 h-4 w-4 shrink-0 text-[#94a3b8]" />
                      <p className="text-[13px] text-[#475569]">{selected.note}</p>
                    </div>
                  </div>
                )}

                {/* Table preference */}
                {selected.tablePreference && (
                  <div className="mt-3">
                    <p className="mb-1.5 text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">Masa Tercihi</p>
                    <div className="flex items-center gap-2">
                      <TableIcon className="h-4 w-4 text-[#94a3b8]" />
                      <p className="text-[13px] text-[#475569]">{selected.tablePreference}</p>
                    </div>
                  </div>
                )}

                {/* Special request */}
                {selected.specialRequest && (
                  <div className="mt-3">
                    <p className="mb-1.5 text-[11px] font-[800] uppercase tracking-wider text-[#94a3b8]">Özel İstek</p>
                    <div className="flex items-center gap-2">
                      <StarSmIcon className="h-4 w-4 text-[#94a3b8]" />
                      <p className="text-[13px] text-[#475569]">{selected.specialRequest}</p>
                    </div>
                  </div>
                )}

                {/* Action buttons */}
                <div className="mt-5 flex flex-col gap-2 border-t border-[#f0f0f0] pt-4">
                  <button className="w-full rounded-xl bg-[#dc2626] py-2.5 text-[13px] font-[800] text-white transition hover:opacity-90">
                    Rezervasyonu Düzenle
                  </button>
                  {selected.status !== 'İptal Edildi' && (
                    <button
                      onClick={() => handleCancel(selected.id)}
                      className="flex w-full items-center justify-center gap-2 rounded-xl border border-[#fecaca] py-2.5 text-[13px] font-[800] text-[#dc2626] transition hover:bg-[#fff1f2]"
                    >
                      <XSmIcon className="h-4 w-4" /> Rezervasyonu İptal Et
                    </button>
                  )}
                  <button className="flex w-full items-center justify-center gap-2 rounded-xl border border-[#e2e8f0] py-2.5 text-[13px] font-[800] text-[#475569] transition hover:bg-[#f8fafc]">
                    <NoteIcon className="h-4 w-4" /> Not Ekle
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom banner */}
      <div className="mt-5 flex items-center gap-4 rounded-2xl border border-blue-200 bg-blue-50 px-5 py-4">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-100">
          <CalendarStatIcon className="h-5 w-5 text-blue-600" />
        </div>
        <div className="flex-1">
          <p className="text-[13px] font-[800] text-[#1a1a2e]">Rezervasyonlarınızı kolayca yönetin</p>
          <p className="text-[12px] text-[#64748b]">Rezervasyonları anlık olarak takip edin, onaylayın veya iptal edin.</p>
        </div>
        <Link href="/owner/settings" className="shrink-0 flex items-center gap-1.5 rounded-xl border border-blue-300 bg-white px-4 py-2 text-[12px] font-[800] text-[#1a1a2e] transition hover:bg-blue-50">
          <SettingsIcon className="h-4 w-4" /> Rezervasyon Ayarları →
        </Link>
      </div>
    </div>
  );
}

// ── Sub-components ────────────────────────────────────────────────────────────

function GuestAvatar({ initials, color, size = 38 }: { initials: string; color: string; size?: number }) {
  return (
    <div
      className="flex shrink-0 items-center justify-center rounded-full font-[900] text-white"
      style={{ width: size, height: size, backgroundColor: color, fontSize: size * 0.34 }}
    >
      {initials}
    </div>
  );
}

function StatCard({ icon, color, bg, label, value, sub }: {
  icon: React.ReactNode; color: string; bg: string; label: string; value: string | number; sub: string;
}) {
  return (
    <div className="rounded-[20px] border border-[#f0f0f0] bg-white p-4 shadow-sm">
      <div className="mb-2 flex items-center gap-2">
        <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${bg} ${color}`}>
          {icon}
        </div>
        <span className="text-[11px] font-[700] leading-tight text-[#64748b]">{label}</span>
      </div>
      <p className="text-xl font-[900] text-[#1a1a2e]">{value}</p>
      <p className="mt-0.5 text-[11px] text-[#94a3b8]">{sub}</p>
    </div>
  );
}

function DetailRow({ icon, label, value, mono }: { icon: React.ReactNode; label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-3">
      <div className="flex items-center gap-1.5 shrink-0">
        <span className="text-[#94a3b8]">{icon}</span>
        <span className="text-[12px] font-[700] text-[#94a3b8]">{label}</span>
      </div>
      <span className={`text-right text-[12px] font-[800] text-[#1a1a2e] ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  );
}

function ChannelIcon({ channel }: { channel: Channel }) {
  if (channel === 'Yeedoy App') {
    return (
      <span className="flex h-5 w-5 items-center justify-center rounded bg-[#dc2626] text-[9px] font-[900] text-white">Y</span>
    );
  }
  if (channel === 'Web Sitesi') {
    return <GlobeIcon className="h-4 w-4 text-blue-500" />;
  }
  return <PhoneIcon className="h-4 w-4 text-green-600" />;
}

// ── Icons ─────────────────────────────────────────────────────────────────────

function SearchIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>;
}
function FilterIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>;
}
function ChevLeftIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="15 18 9 12 15 6"/></svg>;
}
function ChevRightIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="9 6 15 12 9 18"/></svg>;
}
function DotsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>;
}
function NoteIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>;
}
function PhoneIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.42 2 2 0 0 1 3.6 1.27h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L7.91 9a16 16 0 0 0 6 6l.92-.92a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 21.73 16.92z"/></svg>;
}
function MessageIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>;
}
function MailIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>;
}
function HashIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="4" y1="9" x2="20" y2="9"/><line x1="4" y1="15" x2="20" y2="15"/><line x1="10" y1="3" x2="8" y2="21"/><line x1="16" y1="3" x2="14" y2="21"/></svg>;
}
function UsersIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
}
function ClockSmIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
}
function TableIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>;
}
function StarSmIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>;
}
function XSmIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>;
}
function GlobeIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>;
}
function SettingsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
}

// ── Stat card icons ───────────────────────────────────────────────────────────
function CalendarStatIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>;
}
function CalendarSmIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>;
}
function ClockIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
}
function CheckCircleIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>;
}
function XCircleIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>;
}
function WalletIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M20 7H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>;
}
