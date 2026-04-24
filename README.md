<p align="center">
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/branding_banner.png" alt="Gallery Suite Branding Banner" width="100%" />
</p>

<h1 align="center">gallery_suite</h1>

<p align="center">
  <a href="https://github.com/Hawks124/gallery_suite/actions/workflows/ci.yml"><img src="https://github.com/Hawks124/gallery_suite/actions/workflows/ci.yml/badge.svg" alt="CI/CD Status"></a>
  <a href="https://github.com/Hawks124/gallery_suite/actions/workflows/build.yml"><img src="https://github.com/Hawks124/gallery_suite/actions/workflows/build.yml/badge.svg" alt="Build Status"></a>
  <a href="https://pub.dev/packages/gallery_suite"><img src="https://img.shields.io/pub/v/gallery_suite.svg" alt="pub.dev"></a>
  <a href="https://pub.dev"><img src="https://img.shields.io/pub/points/gallery_suite?color=blue&label=pub%20points" alt="pub points"></a>
  <a href="https://pub.dev"><img src="https://img.shields.io/pub/likes/gallery_suite?logo=flutter" alt="likes"></a>
  <a href="https://github.com/Hawks124/gallery_suite/stargazers"><img src="https://img.shields.io/github/stars/Hawks124/gallery_suite?style=social" alt="stars"></a>
  <a href="https://pub.dev/publishers/RiRi"><img src="https://img.shields.io/pub/publisher/gallery_suite.svg" alt="publisher"></a>
  <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10%2B-blue.svg" alt="Flutter"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg" alt="Platform"></a>
  <a href="https://pub.dev/packages/flutter_lints"><img src="https://img.shields.io/badge/style-flutter__lints-blue" alt="Style"></a>
  <a href="https://github.com/Hawks124/gallery_suite/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

**Gallery Suite** is the ultimate media picker for Flutter, featuring a native **Google Photos Cloud Provider** built directly into the UI. It replaces restrictive OS dialogs with a fully customizable, 120fps masonry grid that seamlessly mixes local device files with cloud assets. Ship premium features out-of-the-box like iOS-style swipe-to-select, Bring Your Own Editor (BYOE) architecture, inline video/audio playback, and glassmorphic micro-animations.

<p align="center">
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/demo.gif" width="100%" alt="Gallery Suite UI Demo Animations" />
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_image_picker.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_video_preview.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_audio_picker.png" width="24%" />
  <img src="https://raw.githubusercontent.com/Hawks124/gallery_suite/main/example/assets/screenshot_theme_dark.png" width="24%" />
</p>

---

## 🤔 Why Gallery Suite?

The official `image_picker` is a fantastic tool that delegates to the operating system's native media browser. This is perfect for basic needs, but it means the UI is entirely controlled by the OS (looking different on every device and rarely matching your app's branding).

`gallery_suite` takes a different approach: it builds the entire picker _inside_ Flutter. This guarantees a consistent, premium visual experience across all devices and enables rich in-app interactions (like inline video playback and audio previews) before the user even confirms their selection.

Furthermore, `gallery_suite` is one of the **only major pickers** that ships with a native **Cloud Provider architecture** out of the box. Users can seamlessly browse, zoom, and select their Google Photos directly alongside their local device photos in one beautiful, unified grid, without needing to download them first.

### 🚀 Zero Bloatware & Extreme Performance

Unlike other pickers that force you to download massive editor dependencies or bloated video trimmers, `gallery_suite` keeps its core **100% pristine and lightweight**.

- **120fps Ready**: Powered by a custom `ThumbnailDecodeQueue` and LRU memory caching, the grid stays buttery smooth even when rapidly scrolling through 10,000+ assets.
- **Architecture by Injection**: We provide elegant, decoupled hooks. Want to crop an image? Pass your favorite editor to our `onEditMedia` callback. Our UI seamlessly integrates it without adding a single megabyte to the package's core footprint.

**Compared to similar packages:**

| Feature             | `image_picker`    | `wechat_assets_picker` | `gallery_suite`                     |
| ------------------- | ----------------- | ---------------------- | ----------------------------------- |
| Platforms Supported | All               | iOS, Android, macOS    | ✅ All (Mobile, Web, Desktop)       |
| Assets supported    | Image, Video      | Image, Video, Audio    | Image, Video, Audio                 |
| Picker UI           | Native OS dialog  | WeChat-style grid      | Custom Masonry grid                 |
| Audio/Video         | System default    | Custom                 | Inline playback (Mini-player)       |
| Multi-select        | Images only       | Yes                    | Yes (Images & Video & Audio)        |
| In-app Camera       | No                | Via add-on package     | ✅ Yes (Live tile & Custom UI)      |
| Swipe-To-Select     | No                | No                     | ✅ Yes (iOS Photos style)           |
| Inline Search       | No                | No                     | ✅ Yes (Cross-platform Dart filter) |
| BYOE Image Editing  | No                | No                     | ✅ Yes (Dependency Injection)       |
| Cloud Providers     | No                | No                     | ✅ Yes (Google & iCloud Built-in)   |
| UI Feedback         | No                | No                     | ✅ Yes (Cloud Status Badges)        |
| UI Theming          | System restricted | Custom                 | Fully customizable per-instance     |

