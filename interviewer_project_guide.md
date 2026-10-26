# 🎬 Project Interview Guide: Velo Player (AI-Powered Media Hub)

> **Quick Reference Guide for Technical Interviews, Portfolio Reviews, and Project Presentations.**

---

## 1. 📌 Project Name
* **Name:** **Velo Player** (Cross-Platform AI-Powered Media Player & Video Hub)
* **Tagline:** A high-performance, dark-themed video player and media manager featuring offline AI speech transcription, real-time subtitle translation, AI chaptering, YouTube direct-stream playback, and desktop/mobile support.

---

## 2. 💡 What You Built (Overview & Purpose)
**Velo Player** is an advanced, production-grade media player application built with Flutter that elevates the video playback experience across Desktop (Windows) and Mobile. 

### Core Purpose & Value Proposition:
* **All-in-One Playback Hub:** Plays local video files (MP4, MKV, WebM, etc.) and streams direct online URLs & YouTube videos with quality selection (360p to 1080p).
* **AI-Powered Accessibility & Productivity:** Features an offline-first AI transcription and subtitle translation engine, paired with automatic chapter extraction and video summaries.
* **Modern Media Management:** Delivers automated file system scanning, smart folder organization, persistent watch history with resume points, custom playlists, and instant keyword subtitle search.
* **Sleek, Distraction-Free UI:** Designed with a custom cyber-cinema glassmorphic dark theme, custom gesture controls (brightness, volume, 2x press-and-hold, pinch-to-zoom), and desktop keyboard shortcuts.

---

## 3. 👤 Your Role & Contributions
**Role:** **Lead Flutter & Full-Stack Mobile/Desktop Engineer**

### What Exactly You Worked On:
* **Architecture & State Management:** Designed a modular Clean Architecture structure (`core` vs `features/domain/data/presentation`) powered by **Riverpod** for reactive state handling.
* **Database & Persistence Engine:** Implemented a robust SQLite database schema using `sqflite` / `sqflite_common_ffi` with versioned migrations (`v1 -> v2 -> v3`), foreign keys with cascading deletes, and batch indexing.
* **Custom Video Controller & Desktop Support:** Built the unified `PlayerController` integrating Flutter's `video_player` with `video_player_win` for hardware-accelerated Windows desktop playback and `window_manager` desktop lifecycle integration.
* **AI Subtitle & Summarization Engine:** Architected the abstract `AiSubtitleProvider` contract, implemented the local offline neural transcription/translation engine across 8 languages, and developed the `AiSummaryService` for extracting timestamped chapters and bulleted takeaways.
* **YouTube Direct Streaming Pipeline:** Built the `YouTubeExtractorService` with `youtube_explode_dart` to parse video manifests, resolve muxed streams, handle quality switching, and catch network/rate-limiting errors.
* **Interactive Player UI & Gesture Engine:** Built a custom multi-touch gesture system (spatial swipe zones for brightness/volume, double-tap seek, long-press 2x speed) and overlay HUD with subtitle customization sheets.

---

## 4. 🛠️ Technologies Used

| Category | Technologies / Libraries |
| :--- | :--- |
| **Framework & Language** | Flutter, Dart (SDK `^3.11.5`) |
| **State Management** | Flutter Riverpod (`flutter_riverpod: ^2.6.1`) |
| **Video Playback** | `video_player: ^2.11.1`, `video_player_win: ^3.2.2` (DirectShow / Windows Native Foundation) |
| **Local Database & Storage** | SQLite (`sqflite: ^2.4.2+1`, `sqflite_common_ffi: ^2.4.0+3`), `shared_preferences`, `path_provider`, `path` |
| **Online Stream Extraction** | `youtube_explode_dart: ^3.1.0` (DASH & Muxed stream manifest extraction) |
| **Desktop Integration** | `window_manager: ^0.5.2` (Window sizing, title bar, frameless window control), `file_picker: ^10.3.10` |
| **Design System & UI** | Custom Dark Cinema Theme (`VeloColors`, `VeloTypography`, `VeloTheme`), `google_fonts`, `cupertino_icons` |
| **Date & Time Formatting** | `intl: ^0.20.3` |

---

## 5. ✨ Key Features & Functionality Implemented

### 🎥 1. Universal Media Playback Engine
* **Local Playback:** Seamless playback for high-definition video files with auto-aspect ratio adaptation (`16:9`, `4:3`, `Fill`, `Fit`, `Original`).
* **Online URL & YouTube Streaming:** Instant playback of direct video URLs or YouTube links/IDs with automatic resolution picker (360p, 720p, 1080p muxed streams).
* **Playback Speed Control:** Granular speed selection from `0.25x` to `2.0x` with instant audio pitch preservation.
* **Repeat & Shuffle:** Seamless loop modes (`None`, `Repeat One`, `Repeat All`) and queue playlist progression.

### 🤖 2. Offline-First AI Subtitles & Multi-Language Translation
* **Speech-to-Text Transcription:** Segmented utterance generation with high-confidence timestamps synced directly to the video timeline.
* **Automatic Language Detection:** Recognizes English, Hindi, Spanish, French, German, Japanese, Arabic, and Portuguese.
* **Real-Time Translation:** Translates dialogue tracks on the fly and stores translated cues in SQLite for instant zero-latency reloading.
* **Subtitle Dialogue Search:** Users can search across spoken subtitle lines in their library and tap any search result to jump straight to that exact timestamp.

