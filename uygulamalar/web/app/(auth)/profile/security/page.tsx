import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = { title: 'Hesap Güvenliği | Yeedoy', robots: { index: false, follow: false } };

export default function SecurityPage() {
  return (
    <main className="min-h-screen bg-bg">
      <div className="mx-auto max-w-lg px-4 py-12">
        <Link href="/profile/settings" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted hover:text-primary cursor-pointer">← Ayarlara Dön</Link>
        <h1 className="mb-8 text-2xl font-[900] text-textStrong">Hesap Güvenliği</h1>
        <div className="flex flex-col gap-4">
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="font-[700] text-textStrong mb-1">Şifre Değiştir</h2>
            <p className="text-sm text-muted mb-4">Şifrenizi sıfırlamak için e-posta ile bağlantı göndeririz.</p>
            <Link href="/forgot-password" className="inline-flex rounded-xl border border-border bg-bg px-4 py-2 text-sm font-[700] text-textStrong hover:border-primary/30 transition-colors cursor-pointer">
              Şifre Sıfırlama E-postası Gönder
            </Link>
          </div>
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="font-[700] text-textStrong mb-1">İki Faktörlü Doğrulama</h2>
            <p className="text-sm text-muted mb-3">Hesabınızı ekstra bir güvenlik katmanıyla koruyun.</p>
            <span className="inline-flex rounded-full bg-amber-50 px-3 py-1 text-[12px] font-[700] text-amber-700">Yakında</span>
          </div>
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="font-[700] text-textStrong mb-1">Aktif Oturumlar</h2>
            <p className="text-sm text-muted mb-3">Bağlı cihazları yönetin ve oturumları sonlandırın.</p>
            <span className="inline-flex rounded-full bg-amber-50 px-3 py-1 text-[12px] font-[700] text-amber-700">Yakında</span>
          </div>
        </div>
      </div>
    </main>
  );
}
