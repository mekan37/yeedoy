# Admin Rol/İzin Sistemi (Plan B) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 24 admin sayfasının (Roller hariç, o Plan A'da zaten korunuyor) `page.tsx`'ine gerçek `hasPermission()` kısıtlaması eklemek, ilgili 7 mutation `route.ts`'ine de aynı izni eklemek. Bu plan bittiğinde kenar çubuğunda gizli olan sayfalar artık URL ile doğrudan girilse bile "Yetkiniz Yok" gösterir.

**Pattern (her sayfa için aynı):**

`page.tsx` — mevcut fonksiyonun EN BAŞINA, herhangi bir veri çekme işleminden ÖNCE:
```tsx
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
```
Ve fonksiyon gövdesinin ilk satırı olarak:
```tsx
  const yetkili = await hasPermission('page:XXX');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="LABEL" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="LABEL" /></PanelIcerikYuzeyi>
      </div>
    );
  }
```
`PanelSayfaBasligi`/`PanelIcerikYuzeyi` zaten her sayfada import edilmiş durumda — sadece yoksa ekle. Mevcut kodun geri kalanı (veri çekme, render) DEĞİŞTİRİLMEZ, sadece bu blok başa eklenir.

`route.ts` (varsa) — her HTTP handler'da mevcut `is_admin()` kontrolünün HEMEN ALTINA:
```ts
  const { data: yetkili } = await sb.rpc('has_permission_v1', { p_permission: 'page:XXX' });
  if (!yetkili) return NextResponse.json({ error: 'forbidden' }, { status: 403 });
```
(`sb` zaten route'ta tanımlı Supabase client alias'ı — dosyaya göre `sb`/`supabaseAny` olabilir, mevcut ismi kullan.)

**Sayfa → izin anahtarı → etiket eşlemesi (24 sayfa, Roller hariç):**

| Sayfa (page.tsx) | permission key | LABEL | route.ts var mı |
|---|---|---|---|
| isletmeler | page:isletmeler | İşletmeler | evet (+ [id]/menuler alt route) |
| zincirler | page:zincirler | Zincirler | hayır |
| kuyruklar | page:kuyruklar | Kuyruklar | hayır |
| isletme-basvurulari | page:isletme-basvurulari | İşletme Talepleri | hayır |
| raporlar | page:raporlar | Raporlar | evet |
| kullanicilar | page:kullanicilar | Kullanıcılar | hayır |
| yorumlar | page:yorumlar | Yorumlar | hayır |
| itirazlar | page:itirazlar | İtirazlar | evet |
| fis-basvurulari | page:fis-basvurulari | Fiş Başvuruları | hayır |
| cop-kutusu | page:cop-kutusu | Silinmiş Menüler | hayır |
| olaylar | page:olaylar | Olaylar | hayır |
| konumlar | page:konumlar | Konumlar | hayır |
| analitik | page:analitik | Analitik | hayır |
| musteri-destek | page:musteri-destek | Müşteri Destek | evet |
| oneriler | page:oneriler | Öneriler | hayır |
| fiyat-onerileri | page:fiyat-onerileri | Fiyat Önerileri | hayır |
| fraud-tespiti | page:fraud-tespiti | Fraud Tespiti | hayır |
| fotograf-moderasyon | page:fotograf-moderasyon | Fotoğraf Moderasyon | evet |
| feature-flags | page:feature-flags | Feature Flags | evet |
| api-anahtarlari | page:api-anahtarlari | API Anahtarları | evet |
| gozlemlenebilirlik | page:gozlemlenebilirlik | Gözlemlenebilirlik | hayır |
| gelistirme-araclari | page:gelistirme-araclari | Geliştirici Araçları | hayır |
| kvkk-gdpr | page:kvkk-gdpr | KVKK / GDPR | hayır |
| gecici-yuklemeler | page:gecici-yuklemeler | Geçici Yüklemeler | hayır |

Tüm route.ts dosyaları: `app/sunucu/yonetici/isletmeler/route.ts` + `app/sunucu/yonetici/isletmeler/[id]/menuler/route.ts`, `app/sunucu/yonetici/raporlar/route.ts`, `app/sunucu/yonetici/itirazlar/route.ts`, `app/sunucu/yonetici/musteri-destek/route.ts`, `app/sunucu/yonetici/fotograf-moderasyon/route.ts`, `app/sunucu/yonetici/feature-flags/route.ts`, `app/sunucu/yonetici/api-anahtarlari/route.ts`.

**Doğrulama:** her batch sonrası `pnpm run typecheck` + `pnpm run lint` (0 hata). Son batch sonrası tarayıcıda en az bir sayfada gerçek "Yetkiniz Yok" ekranı test edilecek (Roller'daki gibi geçici test rolüyle, hemen geri alınacak).

---

### Batch 1: isletmeler, zincirler, kuyruklar, isletme-basvurulari, raporlar
### Batch 2: kullanicilar, yorumlar, itirazlar, fis-basvurulari, cop-kutusu
### Batch 3: olaylar, konumlar, analitik, musteri-destek, oneriler
### Batch 4: fiyat-onerileri, fraud-tespiti, fotograf-moderasyon, feature-flags, api-anahtarlari
### Batch 5: gozlemlenebilirlik, gelistirme-araclari, kvkk-gdpr, gecici-yuklemeler

Her batch: implementer subagent (pattern + ilgili 4-5 sayfa/route dosya yolu + LABEL verilir) → spec review → kalite review.