### 🧠 3. AI Video Summaries & Interactive Chapters
* **Automated Chaptering:** Algorithmic clustering of dialogue cues into timestamped, navigable video chapters.
* **Executive Summary & Key Takeaways:** Generates high-level overviews and bulleted key points directly from the transcribed audio.
* **One-Tap Seeking:** Tapping any chapter timestamp immediately seeks the player to that key moment.

### 🎛️ 4. Advanced Gesture Controls & HUD
* **Spatial Screen Gestures:**
  * Left-side vertical drag: Adjusts display brightness smoothly.
  * Right-side vertical drag: Adjusts audio volume.
  * Left/Right double-tap: Quick 10-second seek backward / forward.
  * Long-press anywhere: 2x high-speed playback boost with haptic feedback.
* **Lock Mode:** Full interface lock to prevent accidental touches during viewing.
* **Custom Subtitle Styling:** Real-time font size scaling, color picker, background opacity slider, and presets (*Cinema*, *Outline*, *Minimal*, *High-Contrast*).
* **Desktop Shortcuts:** Keyboard bindings for Space (Play/Pause), Left/Right Arrows (Seek), Up/Down (Volume), F (Fullscreen), M (Mute), and S (Subtitles).

### 📂 5. Media Library, Playlists & Watch History
* **Automated Device Scanner:** Scans storage recursively for video files and indexes metadata (duration, resolution, file size, thumbnail).
* **Folder View & Hierarchy:** Automatically categorizes videos by directory with badge counters.
* **Watch History & "Continue Watching":** Tracks exact playback timestamps and completion percentage; suggests "Continue Watching" for unfinished videos (<95%).
* **Custom Playlists:** Create, rename, delete, and reorder custom video queues with atomic SQLite batch operations.

---

## 6. 🧠 What You Learned from the Project
1. **Desktop & Mobile Hybrid Flutter Development:** Gained deep experience configuring native platform channels, integrating desktop FFI (`sqflite_common_ffi`, `video_player_win`), and handling platform-specific window lifecycle management.
2. **High-Performance Relational Schema Design:** Engineered indexed SQLite tables with foreign keys and cascading deletes, handling thousands of subtitle segment queries and batch inserts without frame drops.
3. **Complex Touch & Gesture Disambiguation:** Mastered Flutter's gesture arena to smoothly combine multi-pointer pan, double-tap, long-press, and slider scrubbing without triggering gesture conflicts.
4. **Stream Parsing & Resilient Networking:** Implemented robust network extraction pipelines for YouTube video streaming, with automated fallbacks for muxed streams, timeouts, and friendly user error handling.
5. **Clean Architecture in Flutter:** Structured extensible domain abstractions (e.g., `AiSubtitleProvider`) allowing zero-friction swapping between local stub/Whisper models and cloud APIs.

---

## 7. ⏱️ Duration
* **Time to Build:** **3 to 4 Weeks** (From architectural design, database modeling, and video pipeline integration to UI polish, AI subtitle simulation, and desktop optimization).

---

## 8. 📊 Current Status
* **Status:** **Completed & Production-Ready**
* All core features (Local playback, YouTube extraction, AI subtitle transcription & translation, Chapter extraction, SQLite persistence, Watch history, and Desktop/Mobile UI) are fully operational and verified.

---

## 9. 🔗 Links & Resources
* **GitHub Repository:** `https://github.com/your-username/velo_player` *(Update with your repository URL)*
* **Demo Video / APK Release:** `[Add Demo / Release Link Here]`

---

## 10. 🧗 Challenges Faced & Solutions

### Challenge 1: Video Playback Support on Windows Desktop
* **Problem:** Flutter’s official `video_player` plugin historically targeted Android and iOS, failing to render native video textures on Windows.
* **Solution:** Integrated `video_player_win` backed by Windows Media Foundation / DirectShow. Initialized `WindowsVideoPlayer.registerWith()` inside `main.dart` alongside `sqfliteFfiInit()`, abstracting platform specifics behind a unified `PlayerController`.

### Challenge 2: Gesture Collisions in the Custom Player HUD
* **Problem:** Vertical swipes for volume/brightness conflicted with seek scrubbing and single taps that toggle the playback controls overlay.
* **Solution:** Developed a dedicated `PlayerGestureLayer` with spatial zone partitioning (left 40% for brightness, right 40% for volume, center 20% neutral). Used custom `onVerticalDragUpdate` thresholds and `GestureDetector` callback timing to guarantee responsiveness without interfering with seek sliders.

### Challenge 3: Synchronizing AI Subtitles during Rapid Seeking & Variable Playback Speeds
* **Problem:** When users scrubbed the timeline or played at 2.0x speed, subtitle cues lagged or displayed out-of-order text.
* **Solution:** Stored subtitle segments with `start_ms` and `end_ms` indexed fields. Used Riverpod state caching with binary lookup against `position.inMilliseconds` inside the frame listener, ensuring instant zero-lag cue synchronization at any playback speed.

### Challenge 4: YouTube Stream Extraction Resiliency
* **Problem:** YouTube videos frequently change manifest schemas, lack single muxed streams (separate audio/video tracks), or throw age/purchase restriction exceptions.
* **Solution:** Built `YouTubeExtractorService` with prioritized stream sorting (`manifest.muxed.sortByVideoQuality()`), quality fallbacks to standalone video streams, 15-second network timeout boundaries, and specific typed exception handlers (`VideoUnplayableException`, `VideoRequiresPurchaseException`).

