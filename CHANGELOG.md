# Changelog

All notable changes to this package will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-24

### 🎉 Initial Release
Welcome to the first stable release of `gallery_suite`! This package provides a premium, fully customized in-app media picker experience.

### ✨ Core Pickers

#### 🖼️ Image Picker
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

#### 🎬 Video Picker
- Same masonry grid with **play button overlay** on every tile
- Tap → **slide-up bottom sheet** video preview (88% screen height)
- Inline `VideoPlayer` with **auto-play**, play/pause tap, and seek bar
- "Sélectionner cette vidéo" full-width confirm button
- Handles loading state and file error gracefully

#### 🎵 Audio Picker
- Full **list view** of audio files with album art thumbnails
- **Inline `just_audio` playback** — tap tile to play/pause
- Animated **mini player** (BackdropFilter blur) with seek bar, play/pause and close
- Track title cleaned of file extensions, duration displayed
- Single-select with animated circle badge

### 💎 Premium Capabilities

#### 🌍 Zero-Dependency Internationalization (Intl)
- **Text Delegate Pattern**: Complete translation support without adding heavy `intl` package dependencies or ARB files.
- **Built-in Languages**: Ships with `EnglishPickerTextDelegate` and `FrenchPickerTextDelegate` out-of-the-box.
- **Micro-Overrides**: Easily override single words natively via `FrenchPickerTextDelegate(confirm: 'Envoyer')`.

#### 🖌️ Bring Your Own Editor (BYOE) Integration
- **Zero Bloatware Image Editing**: Natively edit/crop selected images inside the picker via the new `onEditMedia` callback in `PickerConfig` without adding heavy editor dependencies to the package.
- **Live UI Updates**: Automatically displays a pencil badge on editable assets and seamlessly overlays `Image.file` to show the edited photo directly in the preview strip.
- **Optimized Data Propagation**: The picker natively returns populated `MediaItem`s carrying the `editedFile` securely back to the caller.

#### 🔍 Inline Asset Search
- **Cross-Platform**: Beautiful, iOS-style frosted `CupertinoSearchTextField` embedded natively at the top of the grid for Images, Videos, and Audio pickers.
- **Dart-Side Filtering**: Lightning-fast, debounced (300ms) memory filtering of thousands of assets across iOS, Android, macOS, Windows, and Web without relying on unpredictable or unstable native DB query predicates.
- **Fluid UX**: Smooth 240ms `AnimatedSize` transitions, clean "No Results" placeholder, and independent Send Button.

#### 🖱️ Drag & Drop Reordering
- **Dribbble-Style UX**: Long-press any selected image in the bottom preview strip to smoothly detach, scale up (`1.05x`), cast a dynamic drop-shadow, and drag it horizontally to change the selection order!
- **Auto-Syncing Badges**: Dragging and dropping the items instantly and natively synchronizes the numerical badges on the main masonry grid.

#### ☁️ Google Photos Built-in Provider (Premium Cloud Integration)
- **First-Class Cloud Support**: Natively browse, select, zoom, and reorganize Google Photos assets directly inside the picker, mixing them seamlessly with local device photos.
- **Glassmorphic Auth UI**: Features a beautiful blurred placeholder connecting screen if the user isn't logged in yet, maintaining the premium feel.
- **Polymorphic Architecture**: The package intelligently returns mixed arrays of `MediaItem`s containing either local `AssetEntity` files or `RemotePickerAsset` metadata, gracefully disabling local-only features (like BYOE editors) for cloud URLs.
- **Flexible Configuration (`GooglePhotosConfig`)**: Easily toggle the cloud tab via config. Supports zero-config automatic Firebase detection, or manual Web Client ID injection for strict environments.

#### 🔒 Exit Confirmation Prevention
- **Accidental Loss Protection**: Built-in dialog prevents users from accidentally losing selected/edited media when swiping back or hitting the hardware back button.
- **Fully Customizable UI**: Use `StandardExitConfirmation` for a gorgeous built-in blurred glass dialog, or `CustomExitConfirmation` to return your own widget tree.

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

### 🔒 Exit Confirmation Dialog

- **Accidental Exit Prevention**: Added an optional confirmation dialog that appears when the user tries to exit the picker while having selected or edited media.
- **Standard Confirmation**: Includes a beautiful, built-in confirmation dialog with `StandardExitConfirmation` (title, content, confirm/cancel buttons) that can be enabled with a single line in `PickerConfig`.
- **Custom Confirmation**: Supports fully custom confirmation UIs via `CustomExitConfirmation` for complete design flexibility.
- **Safe Navigation**: Implemented robust `mounted` checks throughout the exit flow to prevent navigation errors and crashes.
- **Zero-Config Default**: The feature is opt-in and does not affect existing implementations that don't configure `exitConfirmation`.

---
