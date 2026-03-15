# Changelog

All notable changes to this package will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-01-01

### 🎉 Initial Release

#### Image Picker
- Instagram-style **3-column masonry grid** with natural aspect-ratio tiles
- **Multi-selection** with ordered number badges and animated selection overlay
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

#### General
- **Adaptive dark/light theme** — iOS-inspired color system, auto-follows system or overridable
- `PickerConfig` for full customisation: primary color, max selection, media type, brightness, labels
- Smooth entrance **slide-up page transition** (320 ms easeOutCubic)
- `HapticFeedback` on selection and limit hit
- Permission denied screen with settings CTA
- Shared **`LRU thumbnail cache`** across all pickers via `MediaService`
- Zero-dependency on `image_picker` or native OS dialogs — 100% in-app UI

---

## Roadmap

- [ ] GIF/sticker tab support
- [ ] Camera shortcut tile (first grid cell)
- [ ] Crop / rotate integration
- [ ] Multiple video selection
- [ ] iCloud / Google Photos remote asset support
- [ ] Localization (i18n) support
