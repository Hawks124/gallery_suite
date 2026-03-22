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
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
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

## 🤔 Why Gallery Suite?

The built-in `image_picker` delegates to the operating system's native media browser. That works, but you give up control: the UI looks different on every Android version, it doesn't match your app's theme, and it can't do anything beyond handing you a file path.

`gallery_suite` builds the entire picker inside Flutter. You get a consistent, premium UI on every device, and because it owns the UI, it provides a much richer experience (like playing a video preview or an audio track before the user commits to sending it).

### 🚀 Zero Bloatware & Extreme Performance

Unlike other pickers that force you to download massive editor dependencies or bloated video trimmers, `gallery_suite` keeps its core **100% pristine and lightweight**.

- **120fps Ready**: Powered by a custom `ThumbnailDecodeQueue` and LRU memory caching, the grid stays buttery smooth even when rapidly scrolling through 10,000+ assets.
- **Architecture by Injection**: We provide elegant, decoupled hooks. Want to crop an image? Pass your favorite editor to our `onEditMedia` callback. Our UI seamlessly integrates it without adding a single megabyte to the package's core footprint.

**Compared to similar packages:**

| Feature            | `image_picker`    | `wechat_assets_picker` | `gallery_suite`                     |
| ------------------ | ----------------- | ---------------------- | ----------------------------------- |
| Assets supported   | Image, Video      | Image, Video, Audio    | Image, Video, Audio                 |
| Picker UI          | Native OS dialog  | WeChat-style grid      | Custom Masonry grid                 |
| Audio/Video UI     | System default    | Yes                    | Inline playback (Mini-player)       |
| Multi-select       | Images only       | Yes                    | Yes (Images & Audio)                |
| In-app Camera      | No                | No                     | ✅ Yes (Live tile & Custom UI)      |
| Swipe-To-Select    | No                | No                     | ✅ Yes (iOS Photos style)           |
| Inline Search      | No                | No                     | ✅ Yes (Cross-platform Dart filter) |
| BYOE Image Editing | No                | No                     | ✅ Yes (Dependency Injection)       |
| UI Theming         | System restricted | Restricted             | Fully customizable per-instance     |

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

- 🔍 **Inline Asset Search** — Instantly filter your entire media library by filename/title with a beautiful iOS-style frosted search bar. Uses lightning-fast Dart-side memory filtering.
- 🖌️ **Bring Your Own Editor (BYOE) Architecture** — Why bloat your app with forced editors? Pass your favorite editor (like `pro_image_editor`) to the `onEditMedia` callback. The picker natively intercepts the edit, displays an elegant Pencil badge overlay, and flawlessly updates the preview strip to the new edited image.
- Fully customizable theming via `PickerConfig.brightness` and `primaryColor`.
- Haptic feedback and native-feeling micro-animations and _Glassmorphism_.
- Smooth skeleton loaders and optimized pagination (80 items per page).

---

## 📑 Table of Contents

