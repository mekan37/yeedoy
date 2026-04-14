# Yeedoy PaddleOCR Service

Menu görsel OCR servisi. PaddleOCR ile image → raw_text dönüşümü yapar.
Çıktıyı `ai-menu-analyze` edge function Claude API analizine besler.

## Mimari

```
Panel (Flutter)
    ↓ POST file
Supabase Storage
    ↓ create_menu_ocr_job_v1
menu_ocr_jobs (status: queued)
    ↓ triggerAnalysis (edge function)
ai-menu-analyze (Deno)
    ↓ POST /ocr  ← bu servis
PaddleOCR Service (Python / Docker)
    ↓ raw_text
Claude Haiku API
    ↓ structured JSON
menu_item_ai_analysis (status: pending_review)
    ↓
Panel review UI → owner onaylar
```

## Çalıştırma

### Docker Compose (önerilen)

```bash
docker build -t yeedoy-paddle-ocr .
docker run -d \
  -p 8000:8000 \
  -e PADDLE_OCR_SECRET=your_strong_secret \
  --name paddle-ocr \
  yeedoy-paddle-ocr
```

### Health check

```bash
curl http://localhost:8000/health
# {"ok":true}
```

### Manuel test

```bash
curl -X POST http://localhost:8000/ocr \
  -H "Content-Type: application/json" \
  -H "x-service-secret: your_strong_secret" \
  -d '{"image_url":"https://example.com/menu.jpg"}'
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `PADDLE_OCR_SECRET` | Hayır | Edge function'ın göndereceği `x-service-secret` header değeri |
| `PORT` | Hayır | Dinlenecek port (default: 8000) |

## Edge Function Secrets (Supabase)

```bash
supabase secrets set PADDLE_OCR_URL=http://127.0.0.1:8000
supabase secrets set PADDLE_OCR_SECRET=Tunahan_120819
supabase secrets set ANTHROPIC_API_KEY=your_anthropic_key
```

`PADDLE_OCR_URL` set edilmezse edge function PaddleOCR'ı atlar
ve sadece DB'deki `raw_text` (manuel set) ile Claude analizini çalıştırır.

## Deployment Seçenekleri

| Platform | Notlar |
|---|---|
| Railway | `railway up` — Dockerfile otomatik algılanır |
| Render | Docker service, free tier yavaş startup |
| Fly.io | `fly deploy` — persistent volume OCR model cache için |
| Kendi sunucu | Docker + nginx reverse proxy |

## Model Boyutu

İlk `docker build` sırasında PaddleOCR modelleri (~400MB) indirilir ve
image'a gömülür. Bu sayede container başlatma süresi < 5s olur.

## Notlar

- `use_gpu=False` — CPU ile çalışır, GPU gerekmez
- `lang="en"` — Latin script (Türkçe dahil)
- Diğer diller için `lang="ch"` (Çince+Latin) veya `lang="fr"` kullanılabilir
- `use_angle_cls=True` — Döndürülmüş/eğik yazıyı düzeltir
