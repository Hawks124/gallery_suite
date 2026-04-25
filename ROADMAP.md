# Gallery Suite Roadmap

This document outlines the planned roadmap and potential future features for the `gallery_suite` (`custom_media_picker`) package. Our goal is to maintain the most premium, customizable, and frictionless media picking experience in the Flutter ecosystem.

## 🚀 Near-Term (Next Minor Releases)

- [x] 🔄 **Pre-selected Media (`initialSelection`)**: [Priority: 🔥 Critical] Allow developers to pass an initial list of selected `MediaItem`s. Vital for editing an existing selection (like adding a 4th photo to an already constructed post).
- [x] 🪄 **Auto-Conversion HEIC to JPG**: [Priority: 🔥 High] Background converter to natively transform iOS HEIC/HEVC photos to standard JPG before returning the file (using `flutter_image_compress`), avoiding cross-platform rendering crashes. _(⚠️ Experimental: Natively implemented using safe defensive fallback, but heavily requires physical iOS device contributions to perfectly test.)_
- [x] **Camera Integration**: Allow taking photos and recording videos directly from within the picker grid (a live camera tile as the first item).
- [x] **Localization Support**: Add robust built-in `intl` delegate for standard translations without forcing developers to manually inject text config for every language.
- [x] **Draggable Selection**: Allow users to swipe-to-select multiple items rapidly without lifting their finger, similar to iOS Photos.
- [ ] **Custom Video Trimmer**: A lightweight, integrated video trimming UI immediately after selecting a video(Canceled).

## ✨ Upcoming Premium UX Ideas (To Discuss)

- [x] 📋 **Smart Clipboard Integration**: [Priority: 🔥 High] A dynamic grid tile that detects raw images or direct media URLs copied to the device's clipboard. Automatically fetches, decodes, and allows instant selection of copied assets (implemented v1.0.0).
- [x] ♿ **A11y (Accessibility) Compliance**: [Priority: 🛡️ High] Inject deep `Semantics` tags for VoiceOver/TalkBack to make the package Enterprise & Government ready. (Long Terms)
- [x] 🦸‍♂️ **"Hero" Animations**: [Priority: 🌟 Medium] Implement seamless `Hero` flying transitions between the grid thumbnails and full-screen previews (Dribbble-level UX).
- [x] 🗜️ **Smart Compression Hooks**: [Priority: 📈 Medium] Add `onCompressMedia` callback or native ultra-light fast bridge for client-side raw video/photo compression. (Now using Hybrid built-in & BYOC approach)
- [x] **Drag & Drop Reordering**: Allow users to drag-and-drop images in the bottom preview strip to change their selection order before sending.
- [ ] **GIF & Sticker Panel**: A dedicated tab to search and select GIFs (via Giphy/Tenor integration) without leaving the picker.
- [ ] **Document/File Support**: Expand the UI to support picking PDFs and Documents with the same beautiful, glassmorphic design(Canceled).

- [x] **Image Cropper & Editor Integration**: Native hooks to crop, rotate, and add basic filters to images before confirming the selection(by Injection).
- [x] **Performance Optimizations**: Advanced caching strategies for massively large photo libraries (10,000+ assets) to achieve 120fps scrolling on ProMotion displays.
- [x] **Customizable Providers**: Allow fetching assets from remote sources (e.g., Google Photos API, Network URLs) alongside local device assets.

## 🏗️ Long-Term Vision

- [x] **Web Support (HTML5 File Input)**: Since `photo_manager` relies on native mobile APIs, the web implementation will abstract the UI and fallback to an elegant `file_selector` or standard `<input type="file" multiple>` overlay that mirrors the mobile masonry layout once files are loaded into browser memory.
- [x] **Desktop Support (macOS / Windows)**: Integrate `file_selector` for native window dialogs, and support drag-and-drop file inputs directly into the Masonry Grid window using `desktop_drop`. Ensure keyboard shortcuts (Shift+Click) mirror mobile dragging behaviors.

---

_Suggestions and Pull Requests are always welcome! Feel free to open an issue to discuss new features._
