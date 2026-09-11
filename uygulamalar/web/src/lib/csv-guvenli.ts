// CSV formül enjeksiyonuna (CSV/Formula Injection) karşı standart OWASP
// mitigasyonu: bir hücre değeri Excel/Google Sheets'in formül başlangıcı
// olarak yorumladığı bir karakterle (=, +, -, @, TAB, CR) başlıyorsa başına
// tek tırnak ekleniyor — bu, hücreyi formül olarak değil düz metin olarak
// yorumlatır. Sahip-kontrollü alanlar (işletme adı, ürün adı vb.) CSV
// raporlarına aktarılırken bir yönetici Excel'de dosyayı açtığında
// =HYPERLINK(...)/=WEBSERVICE(...) gibi formüller çalışabiliyordu.
const FORMULA_TRIGGER_CHARS = new Set(['=', '+', '-', '@', '\t', '\r']);

function sanitizeCsvValue(value: string): string {
  if (value.length === 0) return value;
  return FORMULA_TRIGGER_CHARS.has(value[0]) ? `'${value}` : value;
}

export function csvHucre(v: unknown): string {
  const raw = v == null ? '' : String(v);
  const s = sanitizeCsvValue(raw).replace(/"/g, '""');
  return s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r') ? `"${s}"` : s;
}

export function toCsv(rows: Record<string, unknown>[], headers?: string[]): string {
  if (!rows.length) return '';
  const cols = headers ?? Object.keys(rows[0]);
  const lines = [
    cols.map(csvHucre).join(','),
    ...rows.map((r) => cols.map((h) => csvHucre(r[h])).join(',')),
  ];
  return lines.join('\r\n');
}
