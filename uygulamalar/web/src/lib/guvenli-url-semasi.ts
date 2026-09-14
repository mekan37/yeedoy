import { z } from 'zod';

// z.string().url() yalnızca WHATWG URL sözdizimini doğrular — javascript:,
// intent://, data: gibi şemaları da kabul eder. Bu alanlar public sayfalarda
// <a href> olarak render edildiği için (rezervasyon/sipariş linkleri, logo/
// kapak URL'leri), http(s) dışı bir şema XSS'e (javascript:) veya mobil
// intent-scheme suistimaline (intent://) yol açabilir.
export function httpUrlSchema(maxLength = 2000) {
  return z
    .string()
    .trim()
    .max(maxLength)
    .refine((value) => {
      try {
        return ['http:', 'https:'].includes(new URL(value).protocol);
      } catch {
        return false;
      }
    }, 'Yalnızca http:// veya https:// ile başlayan adresler kabul edilir.');
}

export function optionalHttpUrlSchema(maxLength = 2000) {
  return z.union([z.literal(''), httpUrlSchema(maxLength)]).optional();
}