> **❤️ A note on Open Source:** `gallery_suite` is proudly powered by the incredible `photo_manager` engine (created by the brilliant authors of `wechat_assets_picker`). While their picker perfectly replicates the WeChat experience, `gallery_suite` focuses on an alternative iOS-inspired masonry design with zero-dependency features like BYOE editing and Glassmorphism.

---

## 📱 Platform Compatibility & Status (Google Photos)

The Google Photos integration relies on different underlying OAuth2 logic depending on platform constraints (like Android's Credential Manager limits vs Web's FedCM updates):

| Platform            | Status             | Engine Used                 | Notes                                                                                                                                   |
| :------------------ | :----------------- | :-------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **Android**         | ✅ Fully Supported | `flutter_web_auth_2` (PKCE) | Uses Chrome Custom Tabs to bypass Android 14 Credential Manager scope restrictions.                                                     |
| **iOS**             | ✅ Fully Supported | `google_sign_in`            | Uses standard AppAuth native implementation. No known issues with inline video playback.                                                |
| **Web**             | ✅ Fully Supported | `google_sign_in_web`        | Successfully patched for strict browser CORS & FedCM. Utilizes custom raw HTTP bridging for `<video>` tags.                             |
| **macOS**           | ⚠️ Experimental    | `google_sign_in_macos`      | Theoretical support; requires enabling macOS support in GCP and linking the macOS Google Sign-In backend.                               |
| **Windows / Linux** | ⚠️ Experimental    | `flutter_web_auth_2` (PKCE) | Uses local-loopback OAuth servers. You must ensure your redirect URI is mapped to `http://localhost:<port>` rather than custom schemes. |

---

## ✨ Features

**Image Picker**

- 📸 **Built-in Native Camera** — live preview tile directly in the grid at position 0. Full custom `CameraScreen` with flash, flip, and recording support. Can be disabled via `showCameraTile: false`.
- 👆 **iOS-style Swipe-To-Select** — long press and drag your finger to rapidly select multiple images in one fluid motion. Includes intelligent auto-scrolling near screen edges. Can be disabled via `enableSwipeToSelect: false`.
- 🖱️ **Drag & Drop Reordering** — Long-press any selected image in the bottom preview strip to drag and drop it! This instantly updates the final order of selection and automatically re-syncs the numeric grid badges. Features a beautiful glassmorphic scale/shadow animation while dragging.
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

**Cloud Integration**

- ☁️ **Google Photos Built-in Provider** — Natively browse, select, and organize Google Photos directly within the Masonry grid. Mixes seamlessly with local device assets.
- 💾 **Persistent Sessions** — Your Google Photos login and imported assets survive app restarts and hot reloads thanks to a zero-dependency local persistence layer.
- 🔄 **Intelligent Auto-Refresh** — Background token exchange handles OAuth2 expiry silently, ensuring a frictionless user experience.
- 🔐 **Secure Sign-Out** — Disconnect your account anytime via the Album sheet with a beautiful confirmation dialog and loading overlay.
- 🌉 **Automatic Cloud Bridge** — The `MediaItem.file` getter automatically detects and downloads cloud assets to a local cache for instant processing.
- ☁️ **Native iCloud Support** — Transparently browse iCloud photos with glassmorphic status badges for assets being fetched from the cloud.

**All Pickers**

- 💻 **Web & Desktop Optimization** — Fully supported across Web, Windows, macOS, and Linux via a polymorphic `MediaSource` engine. Features native Drag-and-Drop OS file uploads, intelligent `LayoutBuilder` responsive grid expansion, and `Ctrl+A`/`Cmd+A` keyboard shortcuts.
- 🔍 **Inline Asset Search** — Instantly filter your entire media library by filename/title with a beautiful iOS-style frosted search bar. Uses lightning-fast Dart-side memory filtering.
- 🔄 **Pre-Selected Media (Initial Selection)** — Seamlessly re-open the picker with previously selected items already checked by passing a list of `MediaItem`s to `initialSelection`. The grid intelligent auto-maps them by ID.
- 📋 **Smart Clipboard Integration** — Automatically decodes copied images, file paths, and media URLs from the system clipboard into seamlessly selectable grid assets (Opt-in via `enableSmartClipboard`). Works 100% offline for local screenshots!
- 🦸‍♂️ **"Hero" Animations** — Seamless `Hero` flying transitions between the grid thumbnails and full-screen previews for that Dribbble-level UX feeling!
- 🪄 **Auto-Conversion HEIC to JPG** (Experimental) — Background converter to natively transform iOS HEIC/HEVC photos to standard JPG before returning the file (using native iOS bridges), avoiding cross-platform rendering crashes.
- 🖌️ **Bring Your Own Editor (BYOE) Architecture** — Why bloat your app with forced editors? Pass your favorite editor (like `pro_image_editor`) to the `onEditMedia` callback. The picker natively intercepts the edit, displays an elegant Pencil action in the Fullscreen Preview, and flawlessly updates the preview strip to the new edited image.
- 🌍 **Zero-Dependency Internationalization (Intl)** — Translate 100% of the UI (buttons, search bar, empty states) without installing heavy `intl` packages. Uses a clean `PickerTextDelegate` pattern.
- 🔒 **Exit Confirmation Prevention** — Built-in `PopScope` protection. If a user tries to swipe back or press the Android back button after spending time selecting/editing photos, a beautiful Glassmorphic dialog prevents accidental data loss.
- Fully customizable theming via `PickerConfig.brightness` and `primaryColor`.
- Haptic feedback and native-feeling micro-animations and _Glassmorphism_.
- Smooth skeleton loaders and optimized pagination (80 items per page).

