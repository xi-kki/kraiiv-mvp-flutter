# Kraiiv MVP

A warm, supportive mobile nutrition habit companion app for Nigerians.
Rebuilt to match the video prototype ("The Kraiiv Prototype walkthrough.mp4"):
light theme, chat onboarding with Klia, daily goals, food scanner with
real AI detection, KTC rewards, Klia chat, and a stats-rich profile.

No emojis anywhere in the UI — all icons come from lucide.dev via the
`lucide_flutter` package.

## Project Structure

```
lib/
├── core/
│   ├── router/           # GoRouter configuration
│   ├── services/         # Data persistence, notifications, food AI client
│   │   ├── data_service.dart               # Hive-based state
│   │   ├── notification_service.dart       # 3 daily reminders
│   │   └── food_recognition_service.dart   # Calls model-api /detect
│   ├── theme/            # Brand theming (light, video-accurate)
│   └── widgets/
│       └── brand_header.dart   # "Kraiiv — Be intentional with every bite"
├── data/
│   └── repository/
│       ├── food_repository.dart   # 46 foods: matching + nutrition
│       └── recipe_repository.dart # Local & Seasonal recipe ideas
├── features/
│   ├── splash/          # Logo + tagline, routes to onboarding/home
│   ├── onboarding/      # 5-step chat flow (name → diet → goal → city → nudges)
│   ├── home/            # Greeting, Your Progress, Today's Goals, Local Ideas
│   ├── logging/         # Food Scanner + scan result
│   ├── rewards/         # Rewards Hub (KTC balance, redemption)
│   ├── chat/            # Klia chat (keyword nutrition answers)
│   ├── profile/         # Weekly progress, habit categories, achievements
│   ├── progress/        # "View Details" from the home progress card
│   └── recipes/         # Recipe detail from Local & Seasonal cards
├── main.dart            # Entry point
└── app.dart
```

## Tech Stack

- **Framework**: Flutter 3.2+ (built with 3.47)
- **Icons**: lucide_flutter (lucide.dev) — never Material emoji
- **State Management**: Riverpod (setup ready)
- **Local Storage**: Hive (all data persisted offline-first)
- **Notifications**: flutter_local_notifications (3 daily reminders)
- **Camera**: image_picker (real camera + analyzing state)
- **Routing**: GoRouter with splash-aware navigation
- **AI food detection**: model-api/ FastAPI service → Nigerian Food Lens
  model (EfficientNetV2-S, 41 Nigerian foods), COCO SSD MobileNet fallback

## Features (video-prototype match)

### Onboarding — 5 steps, chat with Klia
1. Name → 2. Dietary preference (Vegetarian/Vegan/Gluten-free/No restrictions)
3. Health goal (Feel more energized / Eat more mindfully / Improve overall /
   Try more local foods) → 4. Location (city chips) → 5. Daily check-in
   (Allow / Maybe Later). Step indicator + Next button per screen.

### Home Dashboard
- Time-of-day greeting + "Let's make today's intentional"
- **Your Progress** card: today ring (goals done), weekly mini bars,
  "View Details" → full progress screen
- **Today's Goals** (4, matching the video):
  - Log a local and seasonal meal → +15 KTC
  - Try a new vegetable from the farmer's market → +20 KTC
  - Eat mindfully without distractions for one meal → +10 KTC
  - Scan 3 food items to check nutrition facts → +25 KTC
  Tap to complete; KTC awarded instantly.
- **Local & Seasonal Ideas**: carousel (Seasonal Vegetable Harmony Bowl,
  Farmers Market Frittata, Local Berry Breakfast Smoothie) with View Recipe

### Food Scanner (real AI)
- "Scan your food to get nutritional information and know if it's local
  and seasonal." → camera → "Analyzing your meal..." →
  **Nigerian Food Lens** detection via `model-api` → result screen
  (photo, name, calories/protein/health, Klia insight, Log Meal).
- Offline fallback: local keyword matcher (46-food database).

### Rewards Hub
- KTC balance card + Connect Wallet, Available Rewards
  (Spa Treatment Voucher, Gourmet Dessert Box, Local Market Voucher,
  Convert KTC to Cash), earning history.

### Klia Chat
- "Ask Klia about nutrition..." with keyword answers
  (protein, calories, fibre, hydration, local foods, mindful eating, KTC).

### My Profile
- Health Goal / Preferred / Location rows (editable via FilePen),
  Weekly Progress chart with completion rate, Habit Categories bars
  (Food / Mindful / Local / Streak), Achievements grid, daily nudges toggle.

## AI Food Recognition

Two parts, both in this repo:

1. **`model-api/`** — FastAPI service. `POST /detect` runs the
   Nigerian Food Lens model (downloaded from Hugging Face on first use);
   falls back to the COCO SSD MobileNet pipeline from
   xi-kki/An-Object-Detection-App. Responses are enriched with
   healthScore/calories/protein from `nigerian_foods.json`.
   ```bash
   cd model-api && pip install -r requirements.txt
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```
2. **`lib/core/services/food_recognition_service.dart`** — Flutter client.
   Base URL overridable at build time:
   ```bash
   flutter build web --dart-define=KRAIIV_API_URL=http://localhost:8000
   ```
   Unreachable API → automatic local keyword-matcher fallback (app still
   fully functional offline).

Training expansion (CHOWNET + Kaggle datasets, Neo task) lives in
`C:/Users/HP/kraiiv-ai/` — see `README.md` and `neo_training_task.md` there.

## How to Run

```bash
cd "C:/Users/HP/Kraiiv-MVP-Flutter"
flutter pub get
flutter run                # or: flutter run -d chrome
flutter build web --release
```

## Verification

- `flutter analyze` — clean
- `flutter test` — smoke test (splash brand renders, routes away)
- Web: `python -m http.server 8090` in `build/web`, then browse
  `http://localhost:8090`

## Next Steps (Post-MVP)

- [ ] Neo-trained expanded model (60–80 African foods) into model-api
- [ ] Firebase Auth integration (replace profile editing)
- [ ] Cloud sync (meals, streaks, tokens)
- [ ] KTC redemption (airtime, data, groceries)
- [ ] Camera AI vision improvements (bounding boxes, multi-food plates)