- [🤔 Why Gallery Suite?](#-why-gallery-suite)
- [✨ Features](#-features)
- [🚀 Quick Start](#-quick-start)
- [📦 Installation & Setup](#-installation--setup)
  - [Android Setup](#android-setup)
  - [iOS Setup](#ios-setup)
- [💻 Core Usage](#-core-usage)
  - [📸 Pick Images](#-pick-images)
  - [🎬 Pick a Video](#-pick-a-video)
  - [🎵 Pick Audio](#-pick-audio)
- [🧠 Advanced Capabilities](#-advanced-capabilities)
  - [🖌️ Bring Your Own Editor (BYOE) Architecture](#️-bring-your-own-editor-byoe-architecture)
  - [📸 Getting Original Quality Files](#-getting-original-quality-files)
  - [🚫 Disabling the Live Camera Tile](#-disabling-the-live-camera-tile)
  - [👆 Disabling Swipe-To-Select](#-disabling-swipe-to-select)
  - [📤 Handling Selected Media (Upload Example)](#-handling-selected-media-upload-example)
  - [🎨 UI Theming & Customization](#-ui-theming--customization)
- [⚙️ PickerConfig API](#️-pickerconfig-api)
- [⚡ Performance Notes](#-performance-notes)
- [🚀 Version History & Roadmap](#-version-history--roadmap)
- [📜 License](#-license)
- [❤️ Acknowledgements & Credits](#️-acknowledgements--credits)

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

> [!TIP]
> By default, `gallery_suite` uses the OS-level cache (which might be compressed). To get the absolute original bytes, set `useOriginalFile: true` in your `PickerConfig`.

> [!IMPORTANT]
> Don't forget to add **Permissions** in your `AndroidManifest.xml` and `Info.plist`. [See Setup](#-installation--setup).

---

## 📦 Installation & Setup

Because this package accesses the device's native media library, **you must configure native permissions before using it.** It will crash or show a "Permission Denied" screen if you skip this step.

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

## 💻 Core Usage

First, import the package and `photo_manager` (which provides the `RequestType` enum):

```dart
import 'package:gallery_suite/gallery_suite.dart';
import 'package:photo_manager/photo_manager.dart';
```

### 📸 Pick Images

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

### 🎬 Pick a Video

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

### 🎵 Pick Audio

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

---

## 🧠 Advanced Capabilities

### 🖌️ Bring Your Own Editor (BYOE) Architecture

Why force your users to download a bloated media picker that comes packed with heavy image editing dependencies they don't even use?

`gallery_suite` introduces a pristine **Dependency Injection** architecture for media editing. You can pass your favorite image editor (like `pro_image_editor`, `image_cropper`, etc.) directly into the picker via the `onEditMedia` callback.

The picker will automatically:

1. Display an elegant **Edit Pencil overlay** on selected images.
2. Yield execution to your custom editor route.
3. Intercept the edited file and **seamlessly transition the UI** in the selected preview strip without requiring a server upload!

#### Example: Integrating `pro_image_editor`

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    // ...
    onEditMedia: (ctx, asset, file) async {
      // Only allow editing for images
      if (asset.type != AssetType.image) return null;

      // 1. Push your favorite editor route
      return await Navigator.of(ctx).push<File?>(
        MaterialPageRoute(
          builder: (editorCtx) => ProImageEditor.file(
            file,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (bytes) async {
                // 2. Save the edited bytes to a temporary file
                final tempDir = Directory.systemTemp.path;
                final newFile = File('$tempDir/edited.jpg');
                await newFile.writeAsBytes(bytes);

                // 3. Pop the editor and return the new File to the picker!
                if (editorCtx.mounted) {
                  Navigator.of(editorCtx).pop(newFile);
                }
              },
              onCloseEditor: (_) {
                if (editorCtx.mounted) {
                  Navigator.of(editorCtx).pop(null);
                }
              },
            ),
          ),
        ),
      );
    },
  ),
);
```

### 📸 Getting Original Quality Files

On some platforms (especially iOS), the operating system might convert high-efficiency formats (HEIC) to compressed JPEG when apps request a "file" from the library. This can lead to a slight loss in quality.

If your app requires the **pristine, uncompressed original bytes**, use the `useOriginalFile` option:

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    useOriginalFile: true, // 💎 Ensures no OS-level compression
  ),
);
```

### 🚫 Disabling the Live Camera Tile

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

### 👆 Disabling Swipe-To-Select

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

### 📤 Handling Selected Media (Upload Example)

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

### 🎨 UI Theming & Customization

`gallery_suite` is built to seamlessly blend into your app's existing design system. You can easily switch between Light and Dark modes, or enforce a specific brand color.

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    // Enforce dark mode regardless of system settings
    brightness: Brightness.dark,

    // Set your brand's primary color for buttons, badges, and checkmarks
    primaryColor: const Color(0xFFE91E63), // Pink

    // Customize the button labels
    confirmText: 'Envoyer',
    cancelText: 'Retour',
  ),
);
```

---

## ⚙️ PickerConfig API

The entire look and feel is controlled via `PickerConfig`. Here is exactly what you can configure:

| Parameter              | Type          | Default             | Description                                                                                                                                                       |
| ---------------------- | ------------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `requestType`          | `RequestType` | `RequestType.image` | The specific gallery to open (`image`, `video`, or `audio`).                                                                                                      |
| `maxSelection`         | `int`         | `10`                | The maximum number of assets the user can select. Used in Images and Audio. Video is currently single-select.                                                     |
| `primaryColor`         | `Color`       | `Color(0xFF007AFF)` | The global accent color for checkmarks, badges, seek-bars, and confirm buttons.                                                                                   |
| `brightness`           | `Brightness?` | `null`              | Force a specific theme (`Brightness.dark` or `light`). If `null`, it automatically follows the system `Theme.of(context)`.                                        |
| `confirmText`          | `String`      | `'Sélectionner'`    | Localized text for the final send/done button.                                                                                                                    |
| `cancelText`           | `String`      | `'Annuler'`         | Localized text for the cancel button in the app bar.                                                                                                              |
| `showCameraTile`       | `bool`        | `true`              | When `true`, renders a live `camera` feed at index `0`. Supports both photo and video depending on `requestType`. Tap to open a full-screen Dribbble-inspired UI. |
| `enableSwipeToSelect`  | `bool`        | `true`              | When `true`, allows the user to long-press and drag their finger across the masonry grid to rapidly select items (iOS Photos style). Includes edge auto-scroll.   |
| `useOriginalFile`      | `bool`        | `false`             | When `true`, fetches the absolute pristine original file rather than a system-optimized/compressed format from iOS or Android cache.                              |
| `thumbnailCacheSize`   | `int`         | `200`               | Maximum number of thumbnails kept in the LRU memory cache. A value of 200 ensures buttery scrolling over 2–3 screens of content.                                  |
| `maxConcurrentDecodes` | `int`         | `3`                 | Maximum simultaneous thumbnail decodes. Limiting this ensures scrolling remains 60fps+ by preventing thread starvation on large grids.                            |
| `prefetchEnabled`      | `bool`        | `true`              | When `true`, the picker intelligently pre-loads thumbnails for the next 30 items that are about to appear on-screen during scrolling, eliminating pop-in.         |

---

## ⚡ Performance Notes

- **Intelligent Pre-fetching**: Tiles load before they even enter the screen `(viewport + 30 items)` via `MediaService.prefetchThumbnails`.
- **Concurrency Throttling**: A custom `ThumbnailDecodeQueue` ensures that no more than 3 high-resolution thumbnails decode simultaneously, preserving frame budgets on 120Hz ProMotion displays.
- **LRU Cache & Memory Management**: Decoded thumbnails are held in a global `LinkedHashMap<String, Uint8List>` capped at `thumbnailCacheSize` (default: 200) and 50MB. Older images are automatically evicted to prevent OOM errors on 10,000+ asset libraries.
- **Optimized UI Layer**: Each grid tile is wrapped in `RepaintBoundary`. The pulsing animation controllers are completely stopped once an image loads to save GPU processing.
- Pagination automatically adapts: loading 80 assets initially, then 120 per page, triggering aggressively at 1500px from the bottom.

---

## 🚀 Version History & Roadmap

We use [Semantic Versioning](https://semver.org/). This package is currently evolving rapidly:

| Version    | Status    | Highlights                                                                                                                                            |
| ---------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **v1.0.0** | ✅ Stable | Core engine (Grid, Video, Audio), Live Camera Tile, iOS-style swipe-to-select, Heavy Performance Optimizations (LRU Cache, Decode Queue, Prefetching) |
| **v1.1.0** | ✅ Stable | Injectable Bring Your Own Editor (BYOE) Architecture, Dart-side Inline Media Filtering / Search engine                                                |

---

## 📜 License

Apache 2.0 — see [LICENSE](LICENSE).

---

## ❤️ Acknowledgements & Credits

`gallery_suite` stands on the shoulders of giants. This package would not exist without the incredible work of the following open-source contributors:

- **[photo_manager](https://pub.dev/packages/photo_manager)** — The high-performance engine powering our native media library access.
- **[flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view)** — Responsible for the beautiful and fluid Masonry layout of our grids.
- **[video_player](https://pub.dev/packages/video_player)** — Enabling our seamless, zero-latency inline video previews.
- **[just_audio](https://pub.dev/packages/just_audio)** — The backbone of our integrated audio playback experience.
- **[camera](https://pub.dev/packages/camera)** — Allowing us to build a premium, fully-integrated live camera capture experience into the grid.

Thank you to the Flutter community for building the "bricks" that allowed us to create this "house". 🏠✨
