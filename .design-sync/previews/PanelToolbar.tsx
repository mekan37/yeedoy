import { PanelToolbar, PanelToolbarGroup } from '@yeedoy/web-ui';

export function Default() {
  return (
    <div style={{ padding: 16, borderBottom: '1px solid #e5e7eb' }}>
      <PanelToolbar>
        <input
          placeholder="Ara..."
          style={{
            padding: '7px 12px',
            border: '1px solid #e5e7eb',
            borderRadius: 8,
            fontSize: 14,
            minWidth: 200,
          }}
        />
        <button
          style={{
            padding: '7px 16px',
            background: '#7f1d1d',
            color: '#fff',
            borderRadius: 8,
            border: 'none',
            fontWeight: 600,
            cursor: 'pointer',
            fontSize: 14,
          }}
        >
          Ara
        </button>
      </PanelToolbar>
    </div>
  );
}

export function WithGroups() {
  return (
    <div style={{ padding: 16, borderBottom: '1px solid #e5e7eb' }}>
      <PanelToolbar>
        <PanelToolbarGroup>
          <input
            placeholder="İşletme ara..."
            style={{
              padding: '7px 12px',
              border: '1px solid #e5e7eb',
              borderRadius: 8,
              fontSize: 14,
              minWidth: 200,
            }}
          />
        </PanelToolbarGroup>
        <PanelToolbarGroup>
          <select
            style={{
              padding: '7px 12px',
              border: '1px solid #e5e7eb',
              borderRadius: 8,
              fontSize: 14,
              background: '#fff',
            }}
          >
            <option>Tüm Şehirler</option>
            <option>İstanbul</option>
            <option>Ankara</option>
          </select>
          <select
            style={{
              padding: '7px 12px',
              border: '1px solid #e5e7eb',
              borderRadius: 8,
              fontSize: 14,
              background: '#fff',
            }}
          >
            <option>Tüm Durum</option>
            <option>Aktif</option>
            <option>Pasif</option>
          </select>
        </PanelToolbarGroup>
      </PanelToolbar>
    </div>
  );
}
