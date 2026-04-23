import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// A utility class providing cross-platform abstractions for Web-specific APIs.
///
/// This stub implementation ensures that mobile and desktop platforms (Android,
/// iOS, Windows, macOS, Linux) can compile the package without crashing on
/// `dart:html` imports. The actual Web implementations are injected at compile
/// time via conditional exports in `web_utils.dart`.
class WebUtils {
  /// Opens the given [url] in a new browser tab.
  /// No-op on non-Web platforms.
  static void openUrlInNewTab(String url) {}

  /// Fetches media bytes securely bypassing some CORS restrictions on Web
  /// using an XMLHttpRequest. Returns null on non-Web platforms.
  static Future<Uint8List?> fetchMediaBytes(
          String url, Map<String, String> headers) async =>
      null;

  /// Creates an ephemeral Object URL (blob:) from memory [bytes].
  /// Required for `<video>` tag playback on Web without CORS issues.
  /// Returns null on non-Web platforms.
  static String? createBlobUrl(Uint8List bytes) => null;

  /// Revokes an previously created Object URL to free memory.
  /// No-op on non-Web platforms.
  static void revokeBlobUrl(String url) {}

  /// Renders the Google Sign-In Web button via FedCM.
  /// Returns an empty SizedBox on non-Web platforms.
  static Widget renderWebLoginButton() => const SizedBox.shrink();
}
