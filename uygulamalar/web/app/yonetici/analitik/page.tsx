import type { Metadata } from 'next';
import Link from 'next/link';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { createSupabaseServiceClient } from '@/src/lib/taban/hizmet';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { MetricCard } from '@/src/ui/bilesenler/olcum-karti';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { DisaAktarButonu } from './disa-aktar-butonu';
import { TarihSecici } from './tarih-secici';
import { yuzdeDegisim, gunEtiketi, KAYNAK_ETIKETLERI, kaynaktanPlatformCikar, PLATFORM_ETIKETLERI, GUN_ETIKETLERI, type Platform } from './analitik-yardimcilari';

export const metadata: Metadata = {
  title: 'Analitik | Yonetici Paneli',
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ tarih?: string }> };

type OlayRow = {
  id: string; event_name: string; source: string | null; business_id: string | null;
  client_id: string | null; user_id: string | null; created_at: string;
};

export default async function AdminAnalyticsPage({ searchParams }: Props) {
  const yetkili = await hasPermission('page:analitik');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Analitik" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Analitik" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const { tarih = 'all' } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const sb = (createSupabaseServiceClient() ?? supabase) as any;

  const now = Date.now();
  const gunBasi30 = new Date(now - 30 * 86400000).toISOString();
  const gunBasi60 = new Date(now - 60 * 86400000).toISOString();

  const [
    totalUsersRes, totalBusinessesRes, totalReviewsRes, totalFavoritesRes,
    newUsers30Res, newUsersPrev30Res, newBusinesses30Res, newBusinessesPrev30Res,
    reviews30Res, reviewsPrev30Res, favorites30Res, favoritesPrev30Res,
    ownerClaimsRes, eventsRes,
    recentReviewsRes, recentFavoritesRes, recentAuditRes, recentSubmissionsRes,
    allUsersRes,
  ] = await Promise.all([
    sb.from('user_profiles').select('user_id', { count: 'exact', head: true }),
    sb.from('businesses').select('id', { count: 'exact', head: true }),
    sb.from('reviews').select('id', { count: 'exact', head: true }),
    sb.from('favorites').select('id', { count: 'exact', head: true }),
    sb.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', gunBasi30),
    sb.from('user_profiles').select('user_id', { count: 'exact', head: true }).gte('created_at', gunBasi60).lt('created_at', gunBasi30),
    sb.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi30),
    sb.from('businesses').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi60).lt('created_at', gunBasi30),
    sb.from('reviews').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi30),
    sb.from('reviews').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi60).lt('created_at', gunBasi30),
    sb.from('favorites').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi30),
    sb.from('favorites').select('id', { count: 'exact', head: true }).gte('created_at', gunBasi60).lt('created_at', gunBasi30),
    sb.from('owner_claims').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    sb.from('analytics_events').select('id, event_name, source, business_id, client_id, user_id, created_at').order('created_at', { ascending: false }).limit(5000),
    sb.from('reviews').select('id, business_id, rating, created_at').order('created_at', { ascending: false }).limit(5),
    sb.from('favorites').select('id, business_id, created_at').order('created_at', { ascending: false }).limit(5),
    sb.from('admin_audit_log').select('id, action, target_table, target_id, created_at').order('created_at', { ascending: false }).limit(5).then((r: any) => r).catch(() => ({ data: [] })),
    sb.from('business_submissions').select('id, name, created_at').order('created_at', { ascending: false }).limit(5),
    sb.from('user_profiles').select('user_id, created_at').order('created_at', { ascending: false }).limit(2000),
  ]);

  const toplamKullanici = totalUsersRes.count ?? 0;
  const toplamIsletme = totalBusinessesRes.count ?? 0;
  const toplamYorum = totalReviewsRes.count ?? 0;
  const toplamBegeni = totalFavoritesRes.count ?? 0;
  const allEvents = (eventsRes.data ?? []) as OlayRow[];
  const toplamZiyaret = allEvents.length;
  const tekilZiyaretciSeti = new Set(allEvents.map((e) => e.client_id ?? e.user_id).filter(Boolean));
  const tekilZiyaretci = tekilZiyaretciSeti.size;

  const events30 = allEvents.filter((e) => e.created_at >= gunBasi30).length;
  const eventsPrev30 = allEvents.filter((e) => e.created_at >= gunBasi60 && e.created_at < gunBasi30).length;
  const visitors30 = new Set(allEvents.filter((e) => e.created_at >= gunBasi30).map((e) => e.client_id ?? e.user_id).filter(Boolean)).size;
  const visitorsPrev30 = new Set(allEvents.filter((e) => e.created_at >= gunBasi60 && e.created_at < gunBasi30).map((e) => e.client_id ?? e.user_id).filter(Boolean)).size;

  // ── Seçili döneme göre filtreli veri ──
  const sinirTarih = tarih === '7d' ? now - 7 * 86400000 : tarih === '30d' ? now - 30 * 86400000 : tarih === '90d' ? now - 90 * 86400000 : 0;
  const filtreliEvents = sinirTarih > 0 ? allEvents.filter((e) => new Date(e.created_at).getTime() >= sinirTarih) : allEvents;

  // Günlük trend (en eski gerçek olaydan bugüne, ya da seçili pencere)
  const trendBaslangic = sinirTarih > 0 ? new Date(sinirTarih) : (filtreliEvents.length > 0 ? new Date(Math.min(...filtreliEvents.map((e) => new Date(e.created_at).getTime()))) : new Date(now - 7 * 86400000));
  const gunSayisi = Math.max(1, Math.min(90, Math.ceil((now - trendBaslangic.getTime()) / 86400000) + 1));
  const gunlukZiyaret: Record<string, number> = {};
  const gunlukTekil: Record<string, Set<string>> = {};
  const gunlukIsletmeGoruntuleme: Record<string, number> = {};
  for (const e of filtreliEvents) {
    const gun = gunEtiketi(new Date(e.created_at));
    gunlukZiyaret[gun] = (gunlukZiyaret[gun] ?? 0) + 1;
    if (!gunlukTekil[gun]) gunlukTekil[gun] = new Set();
    const kimlik = e.client_id ?? e.user_id;
    if (kimlik) gunlukTekil[gun].add(kimlik);
    if (e.event_name === 'business_impression') gunlukIsletmeGoruntuleme[gun] = (gunlukIsletmeGoruntuleme[gun] ?? 0) + 1;
  }
  const trendVerisi: { label: string; ziyaret: number; tekilZiyaretci: number; isletmeGoruntuleme: number }[] = [];
  for (let i = gunSayisi - 1; i >= 0; i--) {
    const d = new Date(now - i * 86400000);
    const label = gunEtiketi(d);
    trendVerisi.push({
      label,
      ziyaret: gunlukZiyaret[label] ?? 0,
      tekilZiyaretci: gunlukTekil[label]?.size ?? 0,
      isletmeGoruntuleme: gunlukIsletmeGoruntuleme[label] ?? 0,
    });
  }

  // Yeni kullanıcı kayıtları — trend chart ile aynı gün aralığında
  const allUsers = (allUsersRes.data ?? []) as Array<{ user_id: string; created_at: string }>;
  const filtreliUsers = sinirTarih > 0 ? allUsers.filter((u) => new Date(u.created_at).getTime() >= sinirTarih) : allUsers;
  const gunlukKayit: Record<string, number> = {};
  for (const u of filtreliUsers) {
    const gun = gunEtiketi(new Date(u.created_at));
    gunlukKayit[gun] = (gunlukKayit[gun] ?? 0) + 1;
  }
  const kayitVerisi: { label: string; value: number }[] = trendVerisi.map((v) => ({ label: v.label, value: gunlukKayit[v.label] ?? 0 }));

  // Kaynak dağılımı
  const kaynakSayilari = new Map<string, number>();
  for (const e of filtreliEvents) {
    const k = e.source ?? 'diğer';
    kaynakSayilari.set(k, (kaynakSayilari.get(k) ?? 0) + 1);
  }
  const KAYNAK_RENKLERI = ['#2563eb', '#059669', '#d97706', '#7c3aed', '#dc2626', '#0891b2'];
  const kaynakDonutHam: Array<[string, number, string]> = Array.from(kaynakSayilari.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([k, n], i) => [KAYNAK_ETIKETLERI[k] ?? k, n, KAYNAK_RENKLERI[i % KAYNAK_RENKLERI.length]]);
  const kaynakDonutToplam = kaynakDonutHam.reduce((s, [, n]) => s + n, 0);

  // Platform dağılımı — analytics_events'te gerçek bir cihaz/platform sütunu yok, ama
  // source değerleri mobil (Flutter) ve web (Next.js) istemcilerinden ayrı isim uzayları
  // kullanıyor (bkz. kaynaktanPlatformCikar yorumu). Tanınmayan source → "Bilinmiyor".
  const platformSayilari: Record<Platform, number> = { mobil: 0, web: 0, bilinmiyor: 0 };
  for (const e of filtreliEvents) platformSayilari[kaynaktanPlatformCikar(e.source)] += 1;
  const PLATFORM_RENKLERI: Record<Platform, string> = { mobil: '#2563eb', web: '#059669', bilinmiyor: '#94a3b8' };
  const platformDonutHam: Array<[string, number, string]> = (['mobil', 'web', 'bilinmiyor'] as Platform[])
    .map((p) => [PLATFORM_ETIKETLERI[p], platformSayilari[p], PLATFORM_RENKLERI[p]])
    .filter(([, n]) => (n as number) > 0) as Array<[string, number, string]>;
  const platformDonutToplam = platformDonutHam.reduce((s, [, n]) => s + n, 0);

  // Popüler saatler — gün (Paz-Cmt) x saat (0-23) ızgarası, gerçek created_at'ten.
  // Not: gerçek hacim düşük ve platformun erken test/beta döneminden kalma; geniş
  // müşteri davranışı olarak değil, mevcut sınırlı gerçek kayıt olarak okunmalı.
  const isiHaritasi: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0));
  for (const e of filtreliEvents) {
    const d = new Date(e.created_at);
    isiHaritasi[d.getDay()][d.getHours()] += 1;
  }
  const isiMax = Math.max(...isiHaritasi.flat(), 1);

  // Kategori dağılımı (business_impression olayları → businesses.category)
  const impressionRows = filtreliEvents.filter((e) => e.event_name === 'business_impression' && e.business_id);
  const businessIds = Array.from(new Set(impressionRows.map((e) => e.business_id as string)));
  const categoryByBusiness = new Map<string, string>();
  if (businessIds.length > 0) {
    const { data: bizRows } = await sb.from('businesses').select('id, category').in('id', businessIds);
    for (const b of (bizRows ?? []) as Array<{ id: string; category: string }>) categoryByBusiness.set(b.id, b.category ?? 'Diğer');
  }
  const kategoriSayilari = new Map<string, number>();
  for (const e of impressionRows) {
    const kat = categoryByBusiness.get(e.business_id as string) ?? 'Diğer';
    kategoriSayilari.set(kat, (kategoriSayilari.get(kat) ?? 0) + 1);
  }
  const kategoriListesi = Array.from(kategoriSayilari.entries()).sort((a, b) => b[1] - a[1]).slice(0, 6);
  const kategoriMax = Math.max(...kategoriListesi.map(([, n]) => n), 1);
  const kategoriToplam = kategoriListesi.reduce((s, [, n]) => s + n, 0);

  // Kullanıcı etkileşim özeti
  const kullaniciBasiYorum = toplamKullanici > 0 ? (toplamYorum / toplamKullanici).toFixed(1) : '0';
  const kullaniciBasiFavori = toplamKullanici > 0 ? (toplamBegeni / toplamKullanici).toFixed(1) : '0';
  const sahiplenmeOrani = toplamIsletme > 0 ? ((ownerClaimsRes.count ?? 0) / toplamIsletme) * 100 : 0;

  // Son aktiviteler — gerçek, karışık kaynaklardan, "canlı" iddiası yok
  type Aktivite = { id: string; text: string; sub: string; createdAt: string; tone: string };
  const aktiviteler: Aktivite[] = [
    ...((recentReviewsRes.data ?? []) as any[]).map((r) => ({ id: `review:${r.id}`, text: 'Yeni yorum yapıldı', sub: `${r.rating}/5 puan`, createdAt: r.created_at, tone: 'blue' })),
    ...((recentFavoritesRes.data ?? []) as any[]).map((f) => ({ id: `fav:${f.id}`, text: 'Favoriye eklendi', sub: '', createdAt: f.created_at, tone: 'pink' })),
    ...((recentAuditRes.data ?? []) as any[]).map((a) => ({ id: `audit:${a.id}`, text: `${a.action} işlemi`, sub: a.target_table ?? '', createdAt: a.created_at, tone: 'purple' })),
    ...((recentSubmissionsRes.data ?? []) as any[]).map((s) => ({ id: `sub:${s.id}`, text: 'Yeni işletme talebi', sub: s.name, createdAt: s.created_at, tone: 'orange' })),
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 8);

  const queryBase = tarih !== 'all' ? `?tarih=${tarih}` : '';

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Analitik"
        description="Platform performansını ve kullanıcı davranışlarını gerçek verilerle inceleyin."
        actions={
          <div className="flex items-center gap-2">
            <form method="get" className="flex items-center gap-2">
              <TarihSecici value={tarih} />
            </form>
            <DisaAktarButonu trendVerisi={trendVerisi} />
          </div>
        }
      />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="flex flex-col gap-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-6">
            <MetricCard title="Toplam Kullanıcı" value={toplamKullanici.toLocaleString('tr-TR')} tone="blue" icon={<UsersIcon />} trend={{ value: yuzdeDegisim(newUsers30Res.count ?? 0, newUsersPrev30Res.count ?? 0), label: 'Son 30 gün' }} />
            <MetricCard title="Toplam İşletme" value={toplamIsletme.toLocaleString('tr-TR')} tone="primary" icon={<BuildingIcon />} trend={{ value: yuzdeDegisim(newBusinesses30Res.count ?? 0, newBusinessesPrev30Res.count ?? 0), label: 'Son 30 gün' }} />
            <MetricCard title="Toplam Ziyaret" value={toplamZiyaret.toLocaleString('tr-TR')} subtitle="işletme/menü görüntüleme olayı" tone="green" icon={<EyeIcon />} trend={{ value: yuzdeDegisim(events30, eventsPrev30), label: 'Son 30 gün' }} />
            <MetricCard title="Tekil Ziyaretçi" value={tekilZiyaretci.toLocaleString('tr-TR')} tone="purple" icon={<UserCheckIcon />} trend={{ value: yuzdeDegisim(visitors30, visitorsPrev30), label: 'Son 30 gün' }} />
            <MetricCard title="Toplam Beğeni" value={toplamBegeni.toLocaleString('tr-TR')} tone="pink" icon={<HeartIcon />} trend={{ value: yuzdeDegisim(favorites30Res.count ?? 0, favoritesPrev30Res.count ?? 0), label: 'Son 30 gün' }} />
            <MetricCard title="Toplam Yorum" value={toplamYorum.toLocaleString('tr-TR')} tone="orange" icon={<MessageIcon />} trend={{ value: yuzdeDegisim(reviews30Res.count ?? 0, reviewsPrev30Res.count ?? 0), label: 'Son 30 gün' }} />
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            <PanelBolumKarti title="Ziyaretçi ve Görüntüleme Trendi" description={`${filtreliEvents.length.toLocaleString('tr-TR')} olay · seçili dönem`}>
              <TrendGrafik veriler={trendVerisi} />
              <div className="mt-3 flex flex-wrap items-center gap-4 text-[11px] font-bold text-muted">
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-blue-600" />Ziyaret</span>
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-emerald-600" />Tekil Ziyaretçi</span>
                <span className="flex items-center gap-1.5"><span className="h-2 w-2 rounded-full bg-violet-600" />İşletme Görüntüleme</span>
              </div>
            </PanelBolumKarti>

            <PanelBolumKarti title="Platform Dağılımı" description="source alanından çıkarıldı">
              {platformDonutToplam === 0 ? <p className="text-xs text-muted">Seçili dönemde veri yok.</p> : <KaynakDonut veriler={platformDonutHam} toplam={platformDonutToplam} />}
            </PanelBolumKarti>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            <PanelBolumKarti title="Popüler Saatler" description="Gün × saat, gerçek olay sayısı">
              {filtreliEvents.length === 0 ? (
                <p className="text-xs text-muted">Seçili dönemde veri yok.</p>
              ) : (
                <IsiHaritasi veriler={isiHaritasi} maxDeger={isiMax} />
              )}
              <p className="mt-3 text-[11px] text-muted">Düşük hacim ve platformun erken test döneminden geldiği için geniş müşteri davranışı olarak değil, mevcut sınırlı gerçek kayıt olarak okuyun.</p>
            </PanelBolumKarti>

            <PanelBolumKarti title="Kaynak Dağılımı" description="analytics_events.source">
              {kaynakDonutToplam === 0 ? <p className="text-xs text-muted">Seçili dönemde veri yok.</p> : <KaynakDonut veriler={kaynakDonutHam} toplam={kaynakDonutToplam} />}
            </PanelBolumKarti>
          </div>

          <PanelBolumKarti title="Kullanıcı Etkileşim Özeti">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <OzetKarti label="Kullanıcı Başına Yorum" deger={kullaniciBasiYorum} aciklama={`${toplamYorum} yorum / ${toplamKullanici} kullanıcı`} />
              <OzetKarti label="Kullanıcı Başına Favori" deger={kullaniciBasiFavori} aciklama={`${toplamBegeni} favori / ${toplamKullanici} kullanıcı`} />
              <OzetKarti label="İşletme Sahiplenme Oranı" deger={`%${sahiplenmeOrani.toFixed(2)}`} aciklama={`${ownerClaimsRes.count ?? 0} onaylı sahiplik / ${toplamIsletme} işletme`} />
            </div>
          </PanelBolumKarti>

          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            <PanelBolumKarti title="En Çok Görüntülenen Kategoriler" description="business_impression olayları">
              {kategoriListesi.length === 0 ? (
                <p className="text-xs text-muted">Seçili dönemde veri yok.</p>
              ) : (
                <div className="flex flex-col gap-3">
                  {kategoriListesi.map(([kat, n]) => (
                    <div key={kat} className="flex items-center gap-3">
                      <span className="w-28 shrink-0 truncate text-xs font-bold text-textStrong">{kat}</span>
                      <div className="h-2 flex-1 overflow-hidden rounded-full bg-black/6">
                        <div className="h-full rounded-full bg-primary" style={{ width: `${(n / kategoriMax) * 100}%` }} />
                      </div>
                      <span className="w-20 shrink-0 text-right text-xs font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{kategoriToplam > 0 ? Math.round((n / kategoriToplam) * 100) : 0}</span>
                    </div>
                  ))}
                </div>
              )}
            </PanelBolumKarti>

            <PanelBolumKarti title="Son Aktiviteler" description="Gerçek zamanlı değil — en son gerçekleşenler">
              {aktiviteler.length === 0 ? (
                <p className="text-xs text-muted">Henüz aktivite yok.</p>
              ) : (
                <div className="flex flex-col gap-3">
                  {aktiviteler.map((a) => (
                    <div key={a.id} className="flex flex-col gap-0.5">
                      <p className="text-xs font-bold text-textStrong">{a.text}{a.sub ? ` · ${a.sub}` : ''}</p>
                      <p className="text-[11px] text-muted">{new Date(a.createdAt).toLocaleString('tr-TR')}</p>
                    </div>
                  ))}
                </div>
              )}
            </PanelBolumKarti>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
            <PanelBolumKarti title="Yeni Kullanıcı Kayıtları" description={`Toplam ${filtreliUsers.length.toLocaleString('tr-TR')} kayıt · seçili dönem`}>
              <YeniKullaniciBarGrafik veriler={kayitVerisi} />
            </PanelBolumKarti>

            <PanelBolumKarti title="Raporları Keşfet">
              <div className="flex flex-col gap-2">
                <Link href="/yonetici/kullanicilar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                  Kullanıcılar <ArrowIcon />
                </Link>
                <Link href="/yonetici/isletmeler" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                  İşletmeler <ArrowIcon />
                </Link>
                <Link href="/yonetici/konumlar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                  Konumlar <ArrowIcon />
                </Link>
                <Link href="/yonetici/olaylar" className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
                  Olaylar <ArrowIcon />
                </Link>
              </div>
            </PanelBolumKarti>
          </div>

          <div className="rounded-2xl border border-blue-200 bg-blue-50 p-4">
            <p className="mb-2 text-sm font-black text-blue-900">Bilgilendirme</p>
            <ul className="flex flex-col gap-1.5 text-xs text-blue-800">
              <li>• Bu sayfadaki her sayı gerçek tablo verisidir — analytics_events, reviews, favorites, user_profiles, businesses.</li>
              <li>• Platform Dağılımı için ayrı bir cihaz/platform sütunu tutulmuyor — mobil (Flutter) ve web (Next.js) uygulamalarının kendi kod tabanlarında kullandığı bilinen source değerlerinden çıkarılıyor. Tanınmayan bir source &quot;Bilinmiyor&quot; grubuna düşer.</li>
              <li>• analytics_events kayıtları 1 Temmuz 2026&apos;dan beri durmuş durumda ve platformun erken test/beta döneminden — geniş müşteri davranışı olarak değil, mevcut sınırlı gerçek kayıt olarak okuyun.</li>
              <li>• Platform henüz erken aşamada ({toplamKullanici} kullanıcı) — oranlar küçük örneklemle hesaplanıyor.</li>
            </ul>
          </div>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}

