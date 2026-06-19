import { PanelDataTable, PanelDataTableHeader, PanelDataTableRow, PanelDataTableCell } from '@yeedoy/web-ui';

export function Default() {
  return (
    <div style={{ padding: 24 }}>
      <PanelDataTable>
        <thead>
          <tr>
            <PanelDataTableHeader>İşletme Adı</PanelDataTableHeader>
            <PanelDataTableHeader>Şehir</PanelDataTableHeader>
            <PanelDataTableHeader>Puan</PanelDataTableHeader>
            <PanelDataTableHeader>Durum</PanelDataTableHeader>
          </tr>
        </thead>
        <tbody>
          <PanelDataTableRow>
            <PanelDataTableCell>Karadeniz Mutfağı</PanelDataTableCell>
            <PanelDataTableCell>İstanbul</PanelDataTableCell>
            <PanelDataTableCell>4.8</PanelDataTableCell>
            <PanelDataTableCell>Aktif</PanelDataTableCell>
          </PanelDataTableRow>
        </tbody>
      </PanelDataTable>
    </div>
  );
}
