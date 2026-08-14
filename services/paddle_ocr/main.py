"""
PaddleOCR microservice for Yeedoy menu analysis.
Accepts image URL or base64, returns extracted text lines.
"""

import atexit
import base64
import io
import logging
import os
from contextlib import asynccontextmanager
from typing import Optional

import httpx
from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, HttpUrl
from PIL import Image
import numpy as np
from paddleocr import PaddleOCR
from posthog import Posthog

from config import get_settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("paddle_ocr_service")

# ─── PaddleOCR singleton ──────────────────────────────────────────────────────
# use_angle_cls=True handles rotated text (common in photo menus)
# lang="en" covers Latin scripts; "ch" covers Chinese+Latin
# For Turkish menus (Latin script) "en" is sufficient
_ocr: Optional[PaddleOCR] = None

def get_ocr() -> PaddleOCR:
    global _ocr
    if _ocr is None:
        _ocr = PaddleOCR(
            use_angle_cls=True,
            lang="en",
            use_gpu=False,
            show_log=False,
        )
    return _ocr


# ─── FastAPI app ──────────────────────────────────────────────────────────────


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize the shared PostHog client and flush it during shutdown."""
    settings = get_settings()
    project_token = settings.posthog_project_token
    host = settings.posthog_host

    if not project_token or not host:
        if settings.debug:
            missing_var = "POSTHOG_PROJECT_TOKEN" if not project_token else "POSTHOG_HOST"
            raise RuntimeError(
                f"{missing_var} variable required by PostHog is missing or un-configured, "
                f"this causes events to be silently missed. This error stops appearing once "
                f"{missing_var} is configured"
            )
        app.state.posthog_client = None
        yield
        return

    posthog_client = Posthog(
        project_token,
        host=host,
        enable_exception_autocapture=True,
    )
    app.state.posthog_client = posthog_client
    atexit.register(posthog_client.shutdown)

    try:
        yield
    finally:
        posthog_client.flush()
        posthog_client.shutdown()


app = FastAPI(
    title="Yeedoy PaddleOCR Service",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def posthog_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Capture unhandled application exceptions before returning a 500 response."""
    posthog_client: Optional[Posthog] = getattr(request.app.state, "posthog_client", None)
    if posthog_client is not None:
        posthog_client.capture_exception(exc)

    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


SERVICE_SECRET = os.environ.get("PADDLE_OCR_SECRET", "")

ALLOWED_MIMES = {"image/jpeg", "image/png", "image/webp", "image/bmp", "image/tiff"}
MAX_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


# ─── models ──────────────────────────────────────────────────────────────────

class OcrRequest(BaseModel):
    # Provide either image_url OR image_base64 + media_type
    image_url: Optional[str] = None
    image_base64: Optional[str] = None
    media_type: Optional[str] = "image/jpeg"


class OcrLine(BaseModel):
    text: str
    confidence: float
    bbox: list[list[float]]


class OcrResponse(BaseModel):
    ok: bool
    lines: list[OcrLine] = []
    raw_text: str = ""
    error: Optional[str] = None


# ─── helpers ─────────────────────────────────────────────────────────────────

async def fetch_image_bytes(url: str) -> bytes:
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url)
    if resp.status_code != 200:
        raise HTTPException(status_code=422, detail="image_fetch_failed")
    content_type = resp.headers.get("content-type", "").split(";")[0].strip().lower()
    if content_type not in ALLOWED_MIMES:
        raise HTTPException(status_code=422, detail=f"unsupported_mime: {content_type}")
    if len(resp.content) > MAX_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="image_too_large")
    return resp.content


def decode_base64_image(b64: str, media_type: str) -> bytes:
    if media_type not in ALLOWED_MIMES:
        raise HTTPException(status_code=422, detail=f"unsupported_mime: {media_type}")
    try:
        data = base64.b64decode(b64)
    except Exception:
        raise HTTPException(status_code=422, detail="invalid_base64")
    if len(data) > MAX_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="image_too_large")
    return data


def image_bytes_to_numpy(data: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(data)).convert("RGB")
    return np.array(img)


def run_paddle_ocr(img_array: np.ndarray) -> list[OcrLine]:
    ocr = get_ocr()
    result = ocr.ocr(img_array, cls=True)
    lines: list[OcrLine] = []
    if not result:
        return lines
    for block in result:
        if not block:
            continue
        for item in block:
            if not item or len(item) < 2:
                continue
            bbox, (text, confidence) = item
            text = text.strip()
            if text:
                lines.append(OcrLine(text=text, confidence=float(confidence), bbox=bbox))
    return lines


# ─── endpoints ───────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"ok": True}


@app.post("/ocr", response_model=OcrResponse)
async def ocr_endpoint(
    body: OcrRequest,
    request: Request,
    x_service_secret: str = Header(default="", alias="x-service-secret"),
):
    # Validate service secret (if configured)
    if SERVICE_SECRET and x_service_secret != SERVICE_SECRET:
        raise HTTPException(status_code=401, detail="invalid_secret")

    if not body.image_url and not body.image_base64:
        raise HTTPException(status_code=400, detail="provide image_url or image_base64")

    try:
        if body.image_url:
            data = await fetch_image_bytes(body.image_url)
        else:
            data = decode_base64_image(body.image_base64 or "", body.media_type or "image/jpeg")

        img_array = image_bytes_to_numpy(data)
        lines = run_paddle_ocr(img_array)
        raw_text = "\n".join(line.text for line in lines)

        posthog_client: Optional[Posthog] = getattr(
            request.app.state, "posthog_client", None
        )
        if posthog_client is not None:
            posthog_client.capture(
                "ocr_completed",
                properties={
                    "input_source": "image_url" if body.image_url else "image_base64",
                    "media_type": body.media_type or "image/jpeg",
                    "line_count": len(lines),
                    "has_extracted_text": bool(raw_text),
                },
            )

        return OcrResponse(ok=True, lines=lines, raw_text=raw_text)

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("OCR processing error")
        posthog_client: Optional[Posthog] = getattr(
            request.app.state, "posthog_client", None
        )
        if posthog_client is not None:
            posthog_client.capture(
                "ocr_processing_failed",
                properties={"error_type": type(e).__name__},
            )
        return OcrResponse(ok=False, error=str(e))
