# Kraiiv MVP

A warm, supportive mobile nutrition habit companion app for Nigerians.

## Features

- **Onboarding Flow**: 3-step personalized onboarding (Hook → Goals → Commitment)
- **Home Dashboard**: Streak progress, KTC balance, daily tips from Klia
- **Meal Logging**: Camera capture or text input with quick suggestions
- **AI Feedback**: Health scores (1-10) for 30+ Nigerian foods with personalized tips
- **History**: Persistent meal log with relative timestamps
- **Rewards (KTC)**: Token system with earning rules and redemption options
- **Celebration**: Confetti animation on 7-day goal completion
- **Profile**: Stats, goal badges, daily reminders

## Tech Stack

- **Framework**: Flutter 3.2+
- **State Management**: Riverpod
- **Local Storage**: Hive (offline-first)
- **Routing**: GoRouter
- **Notifications**: flutter_local_notifications (mobile only)

## How to Run

```bash
cd "C:/Users/HP/Kraiiv MVP"
flutter pub get
flutter run
```

For web:
```bash
flutter run -d chrome
```

## Build for Web

```bash
flutter build web --release
```

## Deployment

Configured for Vercel deployment:
- Build command: `flutter build web --release`
- Output directory: `build/web`

## Project Structure

```
lib/
├── core/
│   ├── router/           # GoRouter configuration
│   ├── services/         # Data persistence, notifications
│   └── theme/            # Brand theming
├── data/
│   └── repository/       # 30 Nigerian foods database
├── features/
│   ├── celebration/      # 7-day goal completion
│   ├── history/          # Meal history (persisted)
│   ├── home/             # Main dashboard with streaks
│   ├── layout/           # App shell, bottom nav
│   ├── logging/          # Food logging + AI feedback
│   ├── onboarding/       # 3-step onboarding flow
│   ├── profile/          # User profile + settings
│   ├── rewards/          # KTC token system
│   └── splash/           # Animated splash screen
└── main.dart
```

## Next Steps (Post-MVP)

- [ ] Firebase Auth integration
- [ ] Camera AI vision (food recognition)
- [ ] Cloud sync (meals, streaks, tokens)
- [ ] KTC redemption (airtime, data, groceries)
- [ ] Community features (leaderboards)
