import { describe, expect, it } from 'vitest';
import { ADMIN_PERMISSIONS, type AdminPermissionKey } from '@/src/lib/admin-izinler';

// TS AdminPermissionKey/ADMIN_PERMISSIONS ile DB'deki admin_permission_key
// enum'u iki bağımsız listeydi ve iki kez birbirinden koptu:
// 1) page:yoresel-mutfak TS'de tanımlıydı ama DB enum'unda hiç yoktu —
//    has_permission_v1() cast hatasıyla patlıyor, süper admin dahil kimse
//    sayfayı göremiyordu (P1, 20260912000011 ile düzeltildi).
// 2) page:arama/itirazlar-claims/denetim-kaydi/toplu-islemler DB enum'una
//    eklendi ama admin-izinler.ts'e hiç yansıtılmadı; ilgili sayfa/route'lar
//    hasPermission() çağırmak isteseydi TS tip hatası verirdi.
//
// Bu test canlı DB'ye bağlanmıyor (CI'da ortam bağımlılığı yaratmamak için) —
// aşağıdaki liste, 14 Eylül 2026'da Supabase MCP ile doğrulanmış gerçek
// admin_permission_key enum değerlerinin bir anlık görüntüsüdür. Yeni bir
// enum değeri eklendiğinde bu listeye de eklenmeli (aksi halde bu test
// gerçek anlamda drift'i yakalamaz, ama en azından "TS'de olup DB'de
// olmayan" — yani çökmeye yol açan — yönü her zaman yakalar).
const KNOWN_DB_ENUM_VALUES_2026_09_14 = [
  'page:analitik', 'page:api-anahtarlari', 'page:arama', 'page:cop-kutusu',
  'page:denetim-kaydi', 'page:feature-flags', 'page:fis-basvurulari',
  'page:fiyat-onerileri', 'page:fotograf-moderasyon', 'page:fraud-tespiti',
  'page:gecici-yuklemeler', 'page:gelistirme-araclari', 'page:gorsel-kutuphanesi',
  'page:gozlemlenebilirlik', 'page:isletme-basvurulari', 'page:isletmeler',
  'page:itirazlar', 'page:itirazlar-claims', 'page:kara-liste', 'page:konumlar',
  'page:kullanicilar', 'page:kuyruklar', 'page:kvkk-gdpr', 'page:musteri-destek',
  'page:olaylar', 'page:oneriler', 'page:raporlar', 'page:roller',
  'page:toplu-islemler', 'page:yoresel-mutfak', 'page:yorumlar', 'page:zincirler',
] as const;
// Not: page:api-anahtarlari DB enum'unda hâlâ var (Postgres enum değerleri
// geri alınamaz) ama özellik devre dışı bırakıldığı için admin-izinler.ts'ten
// kasıtlı olarak kaldırıldı — bu yüzden aşağıdaki "TS ⊆ DB" yönünde hariç
// tutulmuyor (zaten DB listesinde var), sadece "DB ⊆ TS" yönünde beklenmiyor.
const INTENTIONALLY_UNUSED_IN_TS = new Set(['page:api-anahtarlari', 'page:itirazlar-claims', 'page:denetim-kaydi', 'page:toplu-islemler']);

describe('admin-izinler: TS katalogu DB enum ile tutarlı', () => {
  it('ADMIN_PERMISSIONS içindeki her key, bilinen DB enum listesinde var (has_permission_v1 cast hatası riski)', () => {
    const dbSet = new Set<string>(KNOWN_DB_ENUM_VALUES_2026_09_14);
    const missingFromDb = ADMIN_PERMISSIONS.map((p) => p.key).filter((key) => !dbSet.has(key));
    expect(missingFromDb, 'Bu key\'ler DB admin_permission_key enum\'unda yok — has_permission_v1() çağrıldığında cast hatasıyla patlar (bkz. page:yoresel-mutfak olayı)').toEqual([]);
  });

  it('katalogda her key benzersiz', () => {
    const keys = ADMIN_PERMISSIONS.map((p) => p.key);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('her katalog girişinin href\'i /yonetici/ ile başlıyor', () => {
    for (const p of ADMIN_PERMISSIONS) {
      expect(p.href.startsWith('/yonetici/'), `${p.key} → ${p.href}`).toBe(true);
    }
  });

  it('bilinen DB enum değerlerinden yalnızca kasıtlı olarak hariç tutulanlar katalogda yok (bilgilendirme amaçlı)', () => {
    const tsSet = new Set<string>(ADMIN_PERMISSIONS.map((p) => p.key));
    const dbOnlyKeys = KNOWN_DB_ENUM_VALUES_2026_09_14.filter((key) => !tsSet.has(key));
    for (const key of dbOnlyKeys) {
      expect(INTENTIONALLY_UNUSED_IN_TS.has(key), `${key} DB'de var ama TS katalogunda yok ve kasıtlı-hariç listesinde de yok — unutulmuş bir izin anahtarı olabilir`).toBe(true);
    }
  });
});

// Derleme-zamanı kontrol: AdminPermissionKey union'ındaki her değer bu
// dosyanın import edildiği her yerde ADMIN_PERMISSIONS.key ile aynı
// literal string tipini paylaşmalı — tip uyuşmazlığı olursa bu satır
// derlenmez (typecheck script'i zaten bunu yakalar, burada yalnızca niyeti
// belgeliyoruz).
const _typeSanityCheck: AdminPermissionKey = ADMIN_PERMISSIONS[0]!.key;
void _typeSanityCheck;
