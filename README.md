# AutoClip 🎬

> **Turn one video into multiple ready-to-use clips.**

AutoClip is a focused, high-performance Android mobile application built with Flutter that automates short-form video creation for TikTok, YouTube Shorts, and Instagram Reels. 

It is designed with **zero bloat**: no timeline editors, no account logins, no cloud dashboards, and no complex menus.

---

## 🎯 The Core Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  ADD VIDEO   │ ──> │ CHOOSE DURATION│ ──> │ SELECT STYLES│ ──> │ CREATE CLIPS │
│  from phone  │     │ 20s / 25s / 30s│     │ Clean/Gaming │     │ (Real FFmpeg)│
└──────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                      │
┌──────────────┐     ┌──────────────┐                                 │
│ PHONE GALLERY│ <── │ RESULTS GRID │ <───────────────────────────────┘
│AutoClip Album│     │Tap to preview│
└──────────────┘     └──────────────┘
```

---

## 📱 Features & Specifications

### 1. Main Screen
- **Header**: "AutoClip" & "Turn one video into multiple ready-to-use clips."
- **Video Input**: Large `+ ADD VIDEO` target. Displays thumbnail, file name, duration, and file size once loaded.
- **Clip Length Selector**:
  - `[ 20 SEC ]`, `[ 25 SEC ]`, `[ 30 SEC ]`
  - Default: `25 SEC`
  - Enforces strict 30-second maximum duration.
  - Automatically divides the video using natural cut points.
- **Editing Styles**:
  - Multi-select ready-made style cards with checkboxes and glow indicators.
  - Predefined editing presets:
    - **Clean**: 9:16 vertical output, clean crop, subtle zoom (`1.05x`), clean captions, subtle visual tuning (`eq=contrast=1.05:saturation=1.08`).
    - **Fast**: 9:16 vertical output, faster visual pacing (`1.04x`), dynamic crop, moderate zoom (`1.12x`), high-tempo animated captions.
    - **Gaming**: 9:16 vertical output, gaming-style crop, punch zooms (`1.18x`), bold neon/yellow captions with heavy border, punchy audio.
    - **Dynamic**: 9:16 vertical output, dynamic reframing, smooth sine-wave zooms (`1.08x`), animated pop captions, smooth transitions.
    - **Minimal**: 9:16 vertical output, clean crop, minimal effects (original aesthetics untouched), simple lower-third captions.
- **Create Button**:
  - `[ CREATE CLIPS ]` at the bottom.
  - Disabled until video, duration, and at least one style are selected.
  - Displays batch total (e.g., `CREATE 12 CLIPS` for 4 cuts × 3 styles).

### 2. Automatic Processing Screen
- Real-time video processing engine using embedded **FFmpeg Kit**.
- 5 distinct processing phases:
  1. `Analyzing video...`: Probes stream metadata, runs scene-change detection (`gt(scene,0.3)`) and silence detection (`silencedetect`).
  2. `Finding clips...`: Snaps cut boundaries to natural transitions within a ±3.5s window around the target duration. Avoids black frames and dead air.
  3. `Applying styles...`: Prepares 9:16 vertical filtergraphs, zoom expressions, color grades, and `.ass` subtitles.
  4. `Rendering...`: Enforces 1080×1920 H.264 video + AAC audio encoding with live progress callbacks and current clip counter.
  5. `Saving to Gallery...`: Automatically places finished MP4s directly into the Android device MediaStore under the `AutoClip` album.
- User can safely cancel rendering at any time.

### 3. Automatic Phone Gallery Save
- Automatically categorizes and exports clips into the device's public media library:
  ```
  Phone Storage
  └── Movies
      └── AutoClip
          ├── Clean_01.mp4
          ├── Clean_02.mp4
          ├── Gaming_01.mp4
          └── Gaming_02.mp4
  ```
- Broadcasts `MediaScannerConnection` intents so clips appear immediately in Google Photos, Samsung Gallery, Xiaomi Gallery, etc.

### 4. Results Screen
- "Done!" banner with total clips created count (e.g. `24 clips created`).
- 2-column portrait thumbnail grid with play overlay, style badges, and duration tags.
- Built-in video player modal on tap.
- **OPEN GALLERY** button (launches Android Gallery intent).
- **CREATE MORE** button (resets state for the next video).

### 5. Settings Screen
- **Output Quality**: High (1080×1920) / Standard (720×1280) / Fast (540×960).
- **Save Location**: AutoClip album info.
- **Auto Gallery Save**: Toggle (default: ON).
- **Captions**: Toggle (default: ON).

---

## 🏗️ Project Architecture

```
autoclip/
├── android/                         # Android native project files
│   ├── app/
│   │   ├── build.gradle             # MinSDK 24, TargetSDK 34, ABI filters
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Media & storage permissions
│   │       └── kotlin/com/autoclip/app/
│   │           └── MainActivity.kt  # MediaScanner & Gallery Intent channel
│   └── build.gradle
├── assets/
│   └── icons/
├── lib/
│   ├── main.dart                    # App entry point, orientation lock, theme
│   ├── models/
│   │   ├── app_settings.dart        # Quality, captions & save settings
│   │   ├── clip_segment.dart        # Segment state, timing, file naming
│   │   └── editing_style.dart       # 5 ready-made style configurations
│   ├── providers/
│   │   └── autoclip_provider.dart   # Main state machine & pipeline coordinator
│   ├── screens/
│   │   ├── main_screen.dart         # Simple one-page main interface
│   │   ├── processing_screen.dart   # Live progress, phases, cancellation
│   │   ├── results_screen.dart      # Results thumbnail grid & gallery opener
│   │   └── settings_screen.dart     # Quality and automation settings
│   ├── services/
│   │   ├── caption_service.dart     # Style-specific ASS subtitle generator
│   │   ├── ffmpeg_service.dart      # 9:16 crop, zoompan, eq & encoder
│   │   ├── gallery_service.dart     # MediaStore & Gal album integration
│   │   └── video_analyzer_service.dart # Scene change & silence cut detector
│   ├── theme/
│   │   └── app_theme.dart           # Clean modern dark theme
│   └── widgets/
│       ├── clip_length_selector.dart# 20s / 25s / 30s toggle pills
│       ├── style_card.dart          # Multi-select cards with checkboxes
│       ├── video_player_modal.dart  # Modal video player
│       └── video_preview_card.dart  # Video picker & info banner
└── test/
    ├── autoclip_provider_test.dart  # State validation & button disabled tests
    ├── editing_style_test.dart      # Preset configurations & filenames
    ├── settings_test.dart           # Dimensions & quality settings
    └── video_analyzer_test.dart     # Natural cut snapping & 30s max rules
```

---

## 🚀 Building & Running

### Requirements
- Flutter SDK 3.0+
- Android SDK (API 34, Build Tools 34.0.0, MinSDK 24)
- Java 17 / JDK 17

### Commands
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run unit tests
flutter test

# 3. Build Android APK
flutter build apk --release

# 4. Run on connected Android device
flutter run
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
