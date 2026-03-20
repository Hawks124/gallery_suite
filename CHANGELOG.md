# Changelog

All notable changes to this package will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-03-20

### 🎉 Initial Release

#### Image Picker

- Instagram-style **3-column masonry grid** with natural aspect-ratio tiles
- **Multi-selection** with ordered number badges and animated selection overlay
- **Draggable Swipe-To-Select**: iOS-style drag/swipe selection capabilities directly over the Masonry grid. Long press and drag finger to select multiple images rapidly. Includes intelligent auto-scrolling.
- **Native Camera Integration**: High-performance inline `CameraTileWidget` directly in the media grid using the official `camera` package.
- **Premium Camera Screen**: Completely redesigned full-screen camera with Dribbble-inspired UI, smooth glassmorphism effects (`BackdropFilter`), and elegant pulsing animations.
- **Bottom preview strip** (BackdropFilter blur) showing selected items with remove button
- **DraggableScrollableSheet album switcher** with cover thumbnails and asset count
- **Pulsing skeleton** loading screen with realistic masonry proportions
- High-quality thumbnails: **400×400 @ quality 90** — sharp, never stretched
- Infinite scroll pagination (80 items per page) with automatic load-more

#### Video Picker

- Same masonry grid with **play button overlay** on every tile
- Tap → **slide-up bottom sheet** video preview (88% screen height)
- Inline `VideoPlayer` with **auto-play**, play/pause tap, and seek bar
- "Sélectionner cette vidéo" full-width confirm button
- Handles loading state and file error gracefully

#### Audio Picker

- Full **list view** of audio files with album art thumbnails
- **Inline `just_audio` playback** — tap tile to play/pause
- Animated **mini player** (BackdropFilter blur) with seek bar, play/pause and close
- Track title cleaned of file extensions, duration displayed
- Single-select with animated circle badge

#### Performance & Architecture (10,000+ Assets)

- **Frame-Budget-Aware Decoding**: Added `ThumbnailDecodeQueue` that limits concurrent thumb decodes to 3, ensuring buttery smooth 60/120fps scrolling.
- **LRU Memory Cache**: Replaced unbounded map with an intelligent LRU cache (`thumbnailCacheSize` = 200, max 50MB) with auto-eviction to prevent OOM errors.
- **Scroll-Aware Prefetching**: Grid intelligently pre-loads the next ~30 thumbnails before they enter the screen (`prefetchEnabled`), eliminating UI pop-in.
- Pagination heavily tuned: now triggers at 1500px instead of 800px, and fetches adaptive page sizes (80 initial, 120 subsequent) for fewer round-trips.
- Singleton `MediaService` architecture for unified resource tracking.
- `AnimationController` optimizations (GPU saver): Shimmer effects now completely stop ticking once the thumbnail loads.

#### General

- **Adaptive dark/light theme** — iOS-inspired color system, auto-follows system or overridable
- `PickerConfig` for full customisation: primary color, max selection, media type, brightness, labels, and `useOriginalFile` option for uncompressed assets.
- Exposes `thumbnailCacheSize`, `maxConcurrentDecodes`, and `prefetchEnabled` via `PickerConfig`.
- Smooth entrance **slide-up page transition** (320 ms easeOutCubic)
- `HapticFeedback` on selection and limit hit
- Permission denied screen with settings CTA
- Zero-dependency on `image_picker` or native OS dialogs — 100% in-app UI
- **Cross-Platform**: Support for Android, iOS, Web, Windows, macOS, and Linux.

---
