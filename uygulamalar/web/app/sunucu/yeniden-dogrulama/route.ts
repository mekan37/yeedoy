// Bu rota, /api/revalidate ile birebir aynı implementasyondu (iki ayrı dosyada
// aynı secret'i doğrulayan aynı kod) — tek kaynak /api/revalidate'e taşındı.
// Hangi URL'in dış sistemlerde (deploy pipeline / Supabase webhook) yapılandırıldığı
// bilinmediğinden iki URL de çalışmaya devam eder, ama artık tek implementasyon var.
export { POST } from '@/app/api/revalidate/route';
