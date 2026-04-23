// Factory that resolves the correct [MediaSource] for the current platform.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'media_source.dart';
import 'native_media_source.dart';
import 'file_selector_media_source.dart';

/// Resolves the appropriate [MediaSource] based on the runtime platform.
///
/// - **Web**: Always returns [FileSelectorMediaSource]
/// - **iOS / Android / macOS**: Returns [NativeMediaSource] (photo_manager)
/// - **Windows / Linux**: Returns [FileSelectorMediaSource]
class MediaSourceFactory {
  MediaSourceFactory._();

  static MediaSource? _instance;

  /// Returns the singleton [MediaSource] for the current app session.
  /// This ensures Web/Desktop selections persist across picker opens.
  static MediaSource get activeSource {
    _instance ??= _create();
    return _instance!;
  }

  static MediaSource _create() {
    if (kIsWeb) {
      return FileSelectorMediaSource();
    }

    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
      return NativeMediaSource();
    }

    // Windows, Linux, Fuchsia → file_selector fallback
    return FileSelectorMediaSource();
  }
}
