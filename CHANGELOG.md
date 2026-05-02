# Changelog

All notable changes to this package will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-dev.1] - 2026-05-02

### V2 Pre-release (Development)

- First pre-release of Gallery Suite for early adopters and community feedback.
- **Feat**: Introduced architecture for Configurable Grid Layouts (`Aligned`, `Quilted`, `Staggered` and `BYOG`).
- **Feat**: Added blueprint for Local File Sorting (`Newest`, `Oldest`, `Largest`, `Smallest`) with isolate-based processing.
- **Refactor**: Abstracted list generation into a dedicated `DynamicGridLayout` widget.

## [1.0.0] - 2026-03-24

### Initial Release

Welcome to the first stable release of `gallery_suite`! This package provides a premium, fully customized in-app media picker experience.

- **Pure Dart & Multi-Platform**: Platform-agnostic architecture natively supporting iOS, Android, macOS, Web, Windows, and Linux.
- **Desktop First-Class Experience**: Intelligent LayoutBuilder responsive grids, `Ctrl+A`/`Cmd+A` keyboard shortcuts, and a clean BYOD (Bring Your Own Drop) native injection hook.
- **Google Photos Built-in Provider**: Natively browse, select, and organize Google Photos assets directly within the grid.
- **Native iCloud Integration**: Transparent support for iCloud photo libraries with zero configuration required.
- **Glassmorphic Cloud Indicators**: Visual feedback badges for iCloud and remote assets to ensure a responsive user experience.
- **Smart Cloud-to-Local Bridge**: Automatic background downloading of cloud assets to local temporary files.
- **March 2025 Policy Compliant**: Fully integrated the latest Google Photos Picker API.

### Core Pickers

### Standalone Multi-Capture Camera

- **Entry Point**: `CustomMediaPicker.camera()` allows developers to bypass the gallery and directly invoke a full-screen camera session optimized for taking multiple rapid shots or videos (configured via `CameraPickerConfig`).
- **Review & Manage Strip**: A beautiful horizontal bottom capture strip allowing users to review, delete, and edit captures before finalizing the session.
- **BYOE Live Injection**: Provide your own image editor (via `onEditMedia` hook) and it seamlessly integrates into the camera preview screen.
- **Dynamic Video Handling**: High-performance state management enforcing memory limits and optimized video returning.

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

### Premium Capabilities

#### Hybrid Smart Compression (Built-in + BYOC)

- **Upload Bandwidth Saver**: Integrated an intelligent core compression engine for JPEG images, automatically reducing payload size for remote server uploads by up to 80% with minimal quality loss.
- **Bring Your Own Compressor (BYOC)**: Introduced a powerful `onCompressMedia` hook in `PickerConfig`. Seamlessly inject your own advanced video compressors (e.g., `video_compress`) and the picker natively tracks their progress, overriding the default behavior securely.

#### Auto-Conversion HEIC to JPG (Experimental)

- **Cross-Platform Bridge**: Solves the nightmare of HEIC format crashes on web/Android by natively intercepting iOS HEIC photos and transparently converting them to standard JPG locally using native platform bridges before returning them to your application layer.

#### Zero-Dependency Internationalization (Intl)

- **Text Delegate Pattern**: Complete translation support without adding heavy `intl` package dependencies or ARB files.
- **Built-in Languages**: Ships with `EnglishPickerTextDelegate` and `FrenchPickerTextDelegate` out-of-the-box.
- **Micro-Overrides**: Easily override single words natively via `FrenchPickerTextDelegate(confirm: 'Envoyer')`.

#### Accessibility (A11y) & Enterprise Readiness

- **Native Semantics**: The picker UI and Masonry grid are now natively annotated with `Semantics` tags.
- **VoiceOver & TalkBack Ready**: Screen readers will natively announce whether an item is an image or a video, its duration, and its exact selection order.
- **i18n Compatible**: A11y string templates are woven deeply into the `PickerTextDelegate`, meaning screen readers will talk to the user in their localized language.

#### Smart Clipboard Integration

- **Seamless Media Paste**: Natively parses the system clipboard for raw image bytes (e.g., screenshots), local file paths, or remote media URLs (with automatic MIME detection).
- **Anti-Bot URL Scraping (New)**: Upgraded the URL scraper with 5 fallback passes to reliably extract OpenGraph images, Schema tags, and raw fallback URLs (bypassing Google Search JSON blocks and Freepik 403s with proper iOS User-Agent strings).
- **App Lifecycle Resume (New)**: Smart Clipboard now seamlessly hooks into `WidgetsBindingObserver` to automatically refresh copied assets the moment the user resumes the app from the background, retaining historical items without dropping data.
- **Isolated Pseudo-Album**: Displays pasted multi-media assets beautifully inside the masonry grid as a virtual "Clipboard" album, exactly like Google Photos or local storage.
- **Opt-In & Pure Dart**: Completely optional (`enableSmartClipboard: true`) and zero-bloat. Raw bytes are securely flushed to temporary files to prevent OOM errors and memory leaks.
- **Cross-Picker Support**: The Smart Clipboard is natively accessible not only in the Image Picker's Album Sheet but also directly inside the Audio Picker's AppBar via an intelligent trailing icon.

