'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

// ── Sabitler ─────────────────────────────────────────────────────────────────

const KATEGORILER = ['Restoran', 'Kafe', 'Kahvaltı', 'Tatlıcı', 'Mekan', 'Balık / Et'];

const SEHIRLER = [
  'Adana', 'Ankara', 'Antalya', 'Balıkesir', 'Bursa', 'Denizli', 'Diyarbakır',
  'Eskişehir', 'Gaziantep', 'İstanbul', 'İzmir', 'Kayseri', 'Kocaeli', 'Konya',
  'Malatya', 'Mersin', 'Muğla', 'Sakarya', 'Samsun', 'Tekirdağ', 'Trabzon',
];

const NEDENLER = [
  'Yeni açıldı, bilinmiyor',
  'Kaliteli ama çok bilinmiyor',
  'Favori mekanım',
  'Arkadaşlarıma önermek istiyorum',
  'Haritada görmek istiyorum',
  'Diğer',
];

// ── Tipler ────────────────────────────────────────────────────────────────────

type EslesenIsletme = {
  id: string;
  name: string;
  category: string | null;
  city: string | null;
  district: string | null;
  address: string | null;
  is_verified: boolean | null;
  slug: string | null;
  public_slug: string | null;
};

// ── Modal altyapısı ───────────────────────────────────────────────────────────

function Modal({ acik, kapat, children }: { acik: boolean; kapat: () => void; children: React.ReactNode }) {
  useEffect(() => {
    if (!acik) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.body.style.overflow = prev; };
  }, [acik]);

  useEffect(() => {
    if (!acik) return;
    function handleKey(e: KeyboardEvent) { if (e.key === 'Escape') kapat(); }
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [acik, kapat]);

  if (!acik) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      aria-modal="true" role="dialog"
    >
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={kapat} aria-hidden="true" />
      <div className="relative z-10 w-full max-w-2xl">{children}</div>
    </div>
  );
}

// ── Gizlilik Politikası Modal ─────────────────────────────────────────────────

function GizlilikModal({ acik, kapat }: { acik: boolean; kapat: () => void }) {
  return (
    <Modal acik={acik} kapat={kapat}>
      <div className="max-h-[85vh] overflow-hidden rounded-[24px] border border-border bg-card shadow-yd3 flex flex-col">
        {/* Başlık */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4 shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/10 text-primary">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
              </svg>
            </div>
            <h2 className="text-base font-[900] text-textStrong">Gizlilik Politikası</h2>
          </div>
          <button type="button" onClick={kapat} aria-label="Kapat"
            className="flex h-8 w-8 items-center justify-center rounded-lg text-muted transition hover:bg-cardAlt hover:text-textStrong">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* İçerik */}
        <div className="overflow-y-auto px-6 py-5 space-y-5 text-sm font-[700] text-text leading-relaxed">
          <p className="text-xs text-muted">Son güncelleme: 1 Ocak 2026</p>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">1. Toplanan Veriler</h3>
            <p className="text-muted">İşletme önerisi formunu doldururken işletme adı, konum bilgileri (şehir, ilçe, adres), iletişim bilgileri ve fotoğraf gibi veriler toplanır. Kimliğinizi doğrudan tanımlayan kişisel bilgi (ad-soyad, TC kimlik no) talep edilmez.</p>
          </section>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">2. Verilerin Kullanım Amacı</h3>
            <ul className="ml-4 list-disc space-y-1 text-muted">
              <li>Önerilen işletmenin platform üzerinde yayımlanıp yayımlanamayacağının değerlendirilmesi</li>
              <li>Mükerrer kayıtların önlenmesi</li>
              <li>Platform içerik kalitesinin korunması</li>
              <li>Yasal yükümlülüklerin yerine getirilmesi</li>
            </ul>
          </section>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">3. Verilerin Saklanması ve Güvenliği</h3>
            <p className="text-muted">Verileriniz, TLS şifrelemesi ve rol tabanlı erişim denetimleriyle güvence altına alınan Supabase altyapısında saklanır. Kişisel veriler, yasal zorunluluk veya açık onayınız olmaksızın üçüncü taraflarla paylaşılmaz.</p>
          </section>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">4. Çerezler ve Takip</h3>
            <p className="text-muted">Bu form işlevi için zorunlu çerezler dışında herhangi bir izleme çerezi kullanılmaz. Oturum bilgisi yalnızca güvenlik amacıyla tutulur.</p>
          </section>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">5. Haklarınız</h3>
            <p className="text-muted">KVKK kapsamında gönderdiğiniz verinin düzeltilmesini veya silinmesini talep etme hakkına sahipsiniz. Talepleriniz için <span className="font-[900] text-primary">destek@yeedoy.com</span> adresine ulaşabilirsiniz.</p>
          </section>

          <section>
            <h3 className="mb-2 font-[900] text-textStrong">6. İletişim</h3>
            <p className="text-muted">Gizlilik politikamıza ilişkin sorularınız için <span className="font-[900] text-primary">gizlilik@yeedoy.com</span> adresine yazabilirsiniz.</p>
          </section>
        </div>

        {/* Footer */}
        <div className="shrink-0 border-t border-border px-6 py-4">
          <button type="button" onClick={kapat}
            className="flex h-11 w-full items-center justify-center rounded-xl bg-primary text-sm font-[900] text-white transition hover:brightness-110">
            Anladım, Kapat
          </button>
        </div>
      </div>
    </Modal>
  );
}

