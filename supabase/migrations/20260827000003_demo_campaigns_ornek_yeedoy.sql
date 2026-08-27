-- Kampanyalar sayfası artık gerçek public.campaigns tablosundan okuyor (önceden
-- her işletme için sahte/uydurma kampanya gösteriyordu). Production'da hiç
-- kampanya olmadığı için (owner panelinden henüz kimse kullanmadı), sayfanın
-- gerçek veriyle nasıl göründüğünü test edebilmek için Örnek Yeedoy hesabından
-- birkaç gerçekçi demo kampanya ekliyoruz — tıpkı bir işletme sahibinin owner
-- panelinden oluşturacağı gibi (owner_upsert_campaign_v1'in yapacağı INSERT'in
-- birebir aynısı, sadece RPC'yi auth.uid() context'i olmadan çağıramadığımız
-- için doğrudan tabloya yazıyoruz).
INSERT INTO public.campaigns
  (business_id, title, description, type, status, discount_percent, starts_at, ends_at)
VALUES
  (
    '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
    'Hafta Sonu %20 İndirim',
    'Cuma-Pazar arası tüm ana yemeklerde geçerli, masada söylemen yeterli.',
    'discount', 'active', 20,
    now() - interval '2 days', now() + interval '5 days'
  ),
  (
    '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
    'Aile Menüsü Fırsatı',
    '4 kişilik aile menüsünde çorba ve tatlı ücretsiz.',
    'special_offer', 'active', NULL,
    now() - interval '1 day', now() + interval '14 days'
  ),
  (
    '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
    '5. Ziyaretinde Kahve Hediye',
    'Sadakat kartına her ziyarette bir damga, 5 damgada bir kahve bizden.',
    'loyalty', 'active', NULL,
    now() - interval '10 days', NULL
  ),
  (
    '2e9be57b-62cd-4f5f-bb4b-0d665994765c',
    'Yeni Sonbahar Menümüz Yayında',
    'Mevsim ürünleriyle hazırlanan yeni tatlarımızı denemeye bekleriz.',
    'announcement', 'active', NULL,
    now() - interval '3 days', now() + interval '30 days'
  );
