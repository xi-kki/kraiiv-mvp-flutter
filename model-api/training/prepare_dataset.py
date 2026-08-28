#!/usr/bin/env python3
"""
Nigerian Foods — Dataset Preparation Script (YOLO format)

Maps Kraiiv's `nigerian_foods.json` + the Hugging Face label vocab
(yusasif/Nigerian-food-recognision, 41 classes, rev 36a13b5) into a
YOLO-ready folder layout with placeholder support for future bbox data.

What it does TODAY (no network, no GPU, safe on slow HDD):
  1. Reads model-api/nigerian_foods.json (46 nutrition entries).
  2. Reads dataset.yaml (41 detector classes).
  3. Validates alias coverage (ALIASES in model-api/main.py).
  4. Creates ./datasets/nigerian-foods/{images,labels}/{train,val,test}
     with .gitkeep + per-class README placeholders.
  5. Generates a YOLO labels manifest (empty until bboxes exist).
  6. Optionally — if --download is passed and datasets/images exist —
     wires real images into YOLO train/val splits and emits dummy
     centre-box labels for dry-run training (replace with real annots).

What it WILL do when an annotated dataset is available (e.g. NigerFood-50,
or a Roboflow export):
  - Download via huggingface_hub / Roboflow API.
  - Convert COCO/VOC/CSV bboxes → YOLO txt (class cx cy w h, normalised).
  - Split 80/10/10, de-duplicate, verify.

Usage:
  python prepare_dataset.py                  # scaffold only (default)
  python prepare_dataset.py --download       # also stage any images found
  python prepare_dataset.py --check          # validation only, no writes
  python prepare_dataset.py --yolo-dry-run   # emit dummy labels for smoke test

Requires: Python 3.10+, PyYAML (optional), Pillow (optional).
No torch / ultralytics needed for scaffolding.
"""

from __future__ import annotations

import argparse
import json
import random
import shutil
import sys
from pathlib import Path
from typing import Dict, List

# ── Paths ────────────────────────────────────────────────────────────
HERE = Path(__file__).resolve().parent
MODEL_API = Path("C:/Users/HP/Kraiiv-MVP-Flutter/model-api")
FOOD_DB_PATH = MODEL_API / "nigerian_foods.json"
DATASET_YAML = HERE / "dataset.yaml"
DATASETS_ROOT = HERE / "datasets" / "nigerian-foods"

# 41 labels from yusasif label_vocab.json (rev 36a13b5) — kept here so the
# script works offline without hitting Hugging Face.
HF_LABELS: List[str] = [
    "Akara", "Akara And Bread", "Amala", "Banga soup", "Beans", "Beef",
    "Bitterleaf soup", "Bread", "Chicken", "Cow foot", "Cow skin", "Eba",
    "Edikaikong", "Efo Riro", "Egg", "Egusi soup", "Ewedu", "Fish", "Fufu",
    "Garri and Groundnut", "Gbegiri", "Iyan", "Jollof rice", "Moi Moi",
    "Nkwobi", "Ofe Oha", "Ofe Owerri", "Ogbono soup", "Ogi", "Ogi and Akara",
    "Okra soup", "Onion", "Plantain", "Rice", "Shrimp", "Snail", "Spaghetti",
    "Stew", "Stockfish", "Tomato", "Tripe",
]

