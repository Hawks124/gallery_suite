# Gallery Suite Roadmap

This document outlines the planned roadmap and potential future features for the `gallery_suite` (`custom_media_picker`) package. Our goal is to maintain the most premium, customizable, and frictionless media picking experience in the Flutter ecosystem.

## 🚀 Near-Term (Next Minor Releases)

- [x] **Camera Integration**: Allow taking photos and recording videos directly from within the picker grid (a live camera tile as the first item).
- [x] **Localization Support**: Add robust built-in `intl` delegate for standard translations without forcing developers to manually inject text config for every language.
- [x] **Draggable Selection**: Allow users to swipe-to-select multiple items rapidly without lifting their finger, similar to iOS Photos.
- [ ] **Custom Video Trimmer**: A lightweight, integrated video trimming UI immediately after selecting a video(Canceled).

## ✨ Upcoming Premium UX Ideas (To Discuss)

- [ ] **Drag & Drop Reordering**: Allow users to drag-and-drop images in the bottom preview strip to change their selection order before sending.
- [ ] **GIF & Sticker Panel**: A dedicated tab to search and select GIFs (via Giphy/Tenor integration) without leaving the picker.
- [ ] **Document/File Support**: Expand the UI to support picking PDFs and Documents with the same beautiful, glassmorphic design.

- [x] **Image Cropper & Editor Integration**: Native hooks to crop, rotate, and add basic filters to images before confirming the selection(by Injection).
- [x] **Performance Optimizations**: Advanced caching strategies for massively large photo libraries (10,000+ assets) to achieve 120fps scrolling on ProMotion displays.
- [ ] **Customizable Providers**: Allow fetching assets from remote sources (e.g., Google Photos API, Network URLs) alongside local device assets.

## 🏗️ Long-Term Vision

- [ ] **Web Support**: Expand `photo_manager` abstractions to fully support a seamless web-based file selection fallback that mirrors the mobile app UI.
- [ ] **Desktop Support (macOS / Windows)**: Native-feeling grid dragging and window-based optimizations.

---

_Suggestions and Pull Requests are always welcome! Feel free to open an issue to discuss new features._