---

## 📑 Table of Contents

- [🤔 Why Gallery Suite?](#-why-gallery-suite)
- [📱 Platform Compatibility & Status (Google Photos)](#-platform-compatibility--status-google-photos)
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
  - [☁️ Google Photos Built-in Provider (Premium Cloud Integration)](#️-google-photos-built-in-provider-premium-cloud-integration)
    - [Authentication & 2026 Compliance (Picker API)](#authentication--2026-compliance-picker-api)
    - [Quick Start: Global Initialization](#quick-start-global-initialization)
    - [🛠️ Google Cloud Platform (GCP) Setup Guide](#️-google-cloud-platform-gcp-setup-guide)
  - [🖌️ Bring Your Own Editor (BYOE) Architecture](#️-bring-your-own-editor-byoe-architecture)
  - [📋 Smart Clipboard Integration](#-smart-clipboard-integration)
  - [🔒 Exit Confirmation](#-exit-confirmation-accidental-exit-prevention)
  - [🌍 Internationalization (Intl)](#-internationalization-intl)
  - [🔄 Pre-Selected Media (Initial Selection)](#-pre-selected-media-initial-selection)
  - [📸 Getting Original Quality Files](#-getting-original-quality-files)
  - [🚫 Disabling the Live Camera Tile](#-disabling-the-live-camera-tile)
  - [👆 Disabling Swipe-To-Select](#-disabling-swipe-to-select)
  - [📤 Handling Selected Media (Upload Example)](#-handling-selected-media-upload-example)
  - [🎨 UI Theming & Customization](#-ui-theming--customization)
    - [PickerThemeData Tokens](#pickerthemedata-tokens)
- [⚙️ PickerConfig API](#️-pickerconfig-api)
- [⚡ Performance Notes](#-performance-notes)
- [🚀 Version History & Roadmap](#-version-history--roadmap)
- [🌟 Support the Project](#-support-the-project)
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

Because this package accesses the device's native media library, **you must configure native permissions before using it.** It will crash or show a "Permission Denied" screen if you skip this step. Also, you need to add the Google Photos Picker Redirect Handler and Gradle Configuration to your Android project if you want to use the Google Photos picker feature. Follow the steps below to configure the package.

### Android Setup

_(Supports API 21+)_

#### ⚠️ Project Requirements

Ensure your `android/app/build.gradle` (or `build.gradle.kts`) meets these minimums:

- **compileSdk**: 33+ (Required for Android 13 media permissions)
- **minSdk**: 21+
- **Kotlin Version**: 1.9.0+

Inside `android/app/src/main/AndroidManifest.xml` `<manifest>` block:

> [!TIP]
> **Manifest Merger Error?** If you encounter a build error about `WRITE_EXTERNAL_STORAGE` conflicts with `camera_android_camerax` on Android 13+, add `xmlns:tools="http://schemas.android.com/tools"` to your `<manifest>` tag, and `tools:replace="android:maxSdkVersion"` as shown below.

```xml
<manifest xmlns:tools="http://schemas.android.com/tools" ...>

<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Required for the built-in camera tile -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Android 9 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"
    tools:replace="android:maxSdkVersion" />
```

#### 🔐 Google Photos Picker Redirect Handler (Required for Google Photos Picker)

You must add the following activity to your `AndroidManifest.xml` file (Note: This is required for the Google Photos picker to work):

```xml
<application ...>
    <!-- Google Photos Picker Redirect Handler (Required) -->
    <activity
        android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
        android:exported="true">
        <intent-filter android:label="flutter_web_auth_2_callback">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="${oauth_scheme}" />
        </intent-filter>
    </activity>
</application>
```

#### 🐘 Gradle Configuration (Required for Google Photos Picker)

You must pass your Google Client ID scheme to the manifest via `manifestPlaceholders`.

**If using `build.gradle.kts` (Kotlin):**

```kotlin
android {
    defaultConfig {
        manifestPlaceholders["oauth_scheme"] = "com.googleusercontent.apps.YOUR_CLIENT_ID"
    }
}
```

**If using `build.gradle` (Groovy):**

```groovy
android {
    defaultConfig {
        manifestPlaceholders = [oauth_scheme: "com.googleusercontent.apps.YOUR_CLIENT_ID"]
    }
}
```

#### 📁 FileProvider Configuration (Required for Android Camera & Smart Clipboard)

Add the following provider inside the `<application>` block of your `AndroidManifest.xml`:

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

#### That's it for Android ✔

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

<!-- Required for Google Photos Auth Redirect -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>

<!-- Helpful for just_audio background compatibility -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

#### That's it for iOS ✔

### macOS Setup

_(Supports macOS 10.15+)_

macOS development requires adjusting the App Sandbox and linking the Google Sign-in framework if using the cloud features.

**1. Expand App Sandbox (Required for File Picking):**
Inside `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`, add:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

**2. Google Photos Auth Redirect:**
If you enabled Google Photos, add your URL scheme to `macos/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Web Setup

Zero native configuration required! However, if you are using the **Google Photos feature**, you must:

1. Ensure your Web App is served via `localhost` during development.
2. Add your deployment URL (e.g., `https://myapp.com`) to the **Authorized JavaScript origins** in your Google Cloud Console.
3. Configure your HTTP headers to support cross-origin isolation if deploying heavy WebGL, though `gallery_suite` works out of the box with standard CORS.

### Windows & Linux Setup

No advanced setup layer is required for local file picking. `gallery_suite` seamlessly integrates the OS native Explorer/Nautilus dialogs.
If using Google Photos on Desktop, ensure you register an OAuth 2.0 Client ID for **Desktop/Web** on Google Cloud Console and handle the local loopback server generated by `flutter_web_auth_2`.

---

## 💻 Core Usage

First, import the package and `photo_manager` (which provides the `RequestType` enum):

```dart
import 'package:gallery_suite/gallery_suite.dart';
import 'package:photo_manager/photo_manager.dart';
```

### 📸 Pick Images

```dart
// Full-featured: Camera tile + Swipe-to-select + Multi-select + Google Photos
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.image,
    maxSelection: 10,
    showCameraTile: true,        // Live camera feed at index 0
    enableSwipeToSelect: true,   // iOS-style drag to select
    primaryColor: Colors.deepPurple,
    googlePhotosConfig: const GooglePhotosConfig(enabled: true), // Enable Cloud by default!
    textDelegate: const EnglishPickerTextDelegate(), // Customize labels
    onEditMedia: (context, asset, file) async {
       // Launch your favorite editor (e.g., pro_image_editor)
       // return await MyEditor.open(file);
       // See example in the example folder
       return null;
    },
  ),
);
```

### 🎬 Pick a Video

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    requestType: RequestType.video,
    maxSelection: 1,             // Set to > 1 to enable Multi-Video Select!
    showCameraTile: true,        // Camera tile records video in this mode
  ),
);
```

> [!TIP]
> **Multi-Video Select:** By default, tapping a video opens the `VideoPreviewSheet`. If you set `maxSelection > 1`, hitting "Confirm" from the preview will add it to a selected timeline strip at the bottom of the screen. Users can also select multiple videos via the selection tick.

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

### ☁️ Google Photos Built-in Provider (Premium Cloud Integration)

`gallery_suite` comes with a powerful **First-Class Cloud Provider** built natively into the UI. Instead of forcing users to download their cloud photos to the device before picking them, the picker allows users to seamlessly browse, select, zoom, and reorganize **Google Photos directly within the Masonry grid**, mixed natively with local files.

The picker returns a polymorphic `MediaItem` array that correctly abstracts local paths (`AssetEntity`) from cloud metadata (`RemotePickerAsset`).

#### Authentication & 2026 Compliance (Picker API)

In **March 2025**, Google heavily restricted direct access to the Google Photos library. To comply with these new privacy standards without requiring a complex, expensive Tier-2 security audit, `gallery_suite` seamlessly integrates the modern **Google Photos Picker API**.

#### Quick Start: Global Initialization

Because the modern Picker API requires a secure OAuth2 PKCE(Proof Key for Code Exchange) flow (to bypass Firebase restrictions and ensure platform independence), you **must initialize the service once** at app startup with your GCP credentials:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gallery_suite/gallery_suite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pick the right Client ID based on the Platform
  String clientId = '';
  String redirectScheme = '';

  if (kIsWeb) {
    clientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  } else if (Platform.isIOS || Platform.isMacOS) {
    clientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
    redirectScheme = 'com.googleusercontent.apps.YOUR_IOS_CLIENT_ID';
  } else if (Platform.isAndroid) {
    clientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'; // Android uses Web Client ID for PKCE
    redirectScheme = 'com.googleusercontent.apps.YOUR_WEB_CLIENT_ID';
  }

  // Initialize the Google Photos Service globally
  GooglePhotosService.instance.init(
    clientId: clientId,
    redirectScheme: redirectScheme,
    apiKey: 'YOUR_GOOGLE_CLOUD_API_KEY', // Required for Picker API routing
  );

  runApp(const MyApp());
}
```

#### Opening the Picker

Then, simply ensure the Google Photos feature is enabled when opening the picker. The "☁️ Google Photos" tab will automatically appear in the UI:

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: const PickerConfig(
    googlePhotosConfig: GooglePhotosConfig(enabled: true),
  ),
);
```

#### 💾 Zero-Dependency Disk Persistence

The Google Photos integration includes a **lightweight, native persistence layer** built entirely with `path_provider` and `dart:io`. This means:

- **Session Survival**: Your OAuth2 tokens (`access_token`, `refresh_token`) and imported cloud assets are saved to local JSON files. Users stay logged in across hot restarts and app closures.
- **Intelligent Auto-Refresh**: When tokens expire, the service silently exchanges the `refresh_token` in the background — users never see a re-login screen.
- **No Heavy Dependencies**: No Riverpod, no Bloc, no Hive. The entire state is managed with native `ValueNotifier`s and atomic file I/O.

#### 🔐 Secure Sign-Out

Users can disconnect their Google account directly from the Album Selector sheet. The sign-out flow includes:

1. A **confirmation dialog** (reusing the premium `StandardExitConfirmation` design) warning users that their imported photos will become invisible.
2. A **loading overlay** while the session is being cleaned.
3. **Full cleanup**: local JSON files are deleted, tokens are cleared, and the UI automatically returns to the local device gallery.

#### 🚀 Smart Cloud Downloads (Automatic Bridging)

One of the most powerful features of `gallery_suite` is the **Automatic Bridge**. Most Flutter apps (and native plugins) expect a local `File` path to display or upload images. However, Google Photos items are essentially remote URLs.

`gallery_suite` solves this by making the `MediaItem.file` getter intelligent. When your application calls `await item.file`:

1. If the asset is **local**, it returns the file from the device gallery.
2. If the asset is **remote**, the picker **automatically downloads** it to a temporary local cache using authenticated headers and returns a `File` object.

**This means your existing code "just works" with cloud assets:**

```dart
for (final item in assets) {
  // Automatically downloads if it's from Google Photos!
  final File? file = await item.file;
  if (file != null) {
     // Upload to Firebase, Supabase, or display via Image.file()
  }
}
```

### ☁️ Native iCloud Support (iOS)

`gallery_suite` provides **Zero-Config iCloud Integration**. Because it leverages the native iOS photo library via the `photo_manager` engine, iCloud photos are seamlessly merged into the main masonry grid without any extra setup.

- **Automated UI Feedback**: For assets stored only in the cloud, the picker automatically displays a subtle, glassmorphic **Cloud badge**.
- **Transparent Downloading**: When an iCloud-only asset is selected, the operating system handles the download progress natively, and the picker provides the local `File` once it's ready.
- **No API Keys Required**: Unlike Google Photos, iCloud support is 100% native and requires only the standard `NSPhotoLibraryUsageDescription` in your `Info.plist`.

---

### 🛠️ Google Cloud Platform (GCP) Setup Guide

Whether you use Firebase or not, you **must enable the Google Photos Picker API** in your GCP Console for the popup authentication to work.

We have prepared a dedicated **[Comprehensive GCP Setup Guide](https://github.com/Hawks124/gallery_suite/blob/main/gcp_setup_guide.md)**. This guide outlines the exact, updated steps to:

1. Configure the new **Google Auth Platform** (Branding, Audience, Data Access).
2. Generate your PKCE OAuth Client IDs.
3. Understand the differences between the modern **Picker API** (free & immediate) and the legacy **Library API** (requires expensive CASA Tier-2 Verification).

### 🖌️ Bring Your Own Editor (BYOE) Architecture

Why force your users to download a bloated media picker that comes packed with heavy image editing dependencies they don't even use?

`gallery_suite` introduces a pristine **Dependency Injection** architecture for media editing. Tap the image thumbnail to open the **Fullscreen Preview**, then tap the pencil icon in the top right to open your own custom editor (like `pro_image_editor` or `image_editor_plus`). The picker smoothly transitions the preview to the new local file while maintaining a 100% lightweight package size.
The picker will automatically:

1. Display an **Edit Pencil icon** in the top-right corner of the Fullscreen Preview for selected images.
2. Wait for your custom editor to pop the new file.
3. Replace the preview thumbnail with the edited version, keeping the original intact in the OS gallery.

#### Example: Integrating `pro_image_editor`

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    // ...
    onEditMedia: (ctx, asset, file) async {
      // Only allow editing for images
      if (asset.type != AssetType.image) return null;

      // 1. A Completer handles the async flow since ProImageEditor uses callbacks
      final completer = Completer<File?>();

      // 2. Push your favorite editor route
      await Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (editorCtx) => ProImageEditor.file(
            file,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (bytes) async {
                // Save edited bytes to a temp file
                final tempDir = Directory.systemTemp.path;
                final newFile = File('$tempDir/edited.jpg');
                await newFile.writeAsBytes(bytes);

                // Complete the future
                if (!completer.isCompleted) completer.complete(newFile);

                // Explicitly pop the editor! ProImageEditor does NOT pop itself.
                if (editorCtx.mounted) Navigator.of(editorCtx).pop();
              },
              onCloseEditor: (_) {
                // User cancelled editing
                if (!completer.isCompleted) completer.complete(null);

                // Explicitly pop the editor!
                if (editorCtx.mounted) Navigator.of(editorCtx).pop();
              },
            ),
          ),
        ),
      );

      // 3. Return the edited file precisely once the editor completely closes
      if (completer.isCompleted) return completer.future;
      return null;
    },
  ),
);
```

### 📋 Smart Clipboard Integration

A highly demanded feature for modern chat and post creation apps is the ability to paste media directly from the OS clipboard. `gallery_suite` provides a built-in, native **Smart Clipboard Integration** that handles the heavy lifting of sniffing MIME types, downloading URLs, and extracting raw image byte streams safely.

To enable this, pass `enableSmartClipboard: true` in your config:

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: const PickerConfig(
    enableSmartClipboard: true, // Turns on the magic
  ),
);
```

#### How it works:

1. When enabled, a "Clipboard" tile appears in the `AlbumSelectorSheet` (and an AppBar icon in Audio mode).
2. Tapping it performs a triple-fallback scan:
   - **Text URLs**: Scans the clipboard for direct image/video/audio links and mounts them as `RemotePickerAsset`s.
   - **Files**: Detects copied file paths and decodes their metadata into `FilePickerAsset`s.
   - **Raw Bytes**: Safely pulls raw image bytes (e.g. from an iOS screenshot copy or Web copy), flushes them to a temporary file via `path_provider` to prevent RAM OOM errors, and mounts them.
3. The pasted items are displayed uniformly inside the Masonry Layout grid!

> [!NOTE]
> **Android Setup:** The Smart Clipboard heavily relies on the `Pasteboard` package to extract Raw Bytes. This requires the **FileProvider Configuration** documented in the [Installation & Setup](#-installation--setup) section.

> [!NOTE]
> **Offline by Default:** The Smart Clipboard requires **NO** internet connection. It perfectly decodes your local iOS/Android screenshots and copied local files totally offline. The only exception is when you copy an external `http` URL (like `https://imgbb.com/photo.jpg`), in which case a light `HTTP GET` probe is made to securely detect the MIME type.

### 🪄 Auto-Conversion HEIC to JPG (Experimental)

High-Efficiency Image formats (HEIC/HEVC) are the default on modern iOS devices. Unfortunately, pushing HEIC files to legacy Android databases, Web SDKs, or standard Server CDNs often results in corrupted renders or crashes.

`gallery_suite` provides a built-in safety net: it intercepts HEIC photos and transparently auto-converts them to universally supported JPGs in the background BEFORE returning them!

Because this utilizes deep native iOS bridges (`flutter_image_compress`), we have gracefully wrapped it in defensive fallbacks.
> [!WARNING]
> This feature is proudly **Experimental** and actively looking for community contributions! Native conversion heavily relies on real, physical iOS devices capturing deep hardware-encoded HEIC files to perfectly test. If the native conversion crashes on an unsupported device, it gracefully aborts and returns the original HEIC file to prevent app bricking.

### 🔒 Exit Confirmation (Accidental Exit Prevention)

Prevent accidental data loss! When users select or edit images, tapping the android back button or swiping to pop can accidentally discard their hard work. You can solve this by providing an `ExitConfirmationConfig`.

To use the beautiful, built-in premium dialog:

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    exitConfirmation: const StandardExitConfirmation(
      title: 'Discard selections?',
      content: 'If you go back now, your current selections will be lost.',
      confirmText: 'Discard',
      cancelText: 'Cancel',
    ),
    // ...
  ),
);
```

Or build your own 100% custom UI by passing `CustomExitConfirmation(showDialog: (context) async { ... })`.

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    exitConfirmation: CustomExitConfirmation(
      showDialog: (context) async {
        // Return `true` if the user confirms they want to exit,
        // or `false` to keep the picker open.
        return await showMyCustomAlert(context);
      },
    ),
  ),
);
```

---

### 🌍 Internationalization (Intl)

`gallery_suite` uses a zero-dependency **Text Delegate** pattern. This means you don't need to bloat your `pubspec.yaml` with ARB files or the `intl` package.

By default, the package uses `EnglishPickerTextDelegate`. We also include `FrenchPickerTextDelegate` out-of-the-box.

**Using a built-in language:**

```dart
final assets = await CustomMediaPicker.show(
  context: context,
  config: PickerConfig(
    textDelegate: const FrenchPickerTextDelegate(),
  ),
);
```

**Overriding specific words:**
Want to use French but change the confirm button from "Sélectionner" to "Envoyer"? Easy!

```dart
config: PickerConfig(
  textDelegate: const FrenchPickerTextDelegate(
    confirm: 'Envoyer',
  ),
)
```

**Supporting your own app's translation engine (GetX, EasyLocalization, etc.):**
Extend `PickerTextDelegate` with a custom class that pulls from your translation layer:

```dart
// Create a custom delegate class
class MyAppTextDelegate extends EnglishPickerTextDelegate {
  const MyAppTextDelegate();

  @override
  String get confirm => MyApp.t('confirm_btn');

  @override
  String get cancel => MyApp.t('cancel_btn');

  @override
  String get albums => MyApp.t('albums_label');
}

// Then pass it to PickerConfig
config: PickerConfig(
  textDelegate: const MyAppTextDelegate(),
)
```

### 🔄 Pre-Selected Media (Initial Selection / Drafts)

When building features like "Edit Post" or "Add to existing Album", you often need to open the picker with previously selected items already checked. To achieve this, simply maintain a `List<MediaItem>` in your widget's state and pass it directly to `PickerConfig.initialSelection`. The picker will automatically map these items back to the grid and pre-check them!

Here is the recommended architecture pattern for maintaining, passing, and clearing a media draft:

```dart
class MyChatInputState extends State<MyChatInput> {
  // 1. Maintain a local draft state
  List<MediaItem> _draftImageSelection = [];
  // List<MediaItem> _draftVideoSelection = [];
  // List<MediaItem> _draftAudioSelection = [];

  Future<void> _openGallery() async {
    // 2. Open the picker and pass your draft to `initialSelection`
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.image,
        maxSelection: 10,
        initialSelection: _draftImageSelection, // The grid will auto-check these items!
      ),
    );

    // 3. If canceled natively, do nothing (keep draft intact)
    if (assets == null || assets.isEmpty) return;

    // 4. Update draft state with the new selection from the gallery
    setState(() {
      _draftImageSelection = List.from(assets);
    });
  }

  Future<void> _submitToServer() async {
    if (_draftImageSelection.isEmpty) return;

    // ... Handle your actual file uploads ...

    // 5. Clear the draft once the items are permanently sent(Optional)!
    setState(() {
      _draftImageSelection.clear();
    });
  }
}
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

    // Advanced: Deep override of every surface/text token
    themeData: const PickerThemeData(
      background: Color(0xFF0A0A1A),     // Deep cinematic background
      surface: Color(0xFF12122A),        // Cards and sheets
      elevated: Color(0xFF1E1E3A),       // Elevated buttons/tiles
      primaryText: Colors.white,         // Titles
      secondaryText: Color(0xFF8888BB),  // Subtitles and captions
      separator: Color(0xFF222244),      // Thin lines
      divider: Color(0xFF2A2A5A),        // Visual break lines
      shimmerBase: Color(0xFF12122A),    // Skeleton loader back
      shimmerHighlight: Color(0xFF1E1E3A), // Skeleton loader flash
    ),

    // Customize the button labels
    confirmText: 'Envoyer',
    cancelText: 'Retour',
  ),
);
```

#### `PickerThemeData` Tokens

For maximum design flexibility, you can override any of these specific tokens:

| Token              | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `background`       | The overall page background color.                                      |
| `surface`          | Background for sheets (Albums) and grid items.                          |
| `elevated`         | Background for circular buttons (Close, Play) and highlighted states.   |
| `primaryText`      | Main font color for titles and selections.                              |
| `secondaryText`    | Muted font color for counts, durations, and empty states.               |
| `separator`        | Color for 0.5px thin borders and lines.                                 |
| `divider`          | Color for larger section breaks.                                        |
| `shimmerBase`      | The background color of the skeleton loader while images are streaming. |
| `shimmerHighlight` | The "flash" animation color of the skeleton loader.                     |

---

## ⚙️ PickerConfig API

The entire look and feel is controlled via `PickerConfig`. Here is exactly what you can configure:

| Parameter              | Type                      | Default                     | Description                                                                                                                                                                                               |
| ---------------------- | ------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `requestType`          | `RequestType`             | `RequestType.image`         | The specific gallery to open (`image`, `video`, or `audio`).                                                                                                                                              |
| `maxSelection`         | `int`                     | `10`                        | The maximum number of assets the user can select. Used in Images and Audio. Video is currently single-select.                                                                                             |
| `primaryColor`         | `Color`                   | `Color(0xFF007AFF)`         | The global accent color for checkmarks, badges, seek-bars, and confirm buttons.                                                                                                                           |
| `brightness`           | `Brightness?`             | `null`                      | Force a specific theme (`Brightness.dark` or `light`). If `null`, it automatically follows the system `Theme.of(context)`.                                                                                |
| `textDelegate`         | `PickerTextDelegate`      | `EnglishPickerTextDelegate` | Handles 100% of the localized strings (buttons, search, empty states) with zero external dependencies.                                                                                                    |
| `initialSelection`     | `List<MediaItem>?`        | `null`                      | An optional list of previously selected media items. The picker dynamically maps them to the grid assets by ID to restore a prior selection state. [See docs](#-pre-selected-media-initial-selection)     |
| `enableSmartClipboard` | `bool`                    | `false`                     | An optional flag to enable the Smart Clipboard integration. Appends a clipboard icon to scan system-level URLs, media paths, or raw copied bytes into the grid. [See docs](#-smart-clipboard-integration) |
| `onEditMedia`          | `Function?`               | `null`                      | Optional callback to launch a custom external image editor (e.g. `pro_image_editor`) directly from the Fullscreen Preview. [See docs](#️-bring-your-own-editor-byoe-architecture)                          |
| `googlePhotosConfig`   | `GooglePhotosConfig`      | `default`                   | Configuration for the built-in Google Photos cloud provider (enabled/disabled and other cloud-specific options).                                                                                          |
| `exitConfirmation`     | `ExitConfirmationConfig?` | `null`                      | An optional configuration that prevents accidental closing of the picker when users have selected media.                                                                                                  |
| `showCameraTile`       | `bool`                    | `true`                      | When `true`, renders a live `camera` feed at index `0`. Supports both photo and video depending on `requestType`. Tap to open a full-screen Dribbble-inspired UI.                                         |
| `enableSwipeToSelect`  | `bool`                    | `true`                      | When `true`, allows the user to long-press and drag their finger across the masonry grid to rapidly select items (iOS Photos style). Includes edge auto-scroll.                                           |
| `useOriginalFile`      | `bool`                    | `false`                     | When `true`, fetches the absolute pristine original file rather than a system-optimized/compressed format from iOS or Android cache.                                                                      |
| `thumbnailCacheSize`   | `int`                     | `200`                       | Maximum number of thumbnails kept in the LRU memory cache. A value of 200 ensures buttery scrolling over 2–3 screens of content.                                                                          |
| `maxConcurrentDecodes` | `int`                     | `3`                         | Maximum simultaneous thumbnail decodes. Limiting this ensures scrolling remains 60fps+ by preventing thread starvation on large grids.                                                                    |
| `prefetchEnabled`      | `bool`                    | `true`                      | When `true`, the picker intelligently pre-loads thumbnails for the next 30 items that are about to appear on-screen during scrolling, eliminating pop-in.                                                 |
| `themeData`            | `PickerThemeData?`        | `null`                      | Provides full control over individual UI colors (background, surface, text, etc.) which take precedence over the defaults resolved from `brightness`.                                                     |

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

| Version    | Status    | Highlights                                                                                                                                                                                                                                                                                                                            |
| ---------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **v1.0.0** | ✅ Stable | Core engine (Grid, Video, Audio), Live Camera Tile, iOS-style swipe-to-select, Heavy Performance Optimizations (LRU Cache, Decode Queue, Prefetching), BYOE Architecture, Inline Search, Google Photos Cloud Provider with native persistence, auto-refresh tokens, secure sign-out flow, iCloud integration, and Drag & Drop Reorder |

---

## 🌟 Support the Project

Building and maintaining high-quality open-source packages takes a lot of time and coffee! ☕  
If `gallery_suite` has saved you time and elevated your app's UX, please consider:

1. **Giving it a ⭐️ on [GitHub](https://github.com/Hawks124/gallery_suite)** to help other developers find it.
2. **Hitting the 👍 Like button on [Pub.dev](https://pub.dev/packages/gallery_suite)** to boost our ranking!

Your support is our greatest motivation. Thank you! ❤️

---

## 📜 License

Apache 2.0 — see [LICENSE](LICENSE).

---

## ❤️ Acknowledgements & Credits

`gallery_suite` stands on the shoulders of giants. This package would not exist without the incredible work of the following open-source contributors:

**Core Media Engine**

- **[photo_manager](https://pub.dev/packages/photo_manager)** — The high-performance engine powering our native media library access on Android, iOS, and macOS.
- **[flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view)** — Responsible for the beautiful and fluid Masonry layout of our grids.

**Playback & Camera**

- **[video_player](https://pub.dev/packages/video_player)** — Enabling our seamless, zero-latency inline video previews.
- **[just_audio](https://pub.dev/packages/just_audio)** — The backbone of our integrated audio playback experience.
- **[camera](https://pub.dev/packages/camera)** — Allowing us to build a premium, fully-integrated live camera capture experience into the grid.

**Desktop & Web Ecosystem**

- **[file_selector](https://pub.dev/packages/file_selector)** — The robust abstraction bridging our UI to native OS Drag-and-Drop and File Explorer dialogs for Windows, Linux, and Web architectures.

- **[desktop_drop](https://pub.dev/packages/desktop_drop)** — The robust abstraction bridging our UI to native OS Drag-and-Drop and File Explorer dialogs for Windows, Linux, and Web architectures.

**Smart Clipboard System**

- **[pasteboard](https://pub.dev/packages/pasteboard)** — Extracts pristine raw media bytes and file URLs directly from the underlying system clipboard natively.
- **[mime](https://pub.dev/packages/mime)** — Performs dynamic deep inspection on clipboard URLs to automatically deduce binary MIME types without HTTP overhead.

**Google Photos Cloud Integration**

- **[google_sign_in](https://pub.dev/packages/google_sign_in)** — Provides lightweight Google authentication for non-PKCE flows and user profile resolution.
- **[flutter_web_auth_2](https://pub.dev/packages/flutter_web_auth_2)** — Powers the secure PKCE OAuth2 flow via Chrome Custom Tabs on Android, enabling our compliant Google Photos integration.
- **[googleapis_auth](https://pub.dev/packages/googleapis_auth)** — Manages authenticated HTTP clients for the Google Picker API token lifecycle.
- **[extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth)** — Bridges `google_sign_in` with `googleapis_auth` for seamless authorized API calls.
- **[cached_network_image](https://pub.dev/packages/cached_network_image)** — Caches and renders remote Google Photos thumbnails in the cloud grid efficiently.
- **[http](https://pub.dev/packages/http)** — Handles OAuth2 PKCE token exchange and authenticated REST API calls.
- **[crypto](https://pub.dev/packages/crypto)** — Provides SHA-256 hashing for generating PKCE code challenges, ensuring a secure OAuth2 flow.

**Persistence**

- **[path_provider](https://pub.dev/packages/path_provider)** — Resolves the platform-appropriate local storage directories for our zero-dependency JSON persistence layer.

Thank you to the Flutter community for building the "bricks" that allowed us to create this "house". 🏠✨
