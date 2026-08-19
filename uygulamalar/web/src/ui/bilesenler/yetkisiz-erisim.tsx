import { PanelEmptyState } from './panel-bos-durum';

export function YetkisizErisim({ sayfaAdi }: { sayfaAdi: string }) {
  return (
    <PanelEmptyState
      icon={<LockIcon />}
      title="Bu sayfaya erişim yetkiniz yok"
      description={`${sayfaAdi} sayfasını görüntülemek için gereken izne sahip değilsiniz. İhtiyacınız varsa bir Süper Admin'den rolünüze bu izni eklemesini isteyin.`}
    />
  );
}

function LockIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}
