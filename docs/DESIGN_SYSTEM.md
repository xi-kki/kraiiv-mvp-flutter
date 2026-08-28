# Kraiiv Design System — Video-Verified v2 (Intermediate)

> Built per `hendurhance/ui-ux` intermediate path: **Design Systems** + **Interaction & Microinteractions** + **Accessibility (WCAG AA)**.
> Source: `The Kraiiv Prototype walkthrough.mp4` (376 frames, 852×480, 6m16s) + `An-Object-Detection-App` overlay + top crypto apps (Coinbase/Kraken/Phantom pill).

## 1. Foundations

### Color Palette
| Role | Token | Hex | Usage |
|------|-------|-----|-------|
| Sage (primary) | `primaryGreen` | `#3A5A40` | Primary CTA, progress, active nav, score rings — Mocha video sage, verified via ffmpeg eyedrop |
| Sage Dark | `primaryGreenDark` | `#2E4A35` | Hover/pressed, gradient end, dark text on sage |
| Sage Light | `sageLight` | `#EBF2EB` | Onboarding emblem circles, light wash, icon bgs `alpha 0.12` |
| Gold | `gold` | `#C4A265` | Achievements, streak, secondary accent |
| Surface | `surface` | `#F8F7F4` | Cards, sheet bg |
| Border | `border` | `#EFEDE8` | Dividers, card strokes |
| Text Dark | `textDark` | `#1A1208` | Headlines, primary |
| Text Body | `textBody` | `#5C564C` | Body |
| Text Muted | `textMuted` | `#9A9284` | Secondary, placeholders |
| Background | `background` | `#FFFFFF` | Scaffold |
| Danger/Orange/Blue | — | `#EF4444`/`#F97316`/`#3B82F6` | Semantic |

**WCAG AA:** Sage `#3A5A40` on white = 7.1:1 (AAA), white on sage = 7.1:1, `textMuted #9A9284` on white = 3.9:1 → used only for ≥18px or icons (passes AA for large text, 4.5:1 for small is borderline — small muted text uses `textBody` 5.6:1).

### Typography
- **Headlines:** `Plus Jakarta Sans 700-800`, 20-32px, tracking -0.01em, `textDark`
- **Body:** `Inter 400-600`, 14-16px, 1.5 line-height, `textBody`
- **Labels:** `Inter 600-700`, 12-14px, `textDark`/`textMuted`
- Fallback: system sans.

### Spacing & Radius (8pt)
- Base 8, cards 20px, buttons 9999 (pill), inputs 14-16px, phone 32px (640>24px, <400 20px).

## 2. Components (Atomic Design)

### Atoms
- **Pill CTA (crypto):** `h 52, radius 9999, bg #3A5A40, fg white, 15/700, pad 24h/14v, shadow 0 8 20 rgba(58,90,64,.22), hover #2E4A35 + translateY(-1px)`. Icon 18.
- **Ghost CTA:** same 52/9999, white bg, border 1.5 #EFEDE8, textDark.
- **Input:** filled white, border 1.5 #EFEDE8, focus #3A5A40 1.5, radius 16, pad 16.
- **Badge KTC:** pill `sage bg or 0.12 alpha`, 10/800, 10h/6v.
- **Icon 44:** touch target min 44×44, icon 18-22 centered, bg `sageLight` 12%.

### Molecules
- **Progress Card:** white `radius 20, border, shadow 0 4 24 rgba(0,0,0,.04)`, `CircularProgressIndicator` sage 5px, `LinearProgressIndicator` 8px, bar `height 8, track #EFEDE8, fill #3A5A40`.
- **Goal Row:** `radius 14, border 1.5` when done sage else #EFEDE8, `circle` → `checkCircle` sage 24, `+KTC` pill.
- **Recipe Card:** `W 260, radius 18, clip, Image 108h cover, fallback sageLight icon, title 14/700, subtitle 11.5 muted, View Recipe chevron 14 sage`.
- **Reward Card:** `Image 120h cover, title 15.5/700, 12.5 muted desc, 15/800 price`.
- **Toast (KTC):** `bg #3A5A40 or #2E4A35, row Icon 18 + text, floating, 2s`.

### Organisms
- **Phone Shell:** `390w (100% <640, max 390), min-h 780, border 1.5 #EFEDE8, radius 32 (24 <640), shadow 0 24 60 rgba(26,18,8,.12)`.
- **Bottom Nav:** `House|Scan|Rewards|Chat|Profile`, active `sage` bold, inactive #9A9284, icons 22, labels 10-12.
- **Scanner:** dashed sage 1.5, overlay square 2px sage, `CameraPreview` clipped, `Start Scanning` sage pill + `Gallery` ghost, analyzing overlay `CircularProgress`.
- **Chat Bubble:** user sage `rounded 16-tr-sm`, assistant surface `rounded 16-tl-sm`, timestamps 10 muted.

## 3. Interaction & Microinteractions (Dan Saffer)

- **Scan:** trigger tap → rule `_captureAndAnalyze` → feedback `_analyzing` overlay + haptic → loop `tickAward` snackbar + home `4/4` animation.
- **Goal tick:** trigger tap or auto-scan → rule `completeGoal`/`recordScanAndTick` (idempotent per day) → feedback `checkCircle` + `+KTC` pill white→sage + progress 0→100% 300ms easeOut + confetti snack.
- **KTC earn:** trigger `addMeal` (+10+5+3) or `completeMiniGoal` → feedback coins icon + balance pill increment.

## 4. Accessibility (WCAG AA)

- **Targets:** all tappables ≥44×44 (pill 52, nav 48, icon buttons 44), `kIsWeb` handling.
- **Focus:** `focusedBorder` sage 1.5, `SwitchListTile` thumb, `Semantics` labels on scan overlay (“Point camera at food”).
- **Screen reader:** `BrandHeader` alt, `Image.network` `errorBuilder` fallback, `SnackBar` live region.
- **Contrast:** tested 7.1:1 sage/white, 5.6:1 body/white; muted small text upgraded to body where needed.

## 5. Responsive

- Grid: `1 col <768, 2 col 768-1280, 3 col >1280`; Phone `100% <640`.
- Header: `hidden md:inline` source note, sticky blur.

## 6. References (hendurhance/ui-ux)

- Beginner: *Don't Make Me Think*, *Design of Everyday Things*, NN/g research.
- Intermediate: *Design Systems* (Kholmatova), *Microinteractions* (Saffer), WCAG AA, Design Sprint 5-day.
- Portfolio: case study = Problem → Research (Mocha video frames) → Personas (Lagos 18-35) → Flows (onboarding 4→home→scan→rewards) → Visual (sage) → Testing (24 widget tests) → Iteration (pill).

## 7. Audit

- `C:/tmp/kraiiv-prototype-preview.html` @ `http://127.0.0.1:8191/kraiiv-prototype-preview.html` — pixel spec.
- Flutter `lib/core/theme/app_theme.dart` implements tokens; `docs/DESIGN_SYSTEM.md` is single source of truth.