#### Pre-Selected Media (Initial Selection)

- **Seamless Editing**: Easily pass a `initialSelection` list of `MediaItem`s to the `PickerConfig` to re-open the picker with those items already selected.
- **Smart Mapping**: The package automatically matches the injected items with the grid assets using their `id`, preserving the exact visual selection state across sessions.
- **Cross-Picker Support**: Works natively for Image, Video, and Audio pickers.

#### Bring Your Own Editor (BYOE) Integration

- **Zero Bloatware Image Editing**: Natively edit/crop selected images inside the picker via the new `onEditMedia` callback in `PickerConfig` without adding heavy editor dependencies to the package.
- **Live UI Updates**: Automatically displays a pencil badge on editable assets and seamlessly overlays `Image.file` to show the edited photo directly in the preview strip.
- **Optimized Data Propagation**: The picker natively returns populated `MediaItem`s carrying the `editedFile` securely back to the caller.

#### Inline Asset Search

- **Cross-Platform**: Beautiful, iOS-style frosted `CupertinoSearchTextField` embedded natively at the top of the grid for Images, Videos, and Audio pickers.
- **Dart-Side Filtering**: Lightning-fast, debounced (300ms) memory filtering of thousands of assets across iOS, Android, macOS, Windows, and Web without relying on unpredictable or unstable native DB query predicates.
- **Fluid UX**: Smooth 240ms `AnimatedSize` transitions, clean "No Results" placeholder, and independent Send Button.

#### Drag & Drop Reordering

- **Dribbble-Style UX**: Long-press any selected image in the bottom preview strip to smoothly detach, scale up (`1.05x`), cast a dynamic drop-shadow, and drag it horizontally to change the selection order!
- **Auto-Syncing Badges**: Dragging and dropping the items instantly and natively synchronizes the numerical badges on the main masonry grid.

#### Google Photos Built-in Provider (Premium Cloud Integration)

- **First-Class Cloud Support**: Natively browse, select, zoom, and reorganize Google Photos assets directly inside the picker, mixing them seamlessly with local device photos.
- **Polymorphic Architecture**: The package intelligently returns mixed arrays of `MediaItem`s containing either local `AssetEntity` files or `RemotePickerAsset` metadata, gracefully disabling local-only features (like BYOE editors) for cloud URLs.
- **2026 Policy Compliant (Picker API)**: Fully integrated the new `photospicker.mediaitems.readonly` scope and API to bypass Google's March 2025 restrictive rollout, avoiding the need for an expensive CASA Tier-2 security audit.
- **Robust Security**: Utilizes a strict platform-independent PKCE OAuth2 flow for the Picker API, managed globally via a single initialization call to `GooglePhotosService.instance.init()`.
- **Zero-Dependency Disk Persistence**: Appends and saves imported cloud assets (alongside authentication state) locally `path_provider`, allowing sessions and selected media to survive hot-restarts and app closures without relying on heavy state management tools.
- **Intelligent Auto-Refresh**: Seamlessly handles OAuth2 token lifespan limits by exchanging the `refresh_token` in the background, ensuring uninterrupted user experiences.
- **Secure Sign-Out Flow**: Added an integrated "Sign Out" button inside the Album selector sheet, protected by a beautiful `StandardExitConfirmation` dialog and a loading overlay to prevent accidental data loss.

#### Exit Confirmation Prevention

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

### Exit Confirmation Dialog

- **Accidental Exit Prevention**: Added an optional confirmation dialog that appears when the user tries to exit the picker while having selected or edited media.
- **Standard Confirmation**: Includes a beautiful, built-in confirmation dialog with `StandardExitConfirmation` (title, content, confirm/cancel buttons) that can be enabled with a single line in `PickerConfig`.
- **Custom Confirmation**: Supports fully custom confirmation UIs via `CustomExitConfirmation` for complete design flexibility.
- **Safe Navigation**: Implemented robust `mounted` checks throughout the exit flow to prevent navigation errors and crashes.
- **Zero-Config Default**: The feature is opt-in and does not affect existing implementations that don't configure `exitConfirmation`.

---
