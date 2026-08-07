"""
Kraiiv Food Recognition API

Wraps the Nigerian Food Lens model (EfficientNetV2-S, 41 Nigerian food
classes, https://huggingface.co/yusasif/Nigerian-food-recognision) behind
a simple /detect endpoint that the Kraiiv MVP scanner calls.

Falls back to the COCO SSD MobileNet detector (the pipeline from
https://github.com/xi-kki/An-Object-Detection-App) when the food model
is not available, so generic items (apple, banana, ...) still resolve.

Run:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000
"""


import hashlib
import io
import json
import logging
import threading
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

logger = logging.getLogger("kraiiv-api")
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Warm the food model in the background so the first /detect is not
    # blocked on the ~80MB Hugging Face download + load. If it fails
    # (e.g. torch missing), requests fall back per-call as designed.
    threading.Thread(target=_load_food_model, daemon=True).start()
    yield


app = FastAPI(
    title="Kraiiv Food Recognition",
    version="1.1.0",
    lifespan=lifespan,
)
# No cookies/credentials are used by this API, so a permissive CORS policy
# is acceptable; abuse control comes from the rate limiter below (and an
# edge allowlist in front of the service once it is hosted).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# Nigerian Food Lens — pinned to an exact commit + sha256 so a compromised
# or mutated Hugging Face repo can never feed us a tampered weights file.
# The weights are a pickle; torch.load on them is arbitrary code execution
# unless pinned and verified (see _load_food_model).
MODEL_REPO = "yusasif/Nigerian-food-recognision"
MODEL_REVISION = "36a13b5de1ecc61162f7d1ee21e28b11420cdb29"
MODEL_SHA256 = "7857709a114ea3c868d0e7a6abf42d9031e8704964b6be26437d8a289c70372f"

FOOD_DB_PATH = Path(__file__).parent / "nigerian_foods.json"
MAX_UPLOAD_BYTES = 16 * 1024 * 1024
# Hard ceiling on decoded pixels: rejects decompression-bomb images (tiny
# compressed file, huge dimensions) before any decode work happens.
Image.MAX_IMAGE_PIXELS = 16_000_000


