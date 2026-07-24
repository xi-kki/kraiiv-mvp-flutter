# Kraiiv MVP

A warm, supportive mobile nutrition habit companion app for Nigerians.

## Project Structure

```
lib/
├── core/
│   ├── router/           # GoRouter configuration
│   │   └── app_router.dart
│   ├── services/         # Data persistence, notifications
│   │   ├── data_service.dart      # Hive-based state management
│   │   └── notification_service.dart
│   └── theme/            # Brand theming
│       └── app_theme.dart
├── data/
│   └── repository/
│       └── food_repository.dart   # 30 Nigerian foods database
├── features/
│   ├── celebration/      # 7-day goal completion
│   │   └── screens/celebration_screen.dart
│   ├── history/          # Meal history (persisted)
│   │   └── screens/history_screen.dart
│   ├── home/             # Main dashboard with streaks
│   │   └── screens/home_screen.dart
│   ├── layout/           # App shell, bottom nav
│   │   └── screens/main_layout.dart
│   ├── logging/          # Food logging + AI feedback
│   │   └── screens/
│   │       ├── meal_logging_screen.dart
│   │       └── feedback_screen.dart
│   ├── onboarding/       # 3-step onboarding flow
│   │   └── screens/
│   │       ├── hook_screen.dart
│   │       ├── goal_screen.dart
│   │       └── commitment_screen.dart
│   ├── profile/          # User profile + settings
│   │   └── screens/profile_screen.dart
│   ├── rewards/          # KTC token system
│   │   └── screens/rewards_screen.dart
│   └── splash/           # Animated splash screen
│       └── screens/splash_screen.dart
├── main.dart             # Entry point
└── app.dart
```

## Tech Stack

- **Framework**: Flutter 3.2+
- **State Management**: Riverpod (setup ready)
- **Local Storage**: Hive (all data persisted offline-first)
- **Auth**: Firebase Auth + Google Sign-in (banner ready)
- **Notifications**: flutter_local_notifications (3 daily reminders)
- **Camera**: image_picker (real camera + quick options)
- **Routing**: GoRouter with splash-aware navigation

## Features (100% MVP)

### ✅ Onboarding (3 screens)
- Hook screen with animated CTA
- Goal selection (multi-select, persisted)
- Commitment prompt with completion tracking

### ✅ Home Dashboard
- Greeting based on time of day
- Circular streak progress (day 1-7)
- Log meal CTA with pulse animation (stops when logged)
- KTC balance badge (tap to view rewards)
- Stats row (streak, meals, tokens)
- Weekly streak progress bar
- Klia daily tip (rotates)

### ✅ Meal Logging
- Camera capture (real image_picker)
- Quick-select bottom sheet after photo
- Text input with suggestions
- "Analyzing..." loading state

### ✅ AI Feedback
- Matches 30 Nigerian foods from JSON
- Health score (1-10) with emoji
- Warm, specific feedback from Klia
- KTC earning notification
- Auto-saves to Hive
- 7-day goal completion detection → celebration screen

### ✅ History
- Real persisted meal log (from Hive)
- Relative timestamps (just now, 2h ago, Yesterday, Jan 5)
- Category emojis and colors
- Empty state with CTA

### ✅ Profile
- Real stats (streak, best streak, meals, tokens)
- Goal badges from onboarding
- Daily reminders toggle (functional)
- Rate Kraiiv + About placeholders
- Google sign-in banner

### ✅ Rewards (KTC Token System)
- Balance card with gradient
- Earning rules (+10 base, +5 healthy, +3 streak)
- Redeem options (Coming soon cards)
- Earning history log

### ✅ Celebration Screen
- Confetti animation
- Trophy + stats
- Motivational quote
- "Keep going" CTA

### ✅ Splash Screen
- Animated logo fade-in + scale
- Auto-navigates based on onboarding state

## Data Architecture

### Hive Boxes
| Box | Contents |
|-----|----------|
| `settings` | onboarding_complete, selected_goals, commitment_accepted, daily_reminders |
| `meals` | List of {name, category, healthScore, feedback, timestamp} |
| `streaks` | current streak, best streak, current day, last_log_date |
| `tokens` | KTC balance, earning history |

### Food Database
- 30 Nigerian foods across 4 categories
- Keywords for matching (handles partial matches)
- Health scores from 3-10
- Warm, specific feedback templates with Klia's voice

## How to Run

```bash
cd "C:/Users/HP/Kraiiv MVP"
flutter pub get
flutter run
```

## Next Steps (Post-MVP)
- [ ] Firebase Auth integration (replace banner)
- [ ] Camera AI vision (food recognition from photo)
- [ ] Cloud sync (meals, streaks, tokens)
- [ ] KTC redemption (airtime, data, groceries)
- [ ] Community features (leaderboards)
- [ ] Family plans
- [ ] Export health data
