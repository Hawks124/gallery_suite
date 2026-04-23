import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

/// The Web-specific implementation of the cross-platform WebUtils layer.
/// This module isolates all [dart:html] calls so that Android and iOS can
/// successfully compile the package without breaking dependencies.
class WebUtils {
  /// Uses [html.window.open] to dynamically launch standard URIs and signed `ppa/`
  /// blobs in a fresh browser context as a fallback.
  static void openUrlInNewTab(String url) {
    html.window.open(url, '_blank');
  }

  /// Prepares an XMLHttpRequest internally to fetch raw media bytes securely from
  /// Google Photos APIs.
  /// Bypasses some aggressive CORS preflight OPTIONS requests by dynamically
  /// scrubbing the HTTP headers for special Picker-API URLs (e.g., `ppa/`).
  static Future<Uint8List?> fetchMediaBytes(
      String url, Map<String, String> headers) async {
    try {
      final completer = Completer<Uint8List?>();
      final xhr = html.HttpRequest();
      xhr.open('GET', url);

      if (!url.contains('/ppa/')) {
        headers.forEach((key, value) {
          xhr.setRequestHeader(key, value);
        });
      }

      xhr.responseType = 'arraybuffer';
      xhr.onLoad.listen((event) {
        if (xhr.status == 200) {
          final buffer = xhr.response as ByteBuffer;
          completer.complete(buffer.asUint8List());
        } else {
          completer.complete(null);
        }
      });
      xhr.onError.listen((event) {
        completer.complete(null);
      });
      xhr.send();
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  /// Packages raw binary `Uint8List` into a memory-resident `Blob` resource,
  /// then provisions a localized Object URL natively parsable by `<img>` and
  /// `<video>` tags. Used extensively for media previews.
  static String? createBlobUrl(Uint8List bytes) {
    try {
      final blob = html.Blob([bytes]);
      return html.Url.createObjectUrlFromBlob(blob);
    } catch (e) {
      return null;
    }
  }

  /// Garbage collects a previously minted Blob URL from the current web timeline,
  /// mitigating catastrophic V8 heap expansion inside intensive media swiping operations.
  static void revokeBlobUrl(String url) {
    if (!url.startsWith('blob:')) return;
    try {
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      // ignore
    }
  }

  /// Renders the Google Sign-In Web button via FedCM.
  static Widget renderWebLoginButton() {
    return web_only.renderButton();
  }
}