# ─── Nutrition enrichment ────────────────────────────────────────────────
def _load_food_db() -> dict[str, dict]:
    if not FOOD_DB_PATH.exists():
        return {}
    try:
        foods = json.loads(FOOD_DB_PATH.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover
        logger.warning("Could not load food DB: %s", exc)
        return {}
    return {f["name"].lower(): f for f in foods}


FOOD_DB = _load_food_db()

# Nigerian Food Lens label → Kraiiv food DB key (name contains match).
ALIASES = {
    "akara": "Akara and Pap",
    "amala": "Amala and Ewedu Soup",
    "banga soup": "Banga Soup and Starch",
    "beans": "Beans Porridge",
    "bitterleaf soup": "Vegetable Soup",
    "eba": "Eba and Egusi Soup",
    "edikaikong": "Ugwu Soup and Fufu",
    "efo riro": "Vegetable Soup",
    "egusi soup": "Eba and Egusi Soup",
    "ewedu": "Amala and Ewedu Soup",
    "fufu": "Ugwu Soup and Fufu",
    "jollof rice": "Jollof Rice and Chicken",
    "moi moi": "Moi Moi and Plantain",
    "nkwobi": "Asun (Spicy Goat Meat)",
    "ogbono soup": "Pounded Yam and Ogbono Soup",
    "ogi": "Akara and Pap",
    "okra soup": "Okra Soup and Fufu",
    "plantain": "Moi Moi and Plantain",
    "rice": "White Rice and Stew",
    "spaghetti": "Spaghetti (Pasta)",
    "stew": "White Rice and Stew",
    "suya": "Suya",
    "puff puff": "Puff Puff",
    "chin chin": "Chin Chin",
}


def _enrich(food_label: str, confidence: float) -> dict:
    """Attach Kraiiv nutrition data to a detected label when we can."""
    key = ALIASES.get(food_label.lower(), food_label.lower())
    entry = FOOD_DB.get(key)
    if entry is None:
        # Try a loose substring match.
        entry = next(
            (f for name, f in FOOD_DB.items() if key in name or name in key),
            None,
        )
    result: dict = {"food": food_label, "confidence": round(confidence, 3)}
    if entry:
        result.update(
            {
                "healthScore": entry.get("health_score"),
                "calories": entry.get("calories"),
                "protein": entry.get("protein"),
                "insight": entry.get("insight"),
                "local": True,
            }
        )
    return result


# ─── Nigerian Food Lens (torch) ──────────────────────────────────────────
_food_model = None
_food_labels: list[str] = []
_model_load_lock = threading.Lock()


def _load_food_model():
    """Lazily load the EfficientNetV2-S multi-label food model.

    The weights file is a pickle, so it is treated as untrusted input:
    downloaded from a pinned revision and verified against a pinned sha256
    before torch.load (weights_only=True) touches it.
    """
    global _food_model, _food_labels
    if _food_model is not None:
        return _food_model

    # Double-checked locking: the lifespan warm-up and the first /detect
    # may race; only one thread should download + load the weights.
    with _model_load_lock:
        if _food_model is not None:
            return _food_model

        import torch
        import torch.nn as nn
        from huggingface_hub import hf_hub_download
        from torchvision import models

        model_path = hf_hub_download(
            MODEL_REPO, "best_model.pth", revision=MODEL_REVISION
        )
        vocab_path = hf_hub_download(
            MODEL_REPO, "label_vocab.json", revision=MODEL_REVISION
        )

        # Verify the pinned sha256 before touching the file with torch.
        digest = hashlib.sha256(Path(model_path).read_bytes()).hexdigest()
        if digest != MODEL_SHA256:
            raise RuntimeError(
                f"Model checksum mismatch (got {digest[:12]}…, expected "
                f"{MODEL_SHA256[:12]}…) — refusing to load"
            )

        _food_labels = json.loads(Path(vocab_path).read_text(encoding="utf-8"))[
            "labels"
        ]

        # weights_only=True refuses pickle payloads that are not plain
        # tensors — the standard mitigation for pickle-based RCE via model
        # files. This checkpoint embeds numpy scalar/dtype fill-values, so
        # allowlist exactly those data types (value types, not code).
        # numpy 2.x moved the real implementations to numpy._core/numpy.
        # dtypes, so the tuple form pins entries to the paths the pickle
        # actually references.
        import numpy as np

        torch.serialization.add_safe_globals(
            [
                (np.core.multiarray.scalar, "numpy.core.multiarray.scalar"),
                (np.dtype, "numpy.dtype"),
                np.dtypes.Float64DType,
            ]
        )
        checkpoint = torch.load(model_path, map_location="cpu", weights_only=True)
        model = models.efficientnet_v2_s(weights=None)
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(model.classifier[1].in_features, len(_food_labels)),
        )
        model.load_state_dict(checkpoint["model_state_dict"])
        model.eval()
        _food_model = model
        logger.info("Loaded Nigerian Food Lens (%d classes)", len(_food_labels))
        return _food_model


def _food_detect(image: Image.Image) -> list[dict]:
    import torch
    from torchvision import transforms

    transform = transforms.Compose(
        [
            transforms.Resize((384, 384)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
            ),
        ]
    )
    model = _load_food_model()
    with torch.no_grad():
        probs = torch.sigmoid(model(transform(image).unsqueeze(0))).squeeze(0)
        probs = probs.numpy()

    results = []
    for idx, prob in enumerate(probs):
        if prob >= 0.3:
            results.append(_enrich(_food_labels[idx], float(prob)))
    results.sort(key=lambda r: r["confidence"], reverse=True)
    return results[:6]


# ─── COCO SSD MobileNet fallback (from An-Object-Detection-App) ──────────
_coco_detector = None


