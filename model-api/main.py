"""
Kraiiv Food Recognition API

Wraps the Nigerian Food Lens model (EfficientNetV2-S, 41 Nigerian food
classes, https://huggingface.co/yusasif/Nigerian-food-Lens) behind a
simple /detect endpoint that the Kraiiv MVP scanner calls.

Falls back to the COCO SSD MobileNet detector (the pipeline from
https://github.com/xi-kki/An-Object-Detection-App) when the food model
is not available, so generic items (apple, banana, ...) still resolve.

Run:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

logger = logging.getLogger("kraiiv-api")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="Kraiiv Food Recognition", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_REPO = "yusasif/Nigerian-food-Lens"
FOOD_DB_PATH = Path(__file__).parent / "nigerian_foods.json"
MAX_UPLOAD_BYTES = 16 * 1024 * 1024


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


def _load_food_model():
    """Lazily load the EfficientNetV2-S multi-label food model."""
    global _food_model, _food_labels
    if _food_model is not None:
        return _food_model

    import torch
    import torch.nn as nn
    from huggingface_hub import hf_hub_download
    from torchvision import models

    model_path = hf_hub_download(MODEL_REPO, "best_model.pth")
    vocab_path = hf_hub_download(MODEL_REPO, "label_vocab.json")
    _food_labels = json.loads(Path(vocab_path).read_text(encoding="utf-8"))[
        "labels"
    ]

    checkpoint = torch.load(model_path, map_location="cpu", weights_only=False)
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
async def detect(file: UploadFile = File(...)) -> dict:
    raw = await file.read()
    if len(raw) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 16MB)")
    if file.content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(status_code=415, detail="Only JPEG/PNG/WebP allowed")

    try:
        image = Image.open(__import__("io").BytesIO(raw)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}")

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