function OzetKarti({ label, deger, aciklama }: { label: string; deger: string; aciklama: string }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-1 text-2xl font-black text-textStrong">{deger}</p>
      <p className="mt-0.5 text-[11px] text-muted">{aciklama}</p>
    </div>
  );
}

function TrendGrafik({ veriler }: { veriler: { label: string; ziyaret: number; tekilZiyaretci: number; isletmeGoruntuleme: number }[] }) {
  const W = 720, H = 220;
  const pad = { l: 8, r: 8, t: 12, b: 20 };
  const innerW = W - pad.l - pad.r;
  const innerH = H - pad.t - pad.b;
  const maxVal = Math.max(...veriler.map((v) => Math.max(v.ziyaret, v.tekilZiyaretci, v.isletmeGoruntuleme)), 1);
  const stepX = innerW / Math.max(veriler.length - 1, 1);
  const scaleY = (v: number) => innerH - (v / maxVal) * innerH;
  const pathFor = (key: 'ziyaret' | 'tekilZiyaretci' | 'isletmeGoruntuleme') =>
    veriler.map((v, i) => `${i === 0 ? 'M' : 'L'}${pad.l + i * stepX},${pad.t + scaleY(v[key])}`).join(' ');

  const gosterilenEtiketler = veriler.filter((_, i) => i % Math.max(1, Math.ceil(veriler.length / 8)) === 0);

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full">
      <path d={pathFor('ziyaret')} fill="none" stroke="#2563eb" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
      <path d={pathFor('tekilZiyaretci')} fill="none" stroke="#059669" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
      <path d={pathFor('isletmeGoruntuleme')} fill="none" stroke="#7c3aed" strokeWidth="2" strokeDasharray="4 3" strokeLinejoin="round" strokeLinecap="round" />
      {gosterilenEtiketler.map((v) => {
        const i = veriler.indexOf(v);
        return (
          <text key={v.label} x={pad.l + i * stepX} y={H - 4} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">{v.label}</text>
        );
      })}
    </svg>
  );
}

