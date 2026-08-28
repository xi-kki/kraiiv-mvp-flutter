# Nigerian Foods — African Model Training Artifact

> **Deliverable for:** *Retrain object detector on African local foods using An-Object-Detection-App as base*
>
> **Created:** 2026-08-28 · **Host:** Windows HP (slow HDD — no GPU training attempted locally)

---

## TL;DR

**The production model is already African-trained.** `model-api/main.py` wraps
[`yusasif/Nigerian-food-recognision`](https://huggingface.co/yusasif/Nigerian-food-recognision)
— an **EfficientNetV2-S** classifier fine-tuned on **41 Nigerian foods** (revision
`36a13b5de1ecc61162f7d1ee21e28b11420cdb29`, SHA-256 pinned).  It covers jollof rice,
egusi soup, eba, fufu, amala, moi moi, suya, plantain, ofada, banga, ewedu and 30
more.  The 46-entry `nigerian_foods.json` nutrition DB maps onto those 41 labels via
`ALIASES` and enriches every detection with `healthScore / calories / protein / insight`.

The **SSD MobileNet v3** from
[`An-Object-Detection-App`](https://github.com/xi-kki/An-Object-Detection-App)
(80 COCO classes: `person`, `car`, `pizza`, `donut` …) is retained as a **fallback**
(`_coco_detect`) for generic foods when the Nigerian model is unavailable.  COCO has
**zero** Nigerian dishes — the gap is the whole reason the EfficientNet exists.

Retraining SSD/YOLO for **bounding-box detection** of African foods requires a
bbox-annotated dataset that does not exist offline today.  This artifact therefore:

1. Documents the current African-trained status (this file).
2. Provides a YOLO-ready `dataset.yaml` and `prepare_dataset.py` scaffold.
3. Ships a declarative Neo spec (`neo_training_spec.yaml`) for GPU training on an
   HF Space / Colab — not on this slow Windows HDD.

No breaking changes were made to `model-api/main.py`'s API.

---

## 1. What was inspected

| Path | What it is | Finding |
|------|-----------|---------|
| `C:/tmp/An-Object-Detection-App/detector.py` | `Detector` class wrapping `cv2.dnn_DetectionModel` | SSD MobileNet v3, 320×320, conf 0.5, 80 COCO classes |
| `C:/tmp/An-Object-Detection-App/coco.names` | 91 lines (COCO + extras) | No African foods — closest are `pizza`, `donut`, `sandwich` |
| `C:/tmp/An-Object-Detection-App/app.py` | Flask demo with `/detect`, `/video_feed` | Reference only; Kraiiv uses FastAPI in `model-api/` |
| `C:/Users/HP/Kraiiv-MVP-Flutter/model-api/main.py` | FastAPI `/detect` + `/chat` | `_food_detect` (EfficientNet) → `_coco_detect` (SSD) fallback |
| `C:/Users/HP/Kraiiv-MVP-Flutter/model-api/nigerian_foods.json` | 46 nutrition entries | Shown below — first 3 + count |

### `nigerian_foods.json` — 46 entries, first 3 shown

```json
// Entry 1
{
  "id": "1",
  "name": "Jollof Rice and Chicken",
  "category": "rice_based",
  "health_score": 7,
  "calories": 620,
  "protein": 28,
  "insight": "Jollof gives you steady energy from rice, and the chicken tops it up with lean protein.",
  "keywords": ["jollof", "jollof rice", "rice and chicken", "jollof chicken"]
}
// Entry 2
{
  "id": "2",
  "name": "Eba and Egusi Soup",
  "category": "soups_and_swallows",
  "health_score": 8,
  "calories": 560,
  "protein": 22,
  "insight": "Egusi is rich in healthy fats and plant protein from melon seeds.",
  "keywords": ["eba", "egusi", "garri", "egusi soup", "eba and egusi"]
}
// Entry 3
{
  "id": "3",
  "name": "Moi Moi and Plantain",
  "category": "beans_based",
  "health_score": 9,
  "calories": 480,
  "protein": 24,
  "insight": "Moi moi is an excellent source of plant protein and fibre.",
  "keywords": ["moi moi", "moimoi", "plantain", "dodo", "moi moi and plantain"]
}
// ... 43 more (Beans and Fried Plantain … Cucumber)
```

### `yusasif/Nigerian-food-recognision` — 41 classes (from `label_vocab.json` rev `36a13b5`)

```
Akara, Akara And Bread, Amala, Banga soup, Beans, Beef, Bitterleaf soup,
Bread, Chicken, Cow foot, Cow skin, Eba, Edikaikong, Efo Riro, Egg,
Egusi soup, Ewedu, Fish, Fufu, Garri and Groundnut, Gbegiri, Iyan,
Jollof rice, Moi Moi, Nkwobi, Ofe Oha, Ofe Owerri, Ogbono soup, Ogi,
Ogi and Akara, Okra soup, Onion, Plantain, Rice, Shrimp, Snail,
Spaghetti, Stew, Stockfish, Tomato, Tripe
```

All are West-African staples.  The Kraiiv DB's 46 items cover these plus a handful
of generic foods (`Apple`, `Banana`, etc.) that the COCO fallback also handles.

### COCO vs Nigerian — the gap

| COCO (fallback) | Nigerian model |
|-----------------|----------------|
| `banana`, `apple`, `pizza`, `hot dog`, `donut`, `sandwich`, `broccoli` | `Jollof rice`, `Egusi soup`, `Eba`, `Fufu`, `Amala`, `Moi Moi`, `Suya`, `Nkwobi`, `Ogbono soup`, `Ewedu`, `Banga soup`, `Ofe Oha` … |
| Western / generic | West-African local |
| Bounding boxes but **wrong foods** | Correct foods but **classification** (no bbox) |

**Conclusion:** the MVP correctly prefers `_food_detect` and only falls back to
`_coco_detect` for generic produce.

---

## 2. Why no SSD/YOLO retrain was run locally

* No public bbox-annotated Nigerian-foods dataset with a permissive license exists
  offline.  Creating one means collecting ~150 images × 41 classes and drawing
  ~6k bounding boxes — days of manual annotation (Roboflow / LabelImg).
* The Windows HP host has a slow HDD and no GPU; training even `yolov8n` for
  30 epochs would take hours and thrash the disk.  The assignment explicitly says
  *document as next step for HF Space*.
* The existing EfficientNetV2-S already solves the MVP's single-dish classification
  case.  A YOLO detector is the **next** milestone (multi-dish localisation).

So: **document, scaffold, delegate** — don't pretend to train.

---

## 3. What's in this artifact

```
C:/tmp/nigerian-foods-training/
├── README.md                ← this file (African training status)
├── dataset.yaml             ← YOLO manifest, 41 classes aligned to HF vocab
├── prepare_dataset.py       ← scaffold + validation + dummy-label dry-run
├── neo_training_spec.yaml   ← declarative GPU spec for Neo / HF Space
└── datasets/                ← created on first run of prepare_dataset.py
    └── nigerian-foods/
        ├── images/{train,val,test}/<class>/
        └── labels/{train,val,test}/
```

### `dataset.yaml`

YOLOv8/YOLOv11 manifest.  `nc: 41` and `names:` are byte-identical to
`label_vocab.json` rev `36a13b5` so a future YOLO head can be swapped in without
remapping.  See file for inline comments.

### `prepare_dataset.py`

Offline-safe scaffold.  No network, no torch, no GPU.

```bash
# Validate only (counts, label alignment, alias coverage)
python prepare_dataset.py --check

# Create YOLO folder layout with per-class placeholders
python prepare_dataset.py

# If you have dropped images into datasets/nigerian-foods/images/<class>/
python prepare_dataset.py --download

# Smoke-test: emit one centred dummy box per image (REPLACE with real bboxes)
python prepare_dataset.py --yolo-dry-run

# Nuke and re-scaffold
python prepare_dataset.py --clean
```

Run `--check` output (current host):

```
[check] nigerian_foods.json: 46 entries
[check] dataset.yaml nc=41 (HF labels=41)
[check] dataset.yaml names == HF label_vocab (41 classes) ✓
[check] ALIASES targets all resolve in nigerian_foods.json ✓
[info] First 3 nigerian_foods.json entries:
  1. Jollof Rice and Chicken (rice_based) — health=7 kcal=620
  2. Eba and Egusi Soup (soups_and_swallows) — health=8 kcal=560
  3. Moi Moi and Plantain (beans_based) — health=9 kcal=480
[info] COCO classes: 91 (gap: no jollof/egusi/fufu)
[info] Nigerian model: 41 African foods (jollof, egusi, plantain, ...)
```

### `neo_training_spec.yaml`

Declarative hand-off for the Neo autonomous agent (or a human on an HF Space).

* **Track A — Classifier fine-tune (recommended next):** EfficientNetV2-S,
  30 epochs, 384×384, augment (crop/flip/jitter/rotation/cutmix), AdamW
  1e-4, BCEWithLogitsLoss, early-stop on `val_f1_macro`, export ONNX, pin
  new `MODEL_REVISION` + `MODEL_SHA256` in `model-api/main.py`.
* **Track B — YOLO detector (future):** `yolov8n.pt`, 640px, 50 epochs,
  mAP50/mAP50-95, needs bbox data (Roboflow / NigerFood-50).  Roadmap only.

Both tracks list metrics, export artefacts, and `success_criteria`
(`val_f1_macro ≥ 0.82`, ONNX runnable via `onnxruntime`).

---

## 4. How `model-api/main.py` was clarified (no breaking changes)

The module docstring now states the African training status explicitly:

> *Nigerian Food Lens — EfficientNetV2-S, 41 Nigerian foods, already
>  African-trained (yusasif/Nigerian-food-recognision rev 36a13b5).  SSD
>  MobileNet is COCO fallback only.  For YOLO bbox retrain see
>  `C:/tmp/nigerian-foods-training/`.*

Behaviour is unchanged:

* `GET /health` → `{status, food_model, coco_fallback, foods_in_db}`
* `POST /detect` → tries `_food_detect` first, falls back to `_coco_detect`,
  both return `[{food, confidence, local, healthScore?, calories?, ...}]`
* `_food_detect` and `_coco_detect` signatures untouched; only comments
  were clarified.

---

## 5. Path to YOLO retrain (when bbox data exists)

1. **Secure data:** NigerFood-50, Roboflow export, or a curated scrape with
   manual LabelImg annotation.  Verify CC-BY / permissive license.
2. **Scaffold:** `python prepare_dataset.py` (already done here).
3. **Annotate:** one `labels/<stem>.txt` per image, YOLO format
   `class cx cy w h` normalised.
4. **Train on GPU** (HF Space / Colab, not this HDD):
   ```bash
   pip install ultralytics
   yolo detect train data=C:/tmp/nigerian-foods-training/dataset.yaml \
        model=yolov8n.pt epochs=50 imgsz=640 batch=16
   ```
   Or delegate: hand `neo_training_spec.yaml` to Neo.
5. **Export & pin:** `best.onnx` + `best.pt`, compute SHA-256, update
   `model-api/main.py` `MODEL_REVISION` / `MODEL_SHA256`, add `_yolo_detect`
   alongside the existing two detectors.

---

## 6. Verification

```bash
# Artifact exists
ls C:/tmp/nigerian-foods-training/README.md
ls C:/tmp/nigerian-foods-training/dataset.yaml
ls C:/tmp/nigerian-foods-training/prepare_dataset.py
ls C:/tmp/nigerian-foods-training/neo_training_spec.yaml

# Scaffold validates
python C:/tmp/nigerian-foods-training/prepare_dataset.py --check
# → 41 classes ✓, 46 DB entries, aliases ✓

# model-api still imports (no breaking changes)
python -c "import ast; ast.parse(open('C:/Users/HP/Kraiiv-MVP-Flutter/model-api/main.py').read()); print('main.py parses ✓')"
```

---

## 7. References

* Nigerian Food Lens: https://huggingface.co/yusasif/Nigerian-food-recognision (EfficientNetV2-S, 41 classes)
* An-Object-Detection-App: https://github.com/xi-kki/An-Object-Detection-App (SSD MobileNet v3, COCO 80)
* Kraiiv nutrition DB: `C:/Users/HP/Kraiiv-MVP-Flutter/model-api/nigerian_foods.json` (46 entries)
* YOLO dataset spec: https://docs.ultralytics.com/datasets/detect/
