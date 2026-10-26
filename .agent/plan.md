# Project Plan

Build a complete, production-quality video player app for Android called VDO Player. The app should have a library scanner, a feature-rich playback engine with gestures, and persistence for watch history using Room. Use Material 3, Jetpack Compose, and Media3 ExoPlayer.

## Project Brief

# Project Brief: VDO Player

A production-quality Android video player application that delivers a modern, feature-rich media experience inspired by industry leaders like MX Player, built natively for the Android ecosystem.

### Features
- Video Library Scanner: Automatically scans local storage for video formats (MP4, MKV, AVI, etc.), extracts metadata, and generates high-quality thumbnails while grouping content by folders.
- Adaptive Library UI: A Material 3-based browsing experience that adapts to smartphone and tablet form factors, featuring search, sorting, and "Favorites" management.
- Advanced Playback Engine: A robust video player supporting custom gesture controls for volume, brightness, and seeking, alongside aspect ratio cycling and subtitle support.
- Playback Persistence: Integrated watch history that saves the last playback position for every video, allowing users to resume exactly where they left off.

### High-Level Technical Stack
- Kotlin: The core language for modern Android development.
- Jetpack Compose: For building a vibrant, energetic, and fully reactive UI.
- Jetpack Navigation 3: Implementing a state-driven navigation strategy for better predictability and testing.
- Compose Material Adaptive: Ensuring a seamless user experience across all device types including foldables and tablets.
- Media3 ExoPlayer: The industry-standard engine for high-performance video playback and gesture integration.
- Room Database: For persisting watch history, last playback positions, and user favorites.
- Coroutines & Flow: For efficient background processing and reactive data updates.
- Coil: Optimized image loading for video thumbnails.

## Implementation Steps

### Task_1_DataLayerAndScanner: Setup Room database for watch history and favorites. Implement a MediaStore scanner to fetch local videos, group them by folders, and extract metadata and thumbnails using Coil.
- **Status:** COMPLETED
- **Updates:** Completed the data layer and scanner setup.
- **Acceptance Criteria:**
  - Room database correctly stores video history and favorites
  - MediaStore scanner retrieves local videos and groups them by folder
  - Thumbnails are extracted and displayable
  - Project builds successfully

### Task_2_LibraryUIAndNavigation: Create the library UI using Material 3 and Navigation 3. Implement adaptive layouts for folder and video lists. Add search, sorting, and favorites management functionality.
- **Status:** COMPLETED
- **Updates:** Completed the Library UI and Navigation setup.
- **Acceptance Criteria:**
  - Navigation 3 manages state-driven transitions between screens
  - UI adapts seamlessly to different screen sizes using Adaptive library
  - Search and Favorites features are fully functional

### Task_3_PlaybackEngineAndPersistence: Integrate Media3 ExoPlayer. Build a custom player UI with gesture controls for volume, brightness, and seeking. Implement logic to save and resume playback positions from the Room database.
- **Status:** COMPLETED
- **Updates:** Completed the Playback Engine and Persistence setup.
- Integrated Media3 ExoPlayer for video playback.
- Built a custom player UI with intuitive gesture controls (brightness, volume, seeking).
- Implemented auto-resume logic using Room database to save and restore playback positions.
- Added aspect ratio cycling support (Fit, Zoom, Fill).
- Verified smooth playback and gesture responsiveness.
- **Acceptance Criteria:**
  - Smooth video playback using Media3 ExoPlayer
  - Gestures for volume, brightness, and seeking work correctly
  - Playback resumes from the last saved position in Room
  - Aspect ratio cycling and subtitle support are functional
- **Duration:** N/A

### Task_4_ThemingIconAndFinalVerification: Implement a vibrant Material 3 theme (Light/Dark), enable full Edge-to-Edge display, and create an adaptive app icon. Perform a final run to verify stability and alignment with requirements.
- **Status:** IN_PROGRESS
- **Acceptance Criteria:**
  - Vibrant and energetic Material 3 color scheme applied
  - Full Edge-to-Edge display implemented
  - Adaptive app icon matching the app's function is present
  - App does not crash and builds successfully
  - Final verification confirms alignment with all user requirements
- **StartTime:** 2026-07-20 00:44:51 IST

