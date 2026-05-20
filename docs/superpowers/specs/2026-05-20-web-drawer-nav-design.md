# Web Drawer Navigasyon + Header/Layout Düzeltmeleri

**Tarih:** 2026-05-20  
**Durum:** Onaylandı

---

## Özet

Web uygulamasında üç sorun tespit edildi:

1. `(kimlik)` route grubu layout'u `PublicShell` içermediğinden `/profil`, `/favoriler`, `/gelen-kutusu` gibi tüm auth gerektiren sayfalarda header görünmüyor.
2. Bazı sayfalar (`/profil` → `max-w-xl`) `Container` standardına (`max-w-6xl`) uymayan dar genişlik kullanıyor.
3. Mobil uygulamadaki drawer navigasyon web'de yok; `<1024px`'de tüm nav öğelerine erişilemiyor.

Çözüm: mobil uygulamadaki `AppDrawer` yapısını web'e birebir çeviren bir drawer sistemi + layout düzeltmeleri.

---

## Mimari

### State Yönetimi

`src/lib/web-kabuk-deposu.ts` — Zustand store (`panel-deposu.ts` ile aynı pattern):

```ts
interface WebKabukStore {
  isDrawerOpen: boolean;
  openDrawer: () => void;
  closeDrawer: () => void;
  toggleDrawer: () => void;
}
```

### Yeni Dosyalar

| Dosya | Açıklama |
|---|---|
| `src/lib/web-kabuk-deposu.ts` | Drawer açık/kapalı state (Zustand) |
| `src/ui/kabuk/uygulama-cekmecesi.tsx` | Client drawer component |
| `src/ui/kabuk/hamburger-dugmesi.tsx` | Client hamburger butonu (store'a yazar) |

### Değiştirilen Dosyalar

| Dosya | Değişiklik |
|---|---|
| `src/ui/acik/yerlesim.tsx` | `PublicHeader`'a `<HamburgerDugmesi>`, `PublicShell`'e `<AppDrawer>` + backdrop |
| `app/(kimlik)/layout.tsx` | `children` → `<PublicShell>` ile sarılır |
| `app/(kimlik)/profil/page.tsx` | `max-w-xl` → `Container` wrapper |

---

## Drawer UI Yapısı

Mobil `uygulama_cekmecesi.dart` ile birebir örtüşür.

**Konum & Animasyon:**
- Soldan açılır: `translate-x-[-100%]` → `translate-x-0`, `transition-transform duration-300`
- Genişlik: `w-80` (320px)
- Z-index: backdrop `z-40`, panel `z-50`
- Backdrop: `fixed inset-0 bg-black/50` — tıklandığında kapanır

**İç yapı (yukarıdan aşağıya):**

1. **Gradient başlık kartı**  
   `bg-gradient-to-br from-[var(--yd-color-primary-deep)] to-[var(--yd-color-primary)]`, `rounded-[18px]`, shadow  
   → `YeedoyLogo` beyaz (inverse)

2. **Profil pill**  
   - Giriş yapıldıysa: avatar (baş harf fallback) + display name + chevron → `/profil`'e yönlendirir  
   - Giriş yapılmadıysa: "Giriş Yap" butonu → `/giris`

3. **Bölüm kartları** (`bg-cardAlt border border-border rounded-2xl shadow-sm`)  
   Her bölüm başlığı `font-[800]`, her öğe: ikon + etiket + chevron-right

   | Bölüm | Öğeler |
   |---|---|
   | Keşfet | Keşfet `/kesif`, En İyiler `/en-iyiler`, Liderler `/liderler`, Bütçe `/butce` |
   | Özellikler | Akıllı Akış `/akilli-akis`, Taste Twin `/tat-ikizi`, Fiyat Uyarıları `/fiyat-uyarilari`, Kolaborasyon Listeleri `/ortak-listeler` |
   | Hesap | Favorilerim `/favoriler`, Profil `/profil`, Gelen Kutusu `/gelen-kutusu` (unread badge), Önerilerim `/oneriler`, Yasal `/yasal` |

4. **Alt satır**  
   `<ThemeToggle>` sol + "Yeedoy" muted metin sağ

**Veri akışı:**
- `PublicShell` (server) → `sessionUser` + `unreadCount` fetch → `AppDrawer`'a prop olarak geçer
- `AppDrawer` client component olduğundan hydration sırasında bu prop'ları alır
- Link tıklandığında: `closeDrawer()` çağrılır, sonra navigasyon

---

## Header Değişiklikleri

`PublicHeader`'da logo sağına hamburger eklenir:

```tsx
{/* Hamburger — sadece <1024px'de görünür, nav gizlenince */}
<div className="md:hidden">
  <HamburgerDugmesi />
</div>
```

Desktop'ta (`≥1024px`) yatay nav korunur, hamburger gizlenir.

---

## Layout Düzeltmeleri

### `(kimlik)/layout.tsx`

```tsx
return <PublicShell>{children}</PublicShell>;
```

Bu tek değişiklik şu sayfalara header + footer + mobile bottom nav ekler:
`/profil`, `/favoriler`, `/gelen-kutusu`, `/sadakat`, `/takip`, `/fiyat-uyarilari`, `/akilli-akis`, `/tat-ikizi`, `/ortak-listeler`, `/grup-istekleri`, `/avantajlar`, `/yemek-gunlugum`, `/diyet-profili`, `/oneriler`, `/bildirim-ayarlari`, `/askiya-alinma-talepleri`, `/katki`, `/profil/security`

### Genişlik

`/profil` sayfasındaki `mx-auto max-w-xl px-4` → `Container` ile sarılır.  
Diğer `(kimlik)` sayfaları gerektiğinde ayrıca incelenir.

---

## Kapsam Dışı

- `sahip/` ve `yonetici/` layout'ları — kendi `PanelShell`'leri var, dokunulmaz
- Ana sayfa hero tam genişlik (`max-w-7xl`) — kasıtlı tasarım, korunur
- Mevcut `MobileBottomNav` — korunur, değiştirilmez

---

## Test Kriterleri

- `<1024px`'de hamburger görünür, tıklandığında drawer soldan açılır
- `≥1024px`'de hamburger gizlidir, yatay nav görünür
- Drawer dışına tıklamak veya link seçmek drawer'ı kapatır
- `/profil`, `/favoriler`, `/gelen-kutusu` sayfalarında header görünür
- Giriş yapılmamış kullanıcıda Hesap bölümü yerine "Giriş Yap" gösterilir
- Okunmamış mesaj varsa Gelen Kutusu badge gösterir
- Dark mode'da gradient ve renkler doğru render edilir
