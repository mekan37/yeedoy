import type { Metadata } from 'next';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';

export const metadata: Metadata = {
  title: 'Mesajlar | Owner Panel',
  robots: { index: false, follow: false },
};

export default function OwnerMessagesPage() {
  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Mesajlar"
        description="Müşterilerden gelen mesajlar ve sorular"
      />
      <div className="px-6 pt-6">
        <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#e5e7eb] bg-white py-24 text-center shadow-[0_1px_3px_rgba(0,0,0,0.04)]">
          <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#fef2f2]">
            <MessagePlaceholderIcon />
          </div>
          <p className="text-base font-[900] text-[#1a1a2e]">Müşteri Mesajları</p>
          <p className="mt-2 max-w-sm text-sm font-[600] text-[#94a3b8]">
            Bu bölüm yakında aktif olacak. Müşteri mesajlarını ve sorularını buradan yönetebileceksiniz.
          </p>
          <span className="mt-5 rounded-full bg-[#fef2f2] px-4 py-1.5 text-[12px] font-[800] text-[#dc2626]">
            Yakında
          </span>
        </div>
      </div>
    </div>
  );
}

function MessagePlaceholderIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}
