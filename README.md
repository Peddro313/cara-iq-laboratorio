# Cara IQ Laboratório

**Original facial analysis app** with landmark detection, multi-pillar scoring, and progress tracking.

Built with **Flutter** — runs on **Android**, **iOS**, and **Web**.

> This is an original product. It does **not** copy Face IQ Labs or any other commercial service. Scoring formulas, UI, and logic are custom.

## Features (v1 roadmap)

- Front + side photo upload with guided capture tips
- Automatic 478-point facial landmark detection (MediaPipe Face Mesh)
- Original scoring across 4 pillars + overall score (0–10):
  - **Harmony** – proportions & balance
  - **Structure** – jaw, cheekbones, angularity
  - **Dimorphism** – gender-typical traits
  - **Features** – surface quality indicators where possible
- Strengths & improvement areas
- Progress tracking: history, charts, side-by-side comparison
- User accounts + secure photo storage (Supabase)
- Clean English UI

## Tech Stack

| Layer            | Technology                          |
|------------------|-------------------------------------|
| Framework        | Flutter 3.x (Dart)                  |
| Landmarks        | MediaPipe Face Mesh                 |
| Backend          | Supabase (Auth, DB, Storage)        |
| Charts           | fl_chart                            |
| State management | Riverpod                            |
| Platforms        | Android, iOS, Web                   |

## Getting Started

### Prerequisites
- Flutter SDK 3.22+
- Android Studio / Xcode (for mobile)
- Chrome (for web)

### Run locally

```bash
git clone https://github.com/Peddro313/cara-iq-laboratorio.git
cd cara-iq-laboratorio
flutter pub get
flutter run          # mobile
flutter run -d chrome # web
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/          # Analysis, Score, Landmark, User
├── services/        # Landmark detection, Scoring engine, Supabase
├── screens/         # Home, Upload, Result, History, Profile
├── widgets/         # Score cards, charts, photo guides
├── utils/           # Math helpers, constants
└── theme/           # Colors, typography
```

## Status

🚧 Early development — core scaffolding in progress.

## License

Private / proprietary for now. All rights reserved.