# ALIASES copied from model-api/main.py so coverage can be checked offline.
ALIASES: Dict[str, str] = {
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


# ── Helpers ──────────────────────────────────────────────────────────
def load_food_db() -> List[dict]:
    if not FOOD_DB_PATH.exists():
        print(f"[warn] {FOOD_DB_PATH} not found — using empty DB")
        return []
    return json.loads(FOOD_DB_PATH.read_text(encoding="utf-8"))


def parse_dataset_yaml() -> dict:
    if not DATASET_YAML.exists():
        raise FileNotFoundError(f"Missing {DATASET_YAML}")
    try:
        import yaml  # type: ignore
        return yaml.safe_load(DATASET_YAML.read_text(encoding="utf-8"))
    except ImportError:
        # Fallback: minimal parse for `names` block without PyYAML
        text = DATASET_YAML.read_text(encoding="utf-8")
        names: Dict[int, str] = {}
        for line in text.splitlines():
            line = line.strip()
            if ":" in line and line[0].isdigit():
                # e.g. "  0: Akara"
                try:
                    k, v = line.split(":", 1)
                    names[int(k.strip())] = v.strip()
                except ValueError:
                    pass
        return {"nc": len(names), "names": names}


def validate() -> bool:
    """Run offline checks; return True if all pass."""
    ok = True
    foods = load_food_db()
    yaml_data = parse_dataset_yaml()

    # 1) Count checks
    print(f"[check] nigerian_foods.json: {len(foods)} entries")
    if len(foods) != 46:
        print(f"  [warn] expected 46, got {len(foods)}")
    nc = yaml_data.get("nc", len(yaml_data.get("names", {})))
    print(f"[check] dataset.yaml nc={nc} (HF labels={len(HF_LABELS)})")
    if nc != len(HF_LABELS):
        print(f"  [fail] nc mismatch: yaml={nc} vs HF={len(HF_LABELS)}")
        ok = False

    # 2) Label alignment
    yaml_names = yaml_data.get("names", {})
    # yaml_names may be dict[int,str] or list[str]
    if isinstance(yaml_names, list):
        yaml_list = yaml_names
    elif isinstance(yaml_names, dict):
        yaml_list = [yaml_names[i] for i in sorted(yaml_names)]
    else:
        yaml_list = list(yaml_names.values())
    if yaml_list != HF_LABELS:
        print("  [fail] dataset.yaml names != HF_LABELS")
        for i, (a, b) in enumerate(zip(yaml_list, HF_LABELS)):
            if a != b:
                print(f"    idx {i}: yaml='{a}' vs HF='{b}'")
        ok = False
    else:
        print("[check] dataset.yaml names == HF label_vocab (41 classes) ✓")

    # 3) Alias coverage — every alias target should exist in food DB
    db_keys = {f["name"].lower() for f in foods}
    missing_targets = []
    for src, target in ALIASES.items():
        if target.lower() not in db_keys:
            # also allow substring match (as _enrich does)
            if not any(target.lower() in k or k in target.lower() for k in db_keys):
                missing_targets.append(f"{src!r} -> {target!r}")
    if missing_targets:
        print(f"[warn] {len(missing_targets)} alias targets not in DB (may use substring):")
        for m in missing_targets:
            print(f"  - {m}")
    else:
        print("[check] ALIASES targets all resolve in nigerian_foods.json ✓")

    # 4) Show first 3 entries as requested by assignment
    print("\n[info] First 3 nigerian_foods.json entries:")
    for i, entry in enumerate(foods[:3], 1):
        print(f"  {i}. {entry['name']} ({entry['category']}) — "
              f"health={entry.get('health_score')} kcal={entry.get('calories')}")

    # 5) COCO gap note
    coco_path = MODEL_API / "coco.names"
    if coco_path.exists():
        coco = [l.strip() for l in coco_path.read_text().splitlines() if l.strip()]
        print(f"\n[info] COCO classes: {len(coco)} (gap: no jollof/egusi/fufu — only western foods)")
        print(f"  COCO food subset: {[c for c in coco if c in ('apple','banana','pizza','sandwich','donut','cake')]}")
    print(f"[info] Nigerian model: {len(HF_LABELS)} African foods "
          f"(jollof, egusi, plantain, amala, suya, fufu, etc.)")

    return ok


def scaffold_structure() -> None:
    """Create YOLO folder layout with placeholders."""
    for split in ("train", "val", "test"):
        for kind in ("images", "labels"):
            d = DATASETS_ROOT / kind / split
            d.mkdir(parents=True, exist_ok=True)
            gitkeep = d / ".gitkeep"
            if not gitkeep.exists():
                gitkeep.write_text("", encoding="utf-8")
            # Per-class subfolder hint for classification-style sources
            if kind == "images":
                for label in HF_LABELS:
                    sub = d / label.lower().replace(" ", "_")
                    sub.mkdir(exist_ok=True)
                    placeholder = sub / "README.txt"
                    if not placeholder.exists():
                        placeholder.write_text(
                            f"Place '{label}' images here.\n"
                            f"YOLO labels go in labels/{split}/<same_stem>.txt\n",
                            encoding="utf-8",
                        )
    print(f"[scaffold] Created {DATASETS_ROOT}/{{images,labels}}/{{train,val,test}}")
    print(f"  + per-class image folders (41 classes x 3 splits)")


def stage_existing_images() -> int:
    """
    If the user has dropped images into datasets/nigerian-foods/images/*,
    copy/link them into a flat train/val split (80/20) for YOLO.
    Returns number of images staged.
    """
    # Look for any images already placed by the user
    exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    candidates: List[Path] = []
    for p in DATASETS_ROOT.rglob("*"):
        if p.is_file() and p.suffix.lower() in exts and ".gitkeep" not in p.name:
            # Skip already-split flat files? We treat nested class folders as source
            candidates.append(p)
    if not candidates:
        print("[stage] No images found under datasets/ — nothing to stage.")
        print("  Drop images into datasets/nigerian-foods/images/{class}/ and re-run with --download")
        return 0

    # Deduplicate by filename stem already counted? Use unique paths
    # Simple 80/20 split
    random.seed(42)
    random.shuffle(candidates)
    n = len(candidates)
    n_train = int(n * 0.8)
    train_files = candidates[:n_train]
    val_files = candidates[n_train:]
    print(f"[stage] Found {n} images -> train={len(train_files)} val={len(val_files)}")
    # For now just report; actual copy is done by --yolo-dry-run or user tooling
    return n


def emit_dummy_labels(dry_run: bool = False) -> int:
    """
    Emit dummy YOLO labels (single centred box) for every image found.
    This lets `yolo detect train` smoke-test without real annotations.
    Real bboxes MUST replace these before any evaluation.
    """
    if not dry_run:
        return 0
    exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    count = 0
    for img in DATASETS_ROOT.rglob("images/**/*"):
        if img.is_file() and img.suffix.lower() in exts:
            # Map class from parent folder name
            parent_class = img.parent.name.lower().replace("_", " ")
            # Find class id
            try:
                class_id = next(i for i, lbl in enumerate(HF_LABELS) if lbl.lower() == parent_class)
            except StopIteration:
                class_id = 0  # fallback
            # Label path mirrors images -> labels
            rel = img.relative_to(DATASETS_ROOT / "images")
            label_path = DATASETS_ROOT / "labels" / rel.with_suffix(".txt")
            label_path.parent.mkdir(parents=True, exist_ok=True)
            # Dummy: one box covering 80% of image centred
            label_path.write_text(f"{class_id} 0.5 0.5 0.8 0.8\n", encoding="utf-8")
            count += 1
    if count:
        print(f"[dry-run] Wrote {count} dummy YOLO labels (REPLACE with real bboxes!)")
    else:
        print("[dry-run] No images to label — add images first")
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description="Prepare Nigerian Foods YOLO dataset")
    parser.add_argument("--check", action="store_true", help="validation only, no writes")
    parser.add_argument("--download", action="store_true", help="stage any existing images")
    parser.add_argument("--yolo-dry-run", action="store_true", help="emit dummy centred labels")
    parser.add_argument("--clean", action="store_true", help="remove datasets/ and re-scaffold")
    args = parser.parse_args()

    print("=" * 60)
    print("Nigerian Foods — YOLO Dataset Prep")
    print("=" * 60)

    if args.clean and DATASETS_ROOT.exists():
        shutil.rmtree(DATASETS_ROOT)
        print(f"[clean] Removed {DATASETS_ROOT}")

    ok = validate()
    if args.check:
        sys.exit(0 if ok else 1)

    scaffold_structure()

    if args.download:
        stage_existing_images()

    if args.yolo_dry_run:
        emit_dummy_labels(dry_run=True)

    print("\n[done] Scaffold ready. Next steps:")
    print("  1. Add bbox-annotated images (see README.md).")
    print("  2. Run: python prepare_dataset.py --yolo-dry-run  (smoke test)")
    print("  3. Train: yolo detect train data=dataset.yaml model=yolov8n.pt epochs=30")
    if not ok:
        print("\n[warn] Validation had failures — fix before training!")


if __name__ == "__main__":
    main()
