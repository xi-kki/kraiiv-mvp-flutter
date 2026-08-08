---
title: Kraiiv Food Recognition API
sdk: docker
app_port: 7860
colorFrom: green
colorTo: emerald
pinned: false
---

This folder is the Hugging Face Space repo: after creating an empty
Docker-SDK Space, push this directory's contents to it and it serves the
Kraiiv food API (see the Dockerfile notes on why the image stays lean).

To deploy:

```bash
cd model-api
git init
git add .
git commit -m "Kraiiv food API"
git remote add space https://huggingface.co/spaces/<your-user>/kraiiv-api
git push space main
```

Then rebuild the Flutter web app pointing at the Space URL:

```bash
flutter build web --release \
  --dart-define=KRAIIV_API_URL=https://<your-user>-kraiiv-api.hf.space
```

The app falls back to the offline 46-food matcher if the API is unreachable,
so a slow Space cold start degrades gracefully.

---

# Kraiiv Food Recognition API

Serves real food identification to the Kraiiv MVP scanner.

## Models

1. **Nigerian Food Lens** (default) — EfficientNetV2-S fine-tuned on the
   NutriMama Nigerian food dataset. Detects 41 Nigerian foods
   (jollof rice, egusi soup, eba, moi moi, suya, ...) with confidence
   scores. Downloaded from Hugging Face on first run
   (`yusasif/Nigerian-food-Lens`), ~model weights cached locally.
2. **COCO SSD MobileNet** (fallback) — the OpenCV pipeline from
   [xi-kki/An-Object-Detection-App](https://github.com/xi-kki/An-Object-Detection-App)
   (80 COCO classes). Used automatically when the food model is missing,
   so generic items (apple, banana, ...) still resolve.

## Setup

```bash
cd model-api
pip install -r requirements.txt
# Optional: copy the COCO fallback weights from your object detection repo:
cp ../kraiiv-ai/An-Object-Detection-App/frozen_inference_graph.pb . \
   ../kraiiv-ai/An-Object-Detection-App/ssd_mobilenet_v3_large_coco_2020_01_14.pbtxt . \
   ../kraiiv-ai/An-Object-Detection-App/coco.names .
cp ../assets/data/nigerian_foods.json .   # nutrition enrichment
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/health` | Status, which model is loaded |
| `POST` | `/detect` | Upload an image → `{"detected": [{food, confidence, ...}], "model": "..."}` |

```bash
curl -X POST -F "file=@plate.jpg" http://localhost:8000/detect
```

## Enrichment

Detected foods are matched against the Kraiiv food database
(`nigerian_foods.json`) and returned with `healthScore`, `calories`,
`protein`, `insight` and a `local` flag — exactly what the MVP result
screen needs.

## Training (via Neo)

See `../kraiiv-ai/README.md` for the dataset downloads (CHOWNET, Kaggle
Nigeria Food AI Dataset) and the Neo training task that expands this
41-class model to more African local and healthy foods.
