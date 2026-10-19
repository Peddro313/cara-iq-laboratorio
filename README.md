# Cara IQ Laboratório

**Original facial analysis app** with landmark detection, multi-pillar scoring, and progress tracking.

Built with **Flutter** — runs on **Android**, **iOS**, and **Web**.

> This is an original product. It does **not** copy Face IQ Labs or any other commercial service. Scoring formulas, UI, and logic are custom.

## Current Status (v0.2)

### Working now
- Full app navigation (Home → Upload → Result → History)
- Front + side photo picker
- Original 4-pillar scoring engine (Harmony, Structure, Dimorphism, Features)
- Real facial ratio calculations from MediaPipe landmark indices
- Local progress tracking (analyses saved on device)
- History screen with score-over-time chart
- Light / dark theme
- Riverpod state management

### Next up
- Real MediaPipe Face Mesh integration (replace demo landmarks)
- Supabase auth + cloud sync
- Better photo guidance overlays
- Side-profile specific angles
- Polish & animations

## Features (v1 roadmap)

- Front + side photo upload with guided capture tips
- Automatic 478-point facial landmark detection (MediaPipe Face Mesh)
- Original scoring across 4 pillars + overall score (0–10)
- Strengths & improvement areas
- Progress tracking: history, charts, side-by-side comparison
- User accounts + secure photo storage (Supabase)
- Clean English UI

## Tech Stack

| Layer            | Technology                          |
|------------------|-------------------------------------|
| Framework        | Flutter 3.x (Dart)                  |
| Landmarks        | MediaPipe Face Mesh (prepared)      |
| Backend          | Supabase (stub ready)               |
| Charts           | fl_chart                            |
| State management | Riverpod                            |
| Local storage    | shared_preferences                  |
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
flutter run                # mobile
flutter run -d chrome      # web
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/
│   └── analysis.dart
├── services/
│   ├── landmark_service.dart      # MediaPipe indices + ratio math
│   ├── scoring_engine.dart        # 4-pillar scoring
│   ├── analysis_repository.dart   # Local storage
│   └── supabase_service.dart      # Cloud ready
├── providers/
│   └── analysis_providers.dart
├── screens/
│   ├── home_screen.dart
│   ├── upload_screen.dart
│   ├── result_screen.dart
│   └── history_screen.dart
└── theme/
    └── app_theme.dart
```

## License

Private / proprietary for now. All rights reserved.
