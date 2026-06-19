import { AppSectionHeader } from '@yeedoy/web-ui';

export function Default() {
  return (
    <div style={{ padding: 24, maxWidth: 480 }}>
      <AppSectionHeader title="Popüler Restoranlar" />
    </div>
  );
}

export function WithSubtitle() {
  return (
    <div style={{ padding: 24, maxWidth: 480 }}>
      <AppSectionHeader
        title="Günün Önerileri"
        subtitle="Bugün özellikle beğenebileceğin yerler seni bekliyor"
      />
    </div>
  );
}

export function WithTrailingAction() {
  return (
    <div style={{ padding: 24, maxWidth: 480 }}>
      <AppSectionHeader
        title="Yakınımdakiler"
        subtitle="2 km içinde 12 mekan"
        trailing={
          <span style={{ fontSize: 12, color: '#7f1d1d', fontWeight: 700, cursor: 'pointer' }}>
            Tümünü gör →
          </span>
        }
      />
    </div>
  );
}
