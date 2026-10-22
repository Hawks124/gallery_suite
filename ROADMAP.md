# Gallery Suite Roadmap

This document outlines the planned roadmap and potential future features for the `gallery_suite` package. Our goal is to maintain the most premium, customizable, and frictionless media picking experience in the Flutter ecosystem.

## Successfully Implemented (V1.0.0)

The following core features have been fully implemented and form the foundation of our stable releases:

- [x] **Smart Clipboard Integration**: Deep device clipboard scanner to detect and preview copied images and URLs.
- [x] **Google Photos Cloud API**: Fully authenticated, frictionless cloud fetching directly integrated alongside local media.
- [x] **Dynamic Grid Architecture**: Support for Masonry, Staggered, Aligned, Quilted, and BYOG (Bring Your Own Grid) layouts.
- [x] **Smart Sorting & Filtering**: Database-level ordering by date and by **real byte size** (`MediaStore._size` on Android, real file size on Web/Desktop), pushed down to the gallery query so the pagination survives huge libraries.
- [x] **Pre-selected Media (`initialSelection`)**: Easily inject previous states for seamless editing workflows.
- [x] **Auto-Conversion HEIC to JPG**: Native defensive architecture to prevent iOS rendering crashes on other platforms.
- [x] **Advanced Localization & A11y**: Deep `Semantics` tags for VoiceOver/TalkBack and multi-language `intl` delegates.
- [x] **Cross-Platform Support**: Feature-parity fallbacks using `file_selector` and `desktop_drop` for Web, macOS, and Windows.
- [x] **Performance Optimizations**: Multi-isolate native thumbnail decode queue to achieve 120fps scrolling on massive 10k+ libraries.
- [x] **BYOC Hooks (Bring Your Own Compressor/Editor)**: Complete abstraction letting developers inject their own `onCompressMedia` pipelines.

## Upcoming (V1.1 & Beyond)

### 🔧 V1.1 — Modular Split: `gallery_suite_photos`

**Problem.** The core package currently ships **26 runtime dependencies** (12 of them native plugins) because the Google Photos provider is bundled inside it — even for the majority of users who never enable the cloud import. Every consumer pays the build time, the tree-shaking cost and the version-conflict risk of the whole Google stack.

**Plan.**

- Extract the Google Photos integration into a companion package **`gallery_suite_photos`**, published from a `gallery_suite_photos/` subfolder of this repository. One repo, one CI, one coordinated release train.
- Introduce a **`CloudSource`** extension point in the core, so any cloud provider (Google Photos, iCloud, Dropbox, S3…) can be plugged in without touching the picker internals.
- Introduce a **`RemoteBytesLoader`** typedef to replace the current `RemotePickerAsset.googleService` (`dynamic`) escape hatch, and a `RemotePickerAsset` model that stays in the core (the Smart Clipboard also produces remote assets).

**Result.** The core drops to **19 runtime dependencies** and **9 native plugins**. `google_sign_in`, `google_sign_in_web`, `googleapis_auth`, `extension_google_sign_in_as_googleapis_auth`, `crypto`, `app_links` and `url_launcher` move to the satellite.

**Guardrail.** The `CloudSource` abstraction and the satellite land only *after* the test suite introduced in 1.0.0, so the refactor of the picker page is covered by regression tests.

### 💡 Ideas to Discuss

- [ ] **GIF & Sticker Panel**: A dedicated tab to search and select lightweight animated media (via Giphy/Tenor integrations) without leaving the picker.
- [ ] **Extended Cloud Providers**: Out-of-the-box UI templates for Dropbox, OneDrive, or native AWS S3 ingestion — the `CloudSource` extension point is the enabler.
- [ ] **Native Database Size Sorting on iOS/macOS**: `PHAsset` does not expose the byte size, so the size orders are currently only offered on Android and Web/Desktop. A native plugin could expose it.

## Scrapped / Out of Scope

- [ ] **Custom Video Trimmer**: _[Canceled]_ Video manipulation is too heavy for a picker UI. Best handled by a dedicated editor package.
- [ ] **Document/File Support**: _[Canceled]_ Expanding to PDFs and raw documents deviates from the 'Gallery' aesthetic. Recommended to use standard `file_selector` instead.

---

_Suggestions and Pull Requests are always welcome! Feel free to open an issue to discuss new features._
