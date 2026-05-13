# Gallery Suite Roadmap

This document outlines the planned roadmap and potential future features for the `gallery_suite` (`custom_media_picker`) package. Our goal is to maintain the most premium, customizable, and frictionless media picking experience in the Flutter ecosystem.

## Successfully Implemented (V1)

The following core features have been fully implemented and form the foundation of our stable releases:

- [x] **Smart Clipboard Integration**: Deep device clipboard scanner to detect and preview copied images and URLs.
- [x] **Google Photos Cloud API**: Fully authenticated, frictionless cloud fetching directly integrated alongside local media.
- [x] **Dynamic Grid Architecture**: Support for Masonry, Staggered, Aligned, Quilted, and BYOG (Bring Your Own Grid) layouts.
- [x] **Smart Sorting & Filtering**: Isolate-based (`compute`) fast sorting by Date (Newest/Oldest) and Size via pixel resolution mapping.
- [x] **Pre-selected Media (`initialSelection`)**: Easily inject previous states for seamless editing workflows.
- [x] **Auto-Conversion HEIC to JPG**: Native defensive architecture to prevent iOS rendering crashes on other platforms.
- [x] **Advanced Localization & A11y**: Deep `Semantics` tags for VoiceOver/TalkBack and multi-language `intl` delegates.
- [x] **Cross-Platform Support**: Feature-parity fallbacks using `file_selector` and `desktop_drop` for Web, macOS, and Windows.
- [x] **Performance Optimizations**: Multi-isolate native thumbnail decode queue to achieve 120fps scrolling on massive 10k+ libraries.
- [x] **BYOC Hooks (Bring Your Own Compressor/Editor)**: Complete abstraction letting developers inject their own `onCompressMedia` pipelines.

## Upcoming (V2 & V3 & Beyond)

- [ ] **GIF & Sticker Panel**: A dedicated tab to search and select lightweight animated media (via Giphy/Tenor integrations) without leaving the picker.
- [ ] **Grid Layouts**: Add more 100% customizable grid layouts like Masonry, Staggered, Aligned, Quilted, and BYOG (Bring Your Own Grid) layouts.
- [ ] **Native Database Size Sorting**: Investigate integration directly into `photo_manager`'s SQL query builder to retrieve localized byte sizes instantly without proxy formulas.
- [ ] **Extended Cloud Providers**: Out-of-the-box UI templates for Dropbox, OneDrive, or native AWS S3 ingestion.

## Scrapped / Out of Scope

- [ ] **Custom Video Trimmer**: _[Canceled]_ Video manipulation is too heavy for a picker UI. Best handled by a dedicated editor package.
- [ ] **Document/File Support**: _[Canceled]_ Expanding to PDFs and raw documents deviates from the 'Gallery' aesthetic. Recommended to use standard `file_selector` instead.

---

_Suggestions and Pull Requests are always welcome! Feel free to open an issue to discuss new features._