// ── Eşleşen İşletmeler Modal ──────────────────────────────────────────────────

function EslesenIsletmelerModal({
  acik,
  kapat,
  isletmeler,
  onGonderDevam,
}: {
  acik: boolean;
  kapat: () => void;
  isletmeler: EslesenIsletme[];
  onGonderDevam: () => void;
}) {
  return (
    <Modal acik={acik} kapat={kapat}>
      <div className="max-h-[85vh] overflow-hidden rounded-[24px] border border-border bg-card shadow-yd3 flex flex-col">
        {/* Başlık */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4 shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-amber-100 text-amber-600">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
              </svg>
            </div>
            <div>
              <h2 className="text-base font-[900] text-textStrong">Benzer işletme bulundu</h2>
              <p className="text-xs font-[700] text-muted">Önermek istediğin işletme sistemde mevcut olabilir.</p>
            </div>
          </div>
          <button type="button" onClick={kapat} aria-label="Kapat"
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-muted transition hover:bg-cardAlt hover:text-textStrong">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* Açıklama */}
        <div className="shrink-0 px-6 pt-4 pb-2">
          <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3">
            <p className="text-sm font-[700] text-amber-800 leading-relaxed">
              Aşağıdaki işletme(ler) girdiğin bilgilerle örtüşüyor. Lütfen incele — bu işletme zaten platformumuzda listelenmiş olabilir. Farklı bir işletme önermek istiyorsan &quot;Yine de Gönder&quot; butonunu kullanabilirsin.
            </p>
          </div>
        </div>

        {/* İşletme listesi */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-3">
          {isletmeler.map((b) => {
            const isletmeUrl = b.public_slug
              ? `/m/${b.public_slug}`
              : b.slug
              ? `/isletme/${b.slug}`
              : null;
            return (
              <div key={b.id} className="rounded-2xl border border-border bg-bg p-4 shadow-yd1">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    {/* İsim + rozet */}
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-base font-[900] text-textStrong leading-tight">{b.name}</span>
                      {b.is_verified && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-[11px] font-[900] text-emerald-700">
                          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12"/>
                          </svg>
                          Doğrulandı
                        </span>
                      )}
                    </div>

                    {/* Kategori */}
                    {b.category && (
                      <span className="mt-1 inline-block rounded-lg bg-primary/8 px-2 py-0.5 text-[12px] font-[800] text-primary">
                        {b.category}
                      </span>
                    )}

                    {/* Konum satırı */}
                    <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1">
                      {(b.city || b.district) && (
                        <span className="flex items-center gap-1 text-[13px] font-[700] text-muted">
                          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0" aria-hidden="true">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>
                          </svg>
                          {[b.city, b.district].filter(Boolean).join(', ')}
                        </span>
                      )}
                      {b.address && (
                        <span className="text-[12px] font-[700] text-muted/70 truncate max-w-[260px]" title={b.address}>
                          {b.address}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Görüntüle butonu */}
                  {isletmeUrl && (
                    <a href={isletmeUrl} target="_blank" rel="noopener noreferrer"
                      className="shrink-0 flex items-center gap-1.5 rounded-xl border border-border bg-card px-3 py-2 text-xs font-[900] text-textStrong shadow-yd1 transition hover:border-primary/40 hover:text-primary">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                        <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>
                      </svg>
                      Görüntüle
                    </a>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer */}
        <div className="shrink-0 border-t border-border px-6 py-4 flex flex-col gap-2 sm:flex-row">
          <button type="button" onClick={kapat}
            className="flex h-11 flex-1 items-center justify-center rounded-xl border border-border bg-card text-sm font-[900] text-textStrong shadow-yd1 transition hover:border-primary/40 hover:text-primary">
            Öneriyi İptal Et
          </button>
          <button type="button" onClick={onGonderDevam}
            className="flex h-11 flex-[2] items-center justify-center gap-2 rounded-xl bg-primary text-sm font-[900] text-white shadow-sm transition hover:brightness-110">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
            </svg>
            Bu farklı bir işletme, yine de gönder
          </button>
        </div>
      </div>
    </Modal>
  );
}

// ── Yardımcı bileşenler ───────────────────────────────────────────────────────

function InputAlan({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="text-sm font-[800] text-textStrong">
        {label}{required && <span className="ml-0.5 text-primary">*</span>}
      </label>
      {children}
    </div>
  );
}

const inputCls = 'h-11 w-full rounded-xl border border-border bg-bg px-4 text-sm font-[700] text-textStrong placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15 transition';
const selectCls = `${inputCls} appearance-none pr-9 cursor-pointer`;

function SelectOk() {
  return (
    <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
        <path d="m6 9 6 6 6-6"/>
      </svg>
    </span>
  );
}

// ── Duplicate tarama yardımcısı ───────────────────────────────────────────────

function ilkAnlamliKelime(s: string): string {
  const DURDUR = new Set(['ve', 'ya', 'ile', 'bir', 'the', 'and', 'or', 'a', 'an', 'de', 'da']);
  const kelimeler = s.toLowerCase().trim().split(/\s+/);
  return kelimeler.find((k) => k.length >= 3 && !DURDUR.has(k)) ?? kelimeler[0] ?? s;
}

// ── Form bileşeni ─────────────────────────────────────────────────────────────

export function IsletmeOnerFormu() {
  const [form, setForm] = useState({
    name: '', category: '', city: '', district: '', neighborhood: '',
    address: '', mapsLink: '', phone: '', website: '', social: '', reason: '', notes: '',
  });
  const [onay1, setOnay1]         = useState(false);
  const [onay2, setOnay2]         = useState(false);
  const [loading, setLoading]     = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError]         = useState<string | null>(null);
  const [dragOver, setDragOver]   = useState(false);
  const [photos, setPhotos]       = useState<string[]>([]);
  const fileRef = useRef<HTMLInputElement>(null);

  // Modal state
  const [gizlilikAcik, setGizlilikAcik]       = useState(false);
  const [eslesenIsletmeler, setEslesenIsletmeler] = useState<EslesenIsletme[]>([]);
  const [eslesenGoster, setEslesenGoster]     = useState(false);

  function setField(key: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
      setForm((p) => ({ ...p, [key]: e.target.value }));
  }

  function handleFiles(files: FileList | null) {
    if (!files) return;
    setPhotos((p) => [...p, ...Array.from(files).map((f) => f.name)].slice(0, 5));
  }

  function resetForm() {
    setForm({ name:'', category:'', city:'', district:'', neighborhood:'', address:'', mapsLink:'', phone:'', website:'', social:'', reason:'', notes:'' });
    setOnay1(false); setOnay2(false); setPhotos([]); setError(null); setSubmitted(false);
    setEslesenIsletmeler([]); setEslesenGoster(false);
  }

  async function supabaseInsert() {
    const ekBilgiler = [
      form.neighborhood && `Mahalle: ${form.neighborhood}`,
      form.mapsLink     && `Harita: ${form.mapsLink}`,
      form.social       && `Sosyal: ${form.social}`,
      form.reason       && `Neden: ${form.reason}`,
      photos.length     && `Fotoğraflar: ${photos.join(', ')}`,
      form.notes        && `Not: ${form.notes}`,
    ].filter(Boolean).join('\n');

    const sb = createSupabaseBrowserClient();
    // Rate-limited RPC (submit_business_suggestion_v1) — 20260708000001 migration.
    // Direct anon INSERT policy kaldırıldı; artık sadece RPC üzerinden gönderim yapılır.
    const { error: err } = await (sb as any).rpc('submit_business_suggestion_v1', {
      p_name:     form.name.trim(),
      p_category: form.category,
      p_city:     form.city     || null,
      p_district: form.district || null,
      p_address:  form.address  || null,
      p_phone:    form.phone    || null,
      p_website:  form.website  || null,
      p_notes:    ekBilgiler    || null,
    });
    if (err) throw err;
    setSubmitted(true);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!onay1 || !onay2) { setError('Lütfen her iki onayı da verin.'); return; }
    setLoading(true); setError(null);

    try {
      const sb = createSupabaseBrowserClient();

      // ── Duplicate tarama ──────────────────────────────────────────────────
      const anahtar = ilkAnlamliKelime(form.name.trim());
      let query = (sb as any)
        .from('businesses')
        .select('id, name, category, city, district, address, is_verified, slug, public_slug')
        .eq('is_active', true)
        .ilike('name', `%${anahtar}%`);

      if (form.city) query = query.ilike('city', `%${form.city}%`);
      if (form.district) query = query.ilike('district', `%${form.district}%`);

      const { data: eslesmeler } = await query.limit(5);

      if (eslesmeler && eslesmeler.length > 0) {
        setEslesenIsletmeler(eslesmeler as EslesenIsletme[]);
        setEslesenGoster(true);
        setLoading(false);
        return; // admin'e bildirim gitme
      }

      // Eşleşme yok → gönder
      await supabaseInsert();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setLoading(false);
    }
  }

  async function handleGonderDevam() {
    setEslesenGoster(false);
    setLoading(true);
    try {
      await supabaseInsert();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setLoading(false);
    }
  }

  // ── Başarı ekranı ──────────────────────────────────────────────────────────

  if (submitted) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center px-4">
        <div className="w-full max-w-md rounded-[24px] border border-border bg-card p-10 text-center shadow-yd2">
          <div className="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-full bg-success/10 text-3xl">✅</div>
          <h2 className="text-xl font-[900] text-textStrong">Önerin alındı!</h2>
          <p className="mt-2 text-sm font-[700] text-muted">Ekibimiz 24–48 saat içinde değerlendirecek. Teşekkürler!</p>
          <div className="mt-6 flex flex-col gap-2">
            <Link href="/kesif" className="flex h-11 items-center justify-center rounded-xl bg-primary text-sm font-[900] text-white transition hover:brightness-110">
              Keşfetmeye Devam Et
            </Link>
            <button type="button" onClick={resetForm} className="text-sm font-[800] text-primary hover:underline">
              Yeni öneri gönder
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ── Form içeriği ──────────────────────────────────────────────────────────

  return (
    <>
      {/* Modallar */}
      <GizlilikModal acik={gizlilikAcik} kapat={() => setGizlilikAcik(false)} />
      <EslesenIsletmelerModal
        acik={eslesenGoster}
        kapat={() => setEslesenGoster(false)}
        isletmeler={eslesenIsletmeler}
        onGonderDevam={handleGonderDevam}
      />

      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">

        {/* Başlık */}
        <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="flex items-center gap-2 text-2xl font-[900] text-textStrong sm:text-3xl">
              İşletme Öner <span aria-hidden="true">🎯</span>
            </h1>
            <p className="mt-1 text-sm font-[700] text-muted">Beğendiğin bir işletmeyi bize öner, değerlendirelim.</p>
          </div>
          <div className="flex items-center gap-2 rounded-xl border border-border bg-card px-4 py-2.5 shadow-yd1">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-muted" aria-hidden="true">
              <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
            </svg>
            <span className="text-sm font-[800] text-muted">Ortalama değerlendirme süresi:</span>
            <span className="text-sm font-[900] text-primary">24–48 saat</span>
          </div>
        </div>

        {/* İki kolon */}
        <div className="flex flex-col gap-6 lg:flex-row lg:items-start">

          {/* Sol sidebar */}
          <aside className="w-full space-y-4 lg:w-72 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">
            <div className="rounded-2xl border border-border bg-card p-5 shadow-yd1">
              <h3 className="mb-2 text-sm font-[900] text-textStrong">Neden Öneride Bulunmalısın?</h3>
              <p className="mb-4 text-[13px] font-[700] leading-relaxed text-muted">
                Yeedoy topluluğunun gücü, senin gibi keşfetmeyi sevenlerin katkılarıyla büyüyor. Beğendiğin işletmeleri önererek hem şehrindeki yeni lezzetlerin keşfedilmesine yardımcı ol hem de diğer kullanıcıların deneyimini zenginleştir.
              </p>
              <div className="space-y-4">
                {[
                  { emoji: '🏪', bg: 'bg-rose-50', title: 'Şehrindeki yeni mekanları görünür kıl', desc: 'Haritada daha fazla kaliteli işletmenin yer almasını sağla.' },
                  { emoji: '👥', bg: 'bg-indigo-50', title: 'Topluluğa katkı yap', desc: 'Kullanıcıların daha iyi seçimler yapmasına yardımcı ol.' },
                  { emoji: '✅', bg: 'bg-emerald-50', title: 'Doğrulanan öneriler daha hızlı yayımlansın', desc: 'Doğru ve eksiksiz bilgilerle önerin daha hızlı değerlendirilir.' },
                ].map((item) => (
                  <div key={item.title} className="flex items-start gap-3">
                    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-lg ${item.bg}`}>
                      {item.emoji}
                    </div>
                    <div>
                      <p className="text-sm font-[900] text-textStrong leading-tight">{item.title}</p>
                      <p className="mt-0.5 text-[12px] font-[700] text-muted leading-snug">{item.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
            <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 shadow-yd1">
              <div className="mb-2 flex items-center gap-2">
                <span className="text-lg" aria-hidden="true">💡</span>
                <p className="text-sm font-[900] text-amber-800">Küçük bir ipucu</p>
              </div>
              <p className="text-[12px] font-[700] leading-relaxed text-amber-700">
                İşletme adı, adres ve varsa sosyal medya bilgilerini eklemen değerlendirmeyi hızlandırır.
              </p>
            </div>
          </aside>

          {/* Sağ: form */}
          <div className="min-w-0 flex-1">
            <form onSubmit={handleSubmit} noValidate>
              <div className="rounded-2xl border border-border bg-card p-6 shadow-yd1">
                <h2 className="mb-5 text-base font-[900] text-textStrong">İşletme Bilgileri</h2>
                <div className="grid gap-4">

                  {/* Ad + Kategori */}
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <InputAlan label="İşletme Adı" required>
                      <input type="text" required value={form.name} onChange={setField('name')} placeholder="Örn. Teras Cafe & Bistro" className={inputCls} />
                    </InputAlan>
                    <InputAlan label="Kategori" required>
                      <div className="relative">
                        <select required value={form.category} onChange={setField('category')} className={selectCls}>
                          <option value="">Kategori seçin</option>
                          {KATEGORILER.map((k) => <option key={k} value={k}>{k}</option>)}
                        </select>
                        <SelectOk />
                      </div>
                    </InputAlan>
                  </div>

                  {/* Şehir + İlçe */}
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <InputAlan label="Şehir" required>
                      <div className="relative">
                        <select required value={form.city} onChange={setField('city')} className={selectCls}>
                          <option value="">Şehir seçin</option>
                          {SEHIRLER.map((s) => <option key={s} value={s}>{s}</option>)}
                        </select>
                        <SelectOk />
                      </div>
                    </InputAlan>
                    <InputAlan label="İlçe" required>
                      <input type="text" required value={form.district} onChange={setField('district')} placeholder="İlçe girin" className={inputCls} />
                    </InputAlan>
                  </div>

                  {/* Mahalle */}
                  <InputAlan label="Mahalle" required>
                    <input type="text" required value={form.neighborhood} onChange={setField('neighborhood')} placeholder="Mahalle girin" className={inputCls} />
                  </InputAlan>

                  {/* Adres */}
                  <InputAlan label="Açık Adres" required>
                    <input type="text" required value={form.address} onChange={setField('address')} placeholder="Cadde, sokak, bina no gibi detaylı adres bilgisi girin" className={inputCls} />
                  </InputAlan>

                  {/* Harita */}
                  <InputAlan label="Harita Konumu / Google Maps Linki">
                    <div className="relative">
                      <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      </span>
                      <input type="url" value={form.mapsLink} onChange={setField('mapsLink')} placeholder="https://maps.google.com/..." className={`${inputCls} pl-9`} />
                    </div>
                  </InputAlan>

                  {/* Telefon + Web */}
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <InputAlan label="Telefon">
                      <div className="relative">
                        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.4 2 2 0 0 1 3.6 1.22h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.8a16 16 0 0 0 6.29 6.29l.95-.96a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
                        </span>
                        <input type="tel" value={form.phone} onChange={setField('phone')} placeholder="0 (5XX) XXX XX XX" className={`${inputCls} pl-9`} />
                      </div>
                    </InputAlan>
                    <InputAlan label="Web Sitesi">
                      <div className="relative">
                        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
                        </span>
                        <input type="url" value={form.website} onChange={setField('website')} placeholder="https://ornek.com" className={`${inputCls} pl-9`} />
                      </div>
                    </InputAlan>
                  </div>

                  {/* Sosyal + Neden */}
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <InputAlan label="Instagram / Sosyal Medya">
                      <div className="relative">
                        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted" aria-hidden="true">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
                        </span>
                        <input type="text" value={form.social} onChange={setField('social')} placeholder="@kullaniciadi veya profil linki" className={`${inputCls} pl-9`} />
                      </div>
                    </InputAlan>
                    <InputAlan label="Neden Öneriyorsun?" required>
                      <div className="relative">
                        <select required value={form.reason} onChange={setField('reason')} className={selectCls}>
                          <option value="">Bir neden seçin</option>
                          {NEDENLER.map((n) => <option key={n} value={n}>{n}</option>)}
                        </select>
                        <SelectOk />
                      </div>
                    </InputAlan>
                  </div>

                  {/* Ek açıklama */}
                  <InputAlan label="Ek Açıklama">
                    <div className="relative">
                      <textarea value={form.notes} onChange={setField('notes')} maxLength={500} rows={4}
                        placeholder="Bu işletme hakkında eklemek istediğin notları yazabilirsin..."
                        className="w-full resize-none rounded-xl border border-border bg-bg px-4 py-3 text-sm font-[700] text-textStrong placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15 transition" />
                      <span className="absolute bottom-2.5 right-3 text-[11px] font-[700] text-muted">{form.notes.length} / 500</span>
                    </div>
                  </InputAlan>

                  {/* Fotoğraf */}
                  <InputAlan label="Fotoğraf Ekle (İsteğe Bağlı)">
                    <div
                      role="button" tabIndex={0}
                      onClick={() => fileRef.current?.click()}
                      onKeyDown={(e) => e.key === 'Enter' && fileRef.current?.click()}
                      onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                      onDragLeave={() => setDragOver(false)}
                      onDrop={(e) => { e.preventDefault(); setDragOver(false); handleFiles(e.dataTransfer.files); }}
                      className={`flex min-h-[96px] cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed transition ${dragOver ? 'border-primary bg-primary/5' : 'border-border bg-bg hover:border-primary/40'}`}
                    >
                      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke={dragOver ? '#7f1d1d' : '#94a3b8'} strokeWidth="1.5" strokeLinecap="round" aria-hidden="true">
                        <polyline points="16 16 12 12 8 16"/><line x1="12" y1="12" x2="12" y2="21"/>
                        <path d="M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3"/>
                      </svg>
                      <p className="text-sm font-[800] text-muted">Fotoğrafları buraya sürükle veya tıkla</p>
                      <p className="text-xs font-[700] text-muted/70">JPG, PNG · maksimum 5 MB</p>
                    </div>
                    <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={(e) => handleFiles(e.target.files)} />
                    {photos.length > 0 && (
                      <div className="flex flex-wrap gap-2">
                        {photos.map((p, i) => (
                          <span key={i} className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-[800] text-textStrong">
                            📎 {p}
                            <button type="button" onClick={() => setPhotos((prev) => prev.filter((_, j) => j !== i))}
                              className="text-muted hover:text-danger transition-colors" aria-label={`${p} kaldır`}>×</button>
                          </span>
                        ))}
                      </div>
                    )}
                  </InputAlan>

                  {/* Onaylar */}
                  <div className="space-y-2.5 border-t border-border pt-4">
                    <label className="flex cursor-pointer items-start gap-3">
                      <input type="checkbox" checked={onay1} onChange={(e) => setOnay1(e.target.checked)} className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer rounded accent-primary" />
                      <span className="text-sm font-[700] text-textStrong leading-snug">Gönderdiğim bilgilerin doğru olduğunu onaylıyorum. <span className="text-primary">*</span></span>
                    </label>
                    <label className="flex cursor-pointer items-start gap-3">
                      <input type="checkbox" checked={onay2} onChange={(e) => setOnay2(e.target.checked)} className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer rounded accent-primary" />
                      <span className="text-sm font-[700] text-textStrong leading-snug">
                        <button
                          type="button"
                          onClick={() => setGizlilikAcik(true)}
                          className="font-[900] text-primary underline underline-offset-2 hover:brightness-110 transition"
                        >
                          Gizlilik politikasını
                        </button>{' '}kabul ediyorum. <span className="text-primary">*</span>
                      </span>
                    </label>
                  </div>

                  {error && (
                    <div className="rounded-xl border border-danger/25 bg-danger/[0.07] px-4 py-3 text-sm font-[700] text-danger">{error}</div>
                  )}

                  {/* Butonlar */}
                  <div className="flex flex-col gap-3 sm:flex-row">
                    <button type="button"
                      className="flex h-12 flex-1 items-center justify-center gap-2 rounded-xl border border-border bg-card text-sm font-[900] text-textStrong shadow-yd1 transition-all hover:border-primary/40 hover:text-primary">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                      </svg>
                      Taslak Kaydet
                    </button>
                    <button type="submit" disabled={loading}
                      className="flex h-12 flex-[2] items-center justify-center gap-2 rounded-xl bg-primary text-sm font-[900] text-white shadow-sm transition-all hover:brightness-110 disabled:opacity-60">
                      {loading ? (
                        <svg className="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                          <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8M21 3v5h-5"/>
                        </svg>
                      ) : (
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                          <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
                        </svg>
                      )}
                      {loading ? 'Kontrol ediliyor…' : 'Öneriyi Gönder'}
                    </button>
                  </div>

                  <p className="flex items-center justify-center gap-1.5 text-xs font-[700] text-muted">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-success" aria-hidden="true">
                      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                    </svg>
                    Onaylanan işletmeler, doğrulama sonrası platformda yayınlanır.
                  </p>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
}
