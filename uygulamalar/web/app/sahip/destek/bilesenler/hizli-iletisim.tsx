export function HizliIletisim() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-1 text-sm font-black text-textStrong">Hızlı İletişim</h3>
      <p className="mb-3 text-xs text-muted">Ekibimizle doğrudan iletişime geçin.</p>

      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-3 rounded-xl border border-border p-3 opacity-60">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-bg text-muted">
            <ChatIcon />
          </span>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <p className="text-xs font-extrabold text-textStrong">Canlı Destek</p>
              <span className="rounded-full bg-muted/15 px-1.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider text-muted">Yakında</span>
            </div>
            <p className="text-[11px] text-muted">Hafta içi 09:00–18:00</p>
          </div>
        </div>

        <div className="flex items-center gap-3 rounded-xl border border-border p-3">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
            <MailIcon />
          </span>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-extrabold text-textStrong">E-posta</p>
            <p className="truncate text-[11px] text-muted">destek@yeedoy.com</p>
          </div>
          <a
            href="mailto:destek@yeedoy.com"
            className="shrink-0 rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
          >
            E-posta Gönder
          </a>
        </div>

        <div className="flex items-center gap-3 rounded-xl border border-border p-3 opacity-60">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-bg text-muted">
            <PhoneIcon />
          </span>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <p className="text-xs font-extrabold text-textStrong">Telefon</p>
              <span className="rounded-full bg-muted/15 px-1.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider text-muted">Yakında</span>
            </div>
            <p className="text-[11px] text-muted">Hafta içi 09:00–18:00</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function ChatIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" /></svg>;
}
function MailIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>;
}
function PhoneIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.362 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.338 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" /></svg>;
}
