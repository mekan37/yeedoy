import { PanelDataTable, PanelDataTableHeader, PanelDataTableRow, PanelDataTableCell } from '@yeedoy/web-ui';

export function Default() {
  return (
    <div style={{ padding: 24 }}>
      <PanelDataTable>
        <thead>
          <tr>
            <PanelDataTableHeader>Ad</PanelDataTableHeader>
            <PanelDataTableHeader>Kategori</PanelDataTableHeader>
            <PanelDataTableHeader>Tarih</PanelDataTableHeader>
          </tr>
        </thead>
        <tbody>
          <PanelDataTableRow>
            <PanelDataTableCell>Kebapçı Mehmet</PanelDataTableCell>
            <PanelDataTableCell>Türk Mutfağı</PanelDataTableCell>
            <PanelDataTableCell>12 Haz 2026</PanelDataTableCell>
          </PanelDataTableRow>
          <PanelDataTableRow>
            <PanelDataTableCell>Deniz Balık</PanelDataTableCell>
            <PanelDataTableCell>Deniz Ürünleri</PanelDataTableCell>
            <PanelDataTableCell>10 Haz 2026</PanelDataTableCell>
          </PanelDataTableRow>
          <PanelDataTableRow>
            <PanelDataTableCell>Fırın Pasta</PanelDataTableCell>
            <PanelDataTableCell>Pastane</PanelDataTableCell>
            <PanelDataTableCell>8 Haz 2026</PanelDataTableCell>
          </PanelDataTableRow>
        </tbody>
      </PanelDataTable>
    </div>
  );
}