function KaynakDonut({ veriler, toplam }: { veriler: Array<[string, number, string]>; toplam: number }) {
  const R = 60, CX = 70, CY = 70, STROKE = 22;
  const CIRCUM = 2 * Math.PI * R;
  const uzunluklar = veriler.map(([, n]) => (n / toplam) * CIRCUM);
  const offsetler = uzunluklar.reduce<number[]>((acc, u, i) => { acc.push(i === 0 ? 0 : acc[i - 1] + uzunluklar[i - 1]); return acc; }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg viewBox="0 0 140 140" width="140" height="140">
        <g transform={`rotate(-90 ${CX} ${CY})`}>
          {veriler.map(([label, , renk], i) => (
            <circle key={label} cx={CX} cy={CY} r={R} fill="none" stroke={renk} strokeWidth={STROKE} strokeDasharray={`${uzunluklar[i]} ${CIRCUM - uzunluklar[i]}`} strokeDashoffset={-offsetler[i]} />
          ))}
        </g>
        <text x={CX} y={CY - 4} textAnchor="middle" fontSize="18" fontWeight="900" fill="var(--yd-color-text-strong)" fontFamily="inherit">{toplam.toLocaleString('tr-TR')}</text>
        <text x={CX} y={CY + 14} textAnchor="middle" fontSize="9" fill="var(--yd-color-muted)" fontFamily="inherit">Toplam</text>
      </svg>
      <div className="flex w-full flex-col gap-1.5">
        {veriler.map(([label, n, renk]) => (
          <div key={label} className="flex items-center justify-between gap-2 text-[11px]">
            <span className="flex min-w-0 items-center gap-1.5 font-bold text-textStrong">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ background: renk }} />
              <span className="truncate">{label}</span>
            </span>
            <span className="shrink-0 font-extrabold text-muted">{n.toLocaleString('tr-TR')} · %{Math.round((n / toplam) * 100)}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function isiRengi(oran: number): string {
  if (oran === 0) return 'transparent';
  const stops: Array<[number, string]> = [[0, '#dbeafe'], [0.5, '#60a5fa'], [1, '#1d4ed8']];
  for (let i = 0; i < stops.length - 1; i++) {
    const [t0, c0] = stops[i];
    const [t1, c1] = stops[i + 1];
    if (oran >= t0 && oran <= t1) {
      const t = t1 === t0 ? 0 : (oran - t0) / (t1 - t0);
      const a = parseInt(c0.slice(1), 16), b = parseInt(c1.slice(1), 16);
      const ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
      const br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
      const r = Math.round(ar + (br - ar) * t), g = Math.round(ag + (bg - ag) * t), bl = Math.round(ab + (bb - ab) * t);
      return `#${((1 << 24) + (r << 16) + (g << 8) + bl).toString(16).slice(1)}`;
    }
  }
  return stops[stops.length - 1][1];
}

function IsiHaritasi({ veriler, maxDeger }: { veriler: number[][]; maxDeger: number }) {
  const saatEtiketleri = [0, 3, 6, 9, 12, 15, 18, 21];
  return (
    <div className="overflow-x-auto">
      <div className="min-w-[520px]">
        <div className="flex gap-1 pl-8">
          {Array.from({ length: 24 }, (_, h) => (
            <div key={h} className="flex-1 text-center text-[9px] font-bold text-muted">{saatEtiketleri.includes(h) ? h.toString().padStart(2, '0') : ''}</div>
          ))}
        </div>
        {GUN_ETIKETLERI.map((gun, gunIdx) => (
          <div key={gun} className="flex items-center gap-1">
            <span className="w-7 shrink-0 text-[10px] font-bold text-muted">{gun}</span>
            {Array.from({ length: 24 }, (_, h) => {
              const n = veriler[gunIdx][h];
              const oran = n / maxDeger;
              return (
                <div
                  key={h}
                  className="h-4 flex-1 rounded-[2px]"
                  style={{ background: isiRengi(oran) }}
                  title={`${gun} ${h.toString().padStart(2, '0')}:00 — ${n} olay`}
                />
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}

function YeniKullaniciBarGrafik({ veriler }: { veriler: { label: string; value: number }[] }) {
  const maxVal = Math.max(...veriler.map((v) => v.value), 1);
  const gosterilenEtiketler = veriler.filter((_, i) => i % Math.max(1, Math.ceil(veriler.length / 10)) === 0);
  return (
    <div className="flex items-end gap-1" style={{ height: 160 }}>
      {veriler.map((v, i) => (
        <div key={`${v.label}-${i}`} className="flex flex-1 flex-col items-center justify-end gap-1" style={{ height: '100%' }}>
          <div className="w-full rounded-t-sm bg-emerald-500" style={{ height: `${(v.value / maxVal) * 100}%`, minHeight: v.value > 0 ? 2 : 0 }} title={`${v.label}: ${v.value}`} />
          {gosterilenEtiketler.includes(v) && <span className="text-[9px] font-bold text-muted">{v.label}</span>}
        </div>
      ))}
    </div>
  );
}

function ArrowIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12" /><polyline points="12 5 19 12 12 19" /></svg>; }
function UsersIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>; }
function BuildingIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2" /><path d="M9 22V12h6v10" /></svg>; }
function EyeIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>; }
function UserCheckIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" /><polyline points="17 11 19 13 23 9" /></svg>; }
function HeartIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>; }
function MessageIcon() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>; }
