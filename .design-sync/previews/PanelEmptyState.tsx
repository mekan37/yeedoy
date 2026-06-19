import { PanelEmptyState } from '@yeedoy/web-ui';

export function Default() {
  return (
    <PanelEmptyState
      icon={<span style={{ fontSize: 28 }}>🍽️</span>}
      title="Henüz yorum yok"
      description="Bu işletme için henüz kullanıcı yorumu eklenmemiş."
    />
  );
}

export function WithAction() {
  return (
    <PanelEmptyState
      icon={<span style={{ fontSize: 28 }}>📋</span>}
      title="Menü bulunamadı"
      description="Henüz bir menü oluşturulmamış. Yeni bir menü ekleyerek başlayın."
      action={
        <button
          style={{
            padding: '8px 20px',
            background: '#7f1d1d',
            color: '#fff',
            borderRadius: 8,
            border: 'none',
            fontWeight: 700,
            cursor: 'pointer',
            fontSize: 14,
          }}
        >
          Menü Ekle
        </button>
      }
    />
  );
}

export function NoIcon() {
  return (
    <PanelEmptyState
      title="Sonuç bulunamadı"
      description="Arama kriterlerinize uygun içerik bulunamadı."
    />
  );
}
