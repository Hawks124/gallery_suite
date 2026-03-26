# Gallery Suite Roadmap

This document outlines the planned roadmap and potential future features for the `gallery_suite` (`custom_media_picker`) package. Our goal is to maintain the most premium, customizable, and frictionless media picking experience in the Flutter ecosystem.

## 🚀 Near-Term (Next Minor Releases)

- [x] **Camera Integration**: Allow taking photos and recording videos directly from within the picker grid (a live camera tile as the first item).
- [x] **Localization Support**: Add robust built-in `intl` delegate for standard translations without forcing developers to manually inject text config for every language.
- [x] **Draggable Selection**: Allow users to swipe-to-select multiple items rapidly without lifting their finger, similar to iOS Photos.
- [ ] **Custom Video Trimmer**: A lightweight, integrated video trimming UI immediately after selecting a video(Canceled).

## ✨ Upcoming Premium UX Ideas (To Discuss)

- [x] **Drag & Drop Reordering**: Allow users to drag-and-drop images in the bottom preview strip to change their selection order before sending.
- [ ] **GIF & Sticker Panel**: A dedicated tab to search and select GIFs (via Giphy/Tenor integration) without leaving the picker.
- [ ] **Document/File Support**: Expand the UI to support picking PDFs and Documents with the same beautiful, glassmorphic design(Canceled).

- [x] **Image Cropper & Editor Integration**: Native hooks to crop, rotate, and add basic filters to images before confirming the selection(by Injection).
- [x] **Performance Optimizations**: Advanced caching strategies for massively large photo libraries (10,000+ assets) to achieve 120fps scrolling on ProMotion displays.
- [x] **Customizable Providers**: Allow fetching assets from remote sources (e.g., Google Photos API, Network URLs) alongside local device assets.

## 🏗️ Long-Term Vision

- [ ] **Web Support (HTML5 File Input)**: Since `photo_manager` relies on native mobile APIs, the web implementation will abstract the UI and fallback to an elegant `file_selector` or standard `<input type="file" multiple>` overlay that mirrors the mobile masonry layout once files are loaded into browser memory.
- [ ] **Desktop Support (macOS / Windows)**: Integrate `file_selector` for native window dialogs, and support drag-and-drop file inputs directly into the Masonry Grid window using `desktop_drop`. Ensure keyboard shortcuts (Shift+Click) mirror mobile dragging behaviors.

---

_Suggestions and Pull Requests are always welcome! Feel free to open an issue to discuss new features._
