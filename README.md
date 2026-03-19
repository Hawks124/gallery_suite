# gallery_suite

<p align="center">
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/branding_banner.png" alt="Gallery Suite Branding Banner" width="100%" />
</p>

[![pub.dev](https://img.shields.io/pub/v/gallery_suite.svg)](https://pub.dev/packages/gallery_suite)
[![pub size](https://img.shields.io)](https://pub.dev)
[![pub tag](https://img.shields.io)](https://pub.dev)
[![pub points](https://img.shields.io)](https://pub.dev)
[![popularity](https://img.shields.io)](https://pub.dev)
[![likes](https://img.shields.io)](https://pub.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev)

**Gallery Suite** is a premium, fully customizable in-app media picker for Flutter. Stop fighting with restrictive native OS dialogs and inconsistent platform UIs. Build seamless, beautiful media selection flows with masonry grids, inline video & audio playback, glassmorphism, and fluid micro-animations.

<p align="center">
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_image_picker.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_video_preview.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_audio_picker.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_theme_dark.png" width="24%" />
</p>

---

## 📑 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [🤔 Why Gallery Suite?](#-why-gallery-suite)
- [✨ Features](#-features)
- [📦 Installation & Setup](#-installation--setup)
- [💻 Usage](#-usage)
  - [Pick Images](#pick-images)
  - [Pick a Video](#pick-a-video)
  - [Pick Audio](#pick-audio)
  - [Disabling the Live Camera Tile](#disabling-the-live-camera-tile)
  - [Disabling Swipe-To-Select](#disabling-swipe-to-select)
- [📤 Handling Selected Media (Upload Example)](#-handling-selected-media-upload-example)
- [⚙️ PickerConfig API](#%EF%B8%8F-pickerconfig-api)
- [🚀 Version History & Roadmap](#-version-history--roadmap)
- [⚡ Performance Notes](#-performance-notes)
- [📝 License & Acknowledgements](#-license--acknowledgements)

---

## 🚀 Quick Start

**1. Add dependency**

```yaml
dependencies:
  gallery_suite: ^1.0.0
```

**2. Open the picker and get the files**

`CustomMediaPicker.show` returns a `List<MediaItem>` (or `null` if the user cancels).

```dart
import 'package:gallery_suite/gallery_suite.dart';

final assets = await CustomMediaPicker.show(context: context);
if (assets != null) {
  for (final item in assets) {
    final file = await item.file;
    // upload or preview `file`
  }
}
```

> [!IMPORTANT]
> Don't forget to add **Permissions** in your `AndroidManifest.xml` and `Info.plist`. [See Setup](#-installation--setup).

---

## 🤔 Why Gallery Suite?

The built-in `image_picker` delegates to the operating system's native media browser. That works, but you give up control: the UI looks different on every Android version, it doesn't match your app's theme, and it can't do anything beyond handing you a file path.

`gallery_suite` builds the entire picker inside Flutter. You get a consistent, premium UI on every device, and because it owns the UI, it provides a much richer experience (like playing a video preview or an audio track before the user commits to sending it).

**Compared to similar packages:**

| Feature          | `image_picker`    | `wechat_assets_picker` | `gallery_suite`                 |
| ---------------- | ----------------- | ---------------------- | ------------------------------- |
| Assets supported | Image, Video      | Image, Video, Audio    | Image, Video, Audio             |
| Picker UI        | Native OS dialog  | WeChat-style grid      | Custom Masonry grid             |
| Audio/Video UI   | System default    | Yes                    | Inline playback (Mini-player)   |
| Multi-select     | Images only       | Yes                    | Yes (Images & Audio)            |
| In-app Camera    | No                | No                     | ✅ Yes (Live tile & Custom UI)  |
| Swipe-To-Select  | No                | No                     | ✅ Yes (iOS Photos style)       |
| UI Theming       | System restricted | Restricted             | Fully customizable per-instance |

---

## ✨ Features

**Image Picker**

- 📸 **Built-in Native Camera** — live preview tile directly in the grid at position 0. Full custom `CameraScreen` with flash, flip, and recording support. Can be disabled via `showCameraTile: false`.
- 👆 **iOS-style Swipe-To-Select** — long press and drag your finger to rapidly select multiple images in one fluid motion. Includes intelligent auto-scrolling near screen edges. Can be disabled via `enableSwipeToSelect: false`.
- Masonry grid — photos display at their natural proportions, no forced square crops.
- Multi-select with numbered badges showing order of selection.
- Horizontal preview strip at the bottom with selected items.
- Album switcher sheet (slide-up, drag to expand).

**Video Picker**

- Built-in Native Camera — record videos directly from the live tile without leaving the app.
- Same masonry grid with a duration badge on each tile.
- Tap a tile → bottom sheet with a full inline video player.
- Confirm button in the sheet — user can preview before deciding to send.

**Audio Picker**

- List view with album art, track name, and duration for each file.
- Tap a track to play or pause it inline.
- Mini player. Selection is separated from playback.

**All Pickers**

- Fully customizable theming via `PickerConfig.brightness` and `primaryColor`.
- Haptic feedback and native-feeling micro-animations and _Glassmorphism_.
- Smooth skeleton loaders and optimized pagination (80 items per page).

---

## 📦 Installation & Setup

1. Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  gallery_suite: ^1.0.0
```

2. Because this package accesses the device's native media library, **you must configure native permissions before using it.** It will crash or show a "Permission Denied" screen if you skip this step.

### Android Setup

_(Supports API 21+)_

Inside `android/app/src/main/AndroidManifest.xml` `<manifest>` block:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Required for the built-in camera tile -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Android 9 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

Inside the `<application>` block of the same file:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

**Create `android/app/src/main/res/xml/file_paths.xml`** with the following content (required for Android API 29+ scoped storage access):

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
</paths>
```

### iOS Setup

_(Supports iOS 11+)_

Inside `ios/Runner/Info.plist`:

```xml
<!-- Required by photo_manager -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to let you pick photos and videos to share.</string>

<!-- Required for the built-in camera tile -->
<key>NSCameraUsageDescription</key>
<string>Used to let you take photos and videos directly from the app.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to record audio for videos.</string>

<!-- Helpful for just_audio background compatibility -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## 💻 Usage

First, import the package and `photo_manager` (which provides the `RequestType` enum):

```dart
import 'package:gallery_suite/gallery_suite.dart';
import 'package:photo_manager/photo_manager.dart';
```

### Pick Images

```dart
// Full-featured: Camera tile + Swipe-to-select + Multi-select
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.image,
    maxSelection: 10,
    showCameraTile: true,        // Live camera feed at index 0
    enableSwipeToSelect: true,   // iOS-style drag to select
    primaryColor: Colors.deepPurple,
    confirmText: 'Done',
  ),
);
```

### Pick a Video

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.video,
    maxSelection: 1,             // Videos are usually single-select
    showCameraTile: true,        // Camera tile records video in this mode
  ),
);
```

### Pick Audio

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.audio,
    maxSelection: 5,             // Supports multi-select!
    primaryColor: Colors.purple,
  ),
);
```

### Disabling the Live Camera Tile

By default, an integrated live camera tile appears at the `0` index of the image and video grids. This allows users to capture and send media seamlessly without leaving the picker. If you want to disable this and handle the camera yourself, simply set `showCameraTile: false`.

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.image,
    showCameraTile: false, // Hides the built-in camera
  ),
);
```

### Disabling Swipe-To-Select

The iOS-style swipe-to-select is enabled by default. If you prefer a classic tap-only selection, simply set `enableSwipeToSelect: false`.

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.image,
    enableSwipeToSelect: false, // Classic tap-only selection
  ),
);
```

---

## 📤 Handling Selected Media (Upload Example)

While `gallery_suite` handles the complex UI of picking files, you will often want to upload them to your backend. The `.show()` method returns a `List<MediaItem>?`.

```dart
final assets = await CustomMediaPicker.show(context: context);
if (assets == null || assets.isEmpty) return;

// Get the Dart `File` asynchronously from the `MediaItem`
final item = assets.first;
final file = await item.file;

if (file == null) return;

try {
  setState(() => _isUploading = true);

  // MOCK: Your custom upload service
  final String downloadUrl = await myUploadService.uploadFile(
    file: file,
    path: 'uploads/images/${item.id}.jpg',
  );

  print('Uploaded successfully: $downloadUrl');
} catch (e) {
  print('Upload failed: $e');
} finally {
  setState(() => _isUploading = false);
}
```

_`MediaItem` also gives you typed convenience getters:_

```dart
print(assets.first.isVideo);        // bool
print(assets.first.aspectRatio);    // double
```

---

## ⚙️ PickerConfig API

The entire look and feel is controlled via `PickerConfig`. Here is exactly what you can configure:

| Parameter             | Type          | Default             | Description                                                                                                                                                       |
| --------------------- | ------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `requestType`         | `RequestType` | `RequestType.image` | The specific gallery to open (`image`, `video`, or `audio`).                                                                                                      |
| `maxSelection`        | `int`         | `10`                | The maximum number of assets the user can select. Used in Images and Audio. Video is currently single-select.                                                     |
| `primaryColor`        | `Color`       | `Color(0xFF007AFF)` | The global accent color for checkmarks, badges, seek-bars, and confirm buttons.                                                                                   |
| `brightness`          | `Brightness?` | `null`              | Force a specific theme (`Brightness.dark` or `light`). If `null`, it automatically follows the system `Theme.of(context)`.                                        |
| `confirmText`         | `String`      | `'Sélectionner'`    | Localized text for the final send/done button.                                                                                                                    |
| `cancelText`          | `String`      | `'Annuler'`         | Localized text for the cancel button in the app bar.                                                                                                              |
| `showCameraTile`      | `bool`        | `true`              | When `true`, renders a live `camera` feed at index `0`. Supports both photo and video depending on `requestType`. Tap to open a full-screen Dribbble-inspired UI. |
| `enableSwipeToSelect` | `bool`        | `true`              | When `true`, allows the user to long-press and drag their finger across the masonry grid to rapidly select items (iOS Photos style). Includes edge auto-scroll.   |
| `useOriginalFile`     | `bool`        | `false`             | When `true`, fetches the absolute pristine original file rather than a system-optimized/compressed format from iOS or Android cache.                              |

---

## 🚀 Version History & Roadmap

We use [Semantic Versioning](https://semver.org/). This package is currently evolving rapidly:

| Version           | Status    | Highlights                                                                       |
| ----------------- | --------- | -------------------------------------------------------------------------------- |
| **v1.0.0**        | ✅ Stable | Core engine (Grid, Video, Audio), Live Camera Tile, iOS-style swipe-to-select    |

---

## ⚡ Performance Notes

- Thumbnails are decoded at 400 × 400 by `photo_manager`. `Image.memory` does not add a second decode step (`cacheWidth`/`cacheHeight` are intentionally omitted) — this is why thumbnails are sharp and not stretched.
- Each grid tile is wrapped in `RepaintBoundary`; only the tapped tile repaints on selection.
- A static `Map<String, Uint8List>` caches decoded thumbnails for the duration of the picker session. Call `MediaService.clearCache()` after closing the picker if memory is a concern.
- Pagination loads 80 assets per page; the next page triggers when the scroll position is within 800 px of the end.

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

## ❤️ Acknowledgements & Credits

`gallery_suite` stands on the shoulders of giants. This package would not exist without the incredible work of the following open-source contributors:

- **[photo_manager](https://pub.dev/packages/photo_manager)** — The high-performance engine powering our native media library access.
- **[flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view)** — Responsible for the beautiful and fluid Masonry layout of our grids.
- **[video_player](https://pub.dev/packages/video_player)** — Enabling our seamless, zero-latency inline video previews.
- **[just_audio](https://pub.dev/packages/just_audio)** — The backbone of our integrated audio playback experience.
- **[camera](https://pub.dev/packages/camera)** — Allowing us to build a premium, fully-integrated live camera capture experience into the grid.

Thank you to the Flutter community for building the "bricks" that allowed us to create this "house". 🏠✨
