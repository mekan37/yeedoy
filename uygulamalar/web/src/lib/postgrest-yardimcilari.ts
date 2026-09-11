// PostgREST'in `.or()` filtre sözdizimi virgülü koşul ayracı, parantezi ise
// grup kapatıcı olarak yorumlar. Kullanıcı girdisi bu operatörlere doğrudan
// enterpole edilirse ek disjunct eklenebilir (filtre bypass) ya da hata
// mesajlarından boolean-oracle ile select dışı kolonlar sızdırılabilir.
// `.or()` içine giden HER kullanıcı girdisi bununla escape edilmeli.
export function escapePostgrestValue(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/,/g, '\\,').replace(/\)/g, '\\)');
}
