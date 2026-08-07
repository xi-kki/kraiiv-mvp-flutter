# Kraiiv MVP

A warm, supportive mobile nutrition habit companion app for Nigerians —
rebuilt to match the video prototype walkthrough. Light theme, chat
onboarding with Klia, daily goals with KTC rewards, AI food scanning,
and a stats-rich profile. All icons from [lucide.dev](https://lucide.dev)
(via `lucide_flutter`) — no emojis.

## Features

- **Chat Onboarding**: 5 steps with Klia — name, dietary preference,
  health goal, location, daily check-in
- **Home Dashboard**: greeting, Your Progress card, Today's Goals
  (+15/+20/+10/+25 KTC), Local & Seasonal recipe ideas
- **Food Scanner**: real AI detection of 41 Nigerian foods
  (Nigerian Food Lens model), calories/protein/health insight,
  offline keyword fallback
- **Rewards Hub**: KTC balance, Connect Wallet, redeemable rewards
  (instant `KRV-XXXX-XXXX` voucher codes), redemption + earning history
- **Klia Chat**: nutrition coach with keyword answers
- **My Profile**: weekly progress chart, habit categories, achievements,
  editable profile

## Tech Stack

- **Framework**: Flutter 3.2+ · **Icons**: lucide_flutter (lucide.dev)
- **State**: Riverpod · **Storage**: Hive (offline-first)
- **Routing**: GoRouter · **Notifications**: flutter_local_notifications
- **AI detection**: FastAPI `model-api/` → EfficientNetV2-S Nigerian
  Food Lens (41 classes), COCO SSD MobileNet fallback

## Run

```bash
flutter pub get
flutter run -d chrome
```

## AI Food Recognition

```bash
cd model-api
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

The scanner calls `POST /detect` (base URL overridable via
`--dart-define=KRAIIV_API_URL=...`); when the API is unreachable it
falls back to the local 46-food keyword matcher. Release builds only
call the API when `KRAIIV_API_URL` was explicitly configured at build
time — otherwise no photo ever leaves the device.

The model weights are pinned to an exact Hugging Face revision and
sha256, loaded with `torch.load(weights_only=True)` (numpy data types
allowlisted) so a compromised model repo cannot execute code on the
API host. The API rate-limits `/detect` (10/min per IP), rejects
decompression-bomb images by declared pixel count, and validates
uploads by magic bytes, not client headers.

Training data + Neo task for expanding the model: `C:/Users/HP/kraiiv-ai/`.

## Build for Web

```bash
flutter build web --release
# serve build/web with any static server (e.g. python -m http.server 8090)
```

Deployable to Vercel (see `vercel.json`). The app is live at
`https://kraiiv-mvp-two.vercel.app` (the marketing landing stays at
`https://kraiiv.vercel.app`).

## Verification

- `flutter analyze` — clean
- `flutter test` — splash smoke test + redemption unit tests
  (deduction, voucher format, insufficient balance, ordering)
- CI (`.github/workflows/ci.yml`) runs analyze + tests + gitleaks on
  every push and pull request