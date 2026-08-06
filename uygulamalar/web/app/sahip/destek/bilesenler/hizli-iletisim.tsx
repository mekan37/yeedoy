export function HizliIletisim() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-1 text-sm font-black text-textStrong">Hızlı İletişim</h3>
      <p className="mb-3 text-xs text-muted">
        Pazartesi–Cuma 09:00–18:00 saatleri arasında size yardımcı olmaktan mutluluk duyarız.
      </p>
      <a
        href="mailto:destek@yeedoy.com"
        className="flex items-center justify-center gap-2 rounded-xl border border-border bg-bg px-3 py-2 text-xs font-bold text-textStrong hover:border-primary/30 hover:text-primary"
      >
        destek@yeedoy.com
      </a>
    </div>
  );
}