def _load_coco_detector():
    """Lazily load the OpenCV SSD MobileNet detector (80 COCO classes)."""
    global _coco_detector
    if _coco_detector is not None:
        return _coco_detector

    import cv2

    base = Path(__file__).parent
    detector = {
        "net": cv2.dnn.readNetFromTensorflow(
            str(base / "frozen_inference_graph.pb"),
            str(base / "ssd_mobilenet_v3_large_coco_2020_01_14.pbtxt"),
        ),
        "classes": [
            line.strip()
            for line in (base / "coco.names").read_text().splitlines()
            if line.strip()
        ],
    }
    _coco_detector = detector
    logger.info("Loaded COCO SSD MobileNet (%d classes)", len(detector["classes"]))
    return detector


def _coco_detect(image: Image.Image) -> list[dict]:
    import cv2
    import numpy as np

    detector = _load_coco_detector()
    blob = cv2.dnn.blobFromImage(
        cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR),
        size=(320, 320),
        swapRB=False,
    )
    detector["net"].setInput(blob)
    detections = detector["net"].forward()

    results = []
    h, w = image.size[1], image.size[0]
    for i in range(detections.shape[2]):
        confidence = float(detections[0, 0, i, 2])
        if confidence < 0.5:
            continue
        class_id = int(detections[0, 0, i, 1])
        label = detector["classes"][class_id] if class_id < len(detector["classes"]) else "object"
        # Only surface food-relevant COCO classes for the MVP.
        if label in {
            "apple", "banana", "orange", "sandwich", "pizza", "hot dog",
            "broccoli", "carrot", "donut", "cake", "bowl", "cup", "fork",
            "knife", "spoon", "dining table", "cake",
        }:
            results.append(
                {"food": label, "confidence": round(confidence, 3), "local": False}
            )
    results.sort(key=lambda r: r["confidence"], reverse=True)
    return results[:6]


# ─── Endpoints ───────────────────────────────────────────────────────────
@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "food_model": _food_model is not None,
        "coco_fallback": (Path(__file__).parent / "frozen_inference_graph.pb").exists(),
        "foods_in_db": len(FOOD_DB),
    }


@app.post("/detect")
@limiter.limit("10/minute")
async def detect(request: Request, file: UploadFile = File(...)) -> dict:
    raw = await file.read()
    if len(raw) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 16MB)")
    # Validate by content (magic bytes), not by the client-supplied
    # Content-Type header — headers are trivially spoofed and real clients
    # (Dart's http package) send application/octet-stream anyway.
    if not (
        raw.startswith(b"\xff\xd8\xff")          # JPEG
        or raw.startswith(b"\x89PNG\r\n\x1a\n")  # PNG
        or (raw.startswith(b"RIFF") and raw[8:12] == b"WEBP")
    ):
        raise HTTPException(status_code=415, detail="Only JPEG/PNG/WebP allowed")

    # Dimension check BEFORE decoding: a tiny compressed file can declare
    # hundreds of megapixels (decompression bomb). Pillow's own guard
    # (MAX_IMAGE_PIXELS, set at module level) raises DecompressionBombError
    # at open(); we map it to a clean 413.
    try:
        with Image.open(io.BytesIO(raw)) as probe:
            width, height = probe.size
        if width * height > Image.MAX_IMAGE_PIXELS:
            raise HTTPException(status_code=413, detail="Image dimensions too large")
    except Image.DecompressionBombError:
        raise HTTPException(status_code=413, detail="Image dimensions too large")
    except HTTPException:
        raise
    except Exception as exc:
        logger.info("Invalid image upload: %s", exc)
        raise HTTPException(status_code=400, detail="Invalid image")

    try:
        image = Image.open(io.BytesIO(raw)).convert("RGB")
    except Exception as exc:
        logger.info("Could not decode image: %s", exc)
        raise HTTPException(status_code=400, detail="Invalid image")

    # 1) Nigerian food model (preferred)
    try:
        detected = _food_detect(image)
        return {"detected": detected, "model": "nigerian-food-lens"}
    except Exception as exc:
        logger.warning("Food model failed (%s) — trying COCO fallback", exc)

    # 2) COCO SSD MobileNet fallback (generic foods)
    try:
        detected = _coco_detect(image)
        return {"detected": detected, "model": "coco-ssd-mobilenet"}
    except Exception as exc:
        logger.warning("COCO detector failed: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="No food model available. Run the setup step in README.md.",
        )
