/// Smart Clipboard detection service for [gallery_suite].
///
/// This service scans the system clipboard for media content and converts it
/// into [PickerAsset] instances that the picker's masonry grid can display
/// natively — exactly like local or cloud assets.
///
/// ## Supported Clipboard Content
///
/// | Content Type          | Detection Method           | Returned Asset         |
/// |-----------------------|----------------------------|------------------------|
/// | Copied image (bytes)  | `Pasteboard.image`         | [FilePickerAsset]      |
/// | Copied file(s)        | `Pasteboard.files()`       | [FilePickerAsset]      |
/// | Media URL (text)      | `Clipboard.getData` + MIME | [RemotePickerAsset]    |
///
/// ## Memory Management
///
/// - Temporary files written to [getTemporaryDirectory] are tracked internally
///   and cleaned up via [dispose] when the clipboard mode is exited.
/// - Only **one** scan is performed per user action (no polling or loops).
/// - Raw `Uint8List` bytes from `Pasteboard.image` are released from memory
///   immediately after being flushed to disk.
library;

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../gallery_suite.dart';

/// Singleton service that detects and converts clipboard content into
/// [PickerAsset] objects usable by the picker grid.
///
/// Call [fetchAssets] to perform a one-shot scan, then call [dispose] when
/// the clipboard mode is dismissed to reclaim temporary disk space.
class ClipboardService {
  ClipboardService._();

  /// Global singleton instance.
  static final ClipboardService instance = ClipboardService._();

  /// Tracks temporary files created during clipboard reads so they can be
  /// deleted when [dispose] is called.
  final List<dynamic> _tempFiles = [];

  /// Whether a fetch is currently in progress (prevents double-tapping).
  bool _isFetching = false;

  /// Performs a single, non-blocking scan of the system clipboard.
  ///
  /// Returns a list of [PickerAsset] instances. The list is empty when
  /// no media content is detected. The caller should show an appropriate
  /// empty-state message in that case.
  ///
  /// The scan order is:
  /// 1. **Text clipboard** — checked for media URLs (image/video/audio).
  /// 2. **File clipboard** — checked for copied file paths.
  /// 3. **Image clipboard** — checked for raw copied image bytes.
  ///
  /// Each step short-circuits: if a URL is found, files and bytes are skipped.
  Future<List<PickerAsset>> fetchAssets() async {
    debugPrint('📋 [ClipboardService] ---- FETCH ASSETS STARTED ----');
    if (_isFetching) {
      debugPrint('📋 [ClipboardService] Fetch already in progress. Aborting.');
      return [];
    }
    _isFetching = true;

    try {
      final assets = <PickerAsset>[];

      debugPrint('📋 [ClipboardService] Step 1: Checking Pasteboard.image');
      final imageAsset = await _tryParseImageBytes();
      if (imageAsset != null) {
        debugPrint('📋 [ClipboardService] Found ImageBytes! Returning.');
        assets.add(imageAsset);
        return assets;
      }

      debugPrint('📋 [ClipboardService] Step 2: Checking Pasteboard.files()');
      final fileAssets = await _tryParseFiles();
      if (fileAssets.isNotEmpty) {
        debugPrint(
            '📋 [ClipboardService] Found ${fileAssets.length} Files! Returning.');
        assets.addAll(fileAssets);
        return assets;
      }

      debugPrint('📋 [ClipboardService] Step 3: Checking Clipboard.kTextPlain');
      final urlAsset = await _tryParseTextUrl();
      if (urlAsset != null) {
        debugPrint('📋 [ClipboardService] Found Text URL! Returning.');
        assets.add(urlAsset);
      } else {
        debugPrint('📋 [ClipboardService] Found NO ASSETS in all 3 steps.');
      }

      return assets;
    } catch (e, stackTrace) {
      debugPrint(
          '📋 [ClipboardService] fetchAssets FATAL ERROR: $e\n$stackTrace');
      return [];
    } finally {
      _isFetching = false;
    }
  }

  // ── Private: URL detection ──────────────────────────────────────────────

  Future<PickerAsset?> _tryParseTextUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      debugPrint(
          '📋 [ClipboardService] _tryParseTextUrl -> Clipboard text: "$text"');
      if (text == null || text.isEmpty) return null;

      final uri = Uri.tryParse(text);
      if (uri == null || !uri.hasScheme) {
        debugPrint(
            '📋 [ClipboardService] _tryParseTextUrl -> Invalid URI scheme');
        return null;
      }

      final mimeType = lookupMimeType(uri.path) ?? '';
      debugPrint(
          '📋 [ClipboardService] _tryParseTextUrl -> URL mimeType: $mimeType');
      AssetType? type;

      if (mimeType.startsWith('image/')) {
        type = AssetType.image;
      } else if (mimeType.startsWith('video/')) {
        type = AssetType.video;
      } else if (mimeType.startsWith('audio/')) {
        type = AssetType.audio;
      }

      if (type == null) {
        final lower = text.toLowerCase();
        if (_hasImageExtension(lower)) {
          type = AssetType.image;
        } else if (_hasVideoExtension(lower)) {
          type = AssetType.video;
        } else if (_hasAudioExtension(lower)) {
          type = AssetType.audio;
        } else {
          try {
            debugPrint(
                '📋 [ClipboardService] _tryParseTextUrl -> Executing HTTP GET fallback...');
            final response = await http.get(
              uri,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
              },
            ).timeout(const Duration(seconds: 5));

            final contentType = response.headers['content-type'] ?? '';
            debugPrint(
                '📋 [ClipboardService] _tryParseTextUrl -> HTTP GET contentType = $contentType');

            if (contentType.startsWith('image/')) {
              type = AssetType.image;
            } else if (contentType.startsWith('video/')) {
              type = AssetType.video;
            } else if (contentType.startsWith('audio/')) {
              type = AssetType.audio;
            } else if (contentType.contains('text/html')) {
              // --- OpenGraph Scraping ---
              // The user pasted a web page URL (e.g. Freepik, Unsplash, Google Images).
              // Try to extract the og:image meta tag to get a shareable preview image.
              final ogImageUrl = _extractOgImage(response.body);
              if (ogImageUrl != null) {
                debugPrint(
                    '📋 [ClipboardService] _tryParseTextUrl -> Found og:image: $ogImageUrl');
                return RemotePickerAsset(
                  id: 'clipboard_og_${ogImageUrl.hashCode.toRadixString(36)}',
                  baseUrl: ogImageUrl,
                  title: uri.pathSegments.isNotEmpty
                      ? uri.pathSegments.last
                      : 'Web Image',
                  type: AssetType.image,
                );
              }
            }
          } catch (e) {
            debugPrint(
                '📋 [ClipboardService] _tryParseTextUrl -> HTTP GET error: $e');
          }
        }
      }

      debugPrint(
          '📋 [ClipboardService] _tryParseTextUrl -> Computed AssetType: $type');
      if (type == null) return null;

      return RemotePickerAsset(
        id: 'clipboard_url_${text.hashCode.toRadixString(36)}',
        baseUrl: text,
        title:
            uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Clipboard',
        type: type,
      );
    } catch (e) {
      debugPrint('📋 [ClipboardService] _tryParseTextUrl error: $e');
      return null;
    }
  }

  // ── Private: File detection ─────────────────────────────────────────────

  Future<List<FilePickerAsset>> _tryParseFiles() async {
    if (kIsWeb) return [];
    try {
      final paths = await Pasteboard.files();
      debugPrint(
          '📋 [ClipboardService] _tryParseFiles -> Pasteboard.files() returned: $paths');
      if (paths.isEmpty) return [];

      final assets = <FilePickerAsset>[];

      for (var path in paths) {
        if (path.startsWith('content://')) {
          debugPrint(
              '📋 [ClipboardService] _tryParseFiles -> Detected Android Content URI: $path');
          try {
            final id = path.split('/').last;
            debugPrint(
                '📋 [ClipboardService] _tryParseFiles -> Extracting ID: $id');
            final entity = await AssetEntity.fromId(id);
            final resolvedFile = await entity?.file;
            if (resolvedFile != null && resolvedFile.existsSync()) {
              debugPrint(
                  '📋 [ClipboardService] _tryParseFiles -> Successfully mapped URI to real file: ${resolvedFile.path}');
              path = resolvedFile.path;
            } else {
              debugPrint(
                  '📋 [ClipboardService] _tryParseFiles -> FAILED to resolve Content URI via photo_manager.');
              continue; // Unable to resolve the secure URI
            }
          } catch (e) {
            debugPrint(
                '📋 [ClipboardService] _tryParseFiles -> exception resolving URI: $e');
            continue;
          }
        }

        final file = io.File(path);
        if (!file.existsSync()) {
          debugPrint(
              '📋 [ClipboardService] _tryParseFiles -> File does not exist locally: $path');
          continue;
        }

        final mimeType = lookupMimeType(path) ?? '';
        final isMedia = mimeType.startsWith('image/') ||
            mimeType.startsWith('video/') ||
            mimeType.startsWith('audio/');

        // If lookup fails, try common extensions locally
        if (!isMedia &&
            !_hasImageExtension(path.toLowerCase()) &&
            !_hasVideoExtension(path.toLowerCase()) &&
            !_hasAudioExtension(path.toLowerCase())) {
          debugPrint(
              '📋 [ClipboardService] _tryParseFiles -> File is not a media file type: $path');
          continue;
        }

        Uint8List? bytes;
        int width = 0;
        int height = 0;

        if (mimeType.startsWith('image/') ||
            _hasImageExtension(path.toLowerCase())) {
          try {
            bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              final image = await decodeImageFromList(bytes);
              width = image.width;
              height = image.height;
              image.dispose();
            }
          } catch (e) {
            debugPrint(
                '📋 [ClipboardService] _tryParseFiles -> Exception reading bytes: $e');
          }
        }

        assets.add(FilePickerAsset(
          filePath: path,
          title: path.split(kIsWeb ? '/' : io.Platform.pathSeparator).last,
          bytes: bytes,
          width: width,
          height: height,
        ));
      }

      return assets;
    } catch (e) {
      debugPrint('📋 [ClipboardService] _tryParseFiles error: $e');
      return [];
    }
  }

  // ── Private: Raw image bytes detection ──────────────────────────────────

  Future<FilePickerAsset?> _tryParseImageBytes() async {
    if (kIsWeb) return null;
    try {
      debugPrint(
          '📋 [ClipboardService] _tryParseImageBytes -> Calling Pasteboard.image...');
      final Uint8List? imageBytes = await Pasteboard.image;

      if (imageBytes == null) {
        debugPrint(
            '📋 [ClipboardService] _tryParseImageBytes -> Pasteboard.image returned NULL.');
        return null;
      }
      if (imageBytes.isEmpty) {
        debugPrint(
            '📋 [ClipboardService] _tryParseImageBytes -> Pasteboard.image returned EMPTY bytes.');
        return null;
      }

      // Write to a temporary file to avoid holding large blobs in memory.
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = io.File('${tempDir.path}/clipboard_$timestamp.png');
      await tempFile.writeAsBytes(imageBytes, flush: true);

      // Track for cleanup.
      _tempFiles.add(tempFile);

      // Decode dimensions for the masonry grid aspect ratio.
      int width = 0;
      int height = 0;
      try {
        final decoded = await decodeImageFromList(imageBytes);
        width = decoded.width;
        height = decoded.height;
        decoded.dispose();
      } catch (_) {}

      // The Uint8List reference will be GC'd after this scope ends since we
      // only pass the file path forward. We intentionally skip storing bytes
      // in the asset to keep memory footprint minimal.
      return FilePickerAsset(
        filePath: tempFile.path,
        title: 'Clipboard_$timestamp.png',
        bytes: imageBytes,
        width: width,
        height: height,
      );
    } catch (e) {
      debugPrint('[ClipboardService] _tryParseImageBytes error: $e');
      return null;
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  /// Deletes all temporary files created during clipboard reads.
  ///
  /// Call this when the user exits clipboard mode to reclaim disk space.
  /// Safe to call multiple times.
  void dispose() {
    if (kIsWeb) return;
    for (final dynamic file in _tempFiles) {
      try {
        if (file is io.File && file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('[ClipboardService] cleanup error: $e');
      }
    }
    _tempFiles.clear();
    _isFetching = false;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool _hasImageExtension(String url) {
    const exts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
    return exts.any((e) => url.contains(e));
  }

  bool _hasVideoExtension(String url) {
    const exts = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'];
    return exts.any((e) => url.contains(e));
  }

  bool _hasAudioExtension(String url) {
    const exts = ['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a'];
    return exts.any((e) => url.contains(e));
  }

  // ── OpenGraph Scraping ──────────────────────────────────────────────────

  /// Extracts a media preview URL from an HTML page using OpenGraph, Twitter
  /// Card, and Schema.org meta tags.
  ///
  /// Covers ALL known real-world variations:
  /// - `og:image`, `og:image:secure_url`, `og:image:url`
  /// - `og:video`, `og:video:secure_url`, `og:video:url`
  /// - `twitter:image`, `twitter:image:src`
  /// - Schema.org `itemprop="image"`
  /// - Both attribute orders (`property` then `content` & vice-versa)
  /// - HTML entity decoding (`&amp;` → `&`)
  /// - Protocol-relative URLs (`//cdn.example.com/...` → `https://...`)
  ///
  /// Uses lightweight regex to avoid adding an HTML parser dependency.
  String? _extractOgImage(String html) {
    // All meta property/name values we want to extract, in priority order.
    // The first match wins.
    const targets = [
      'og:image:secure_url', // HTTPS preferred variant
      'og:image:url', // Explicit URL variant
      'og:image', // Standard OpenGraph image
      'og:video:secure_url',
      'og:video:url',
      'og:video',
      'twitter:image:src', // Twitter Card explicit variant
      'twitter:image', // Twitter Card standard
    ];

    // --- Pass 1: property/name-based meta tags ---
    // Matches both: <meta property="X" content="Y"/>
    //           and: <meta content="Y" property="X"/>
    for (final target in targets) {
      final escaped = RegExp.escape(target);

      // Order A: property="..." content="..."
      final patternA = RegExp(
        '<meta[^>]+(?:property|name)\\s*=\\s*["\']$escaped["\'][^>]+content\\s*=\\s*["\']([^"\']+)["\']',
        caseSensitive: false,
      );
      // Order B: content="..." property="..."
      final patternB = RegExp(
        '<meta[^>]+content\\s*=\\s*["\']([^"\']+)["\'][^>]+(?:property|name)\\s*=\\s*["\']$escaped["\']',
        caseSensitive: false,
      );

      for (final pattern in [patternA, patternB]) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          final resolved = _resolveOgUrl(match.group(1));
          if (resolved != null) return resolved;
        }
      }
    }

    // --- Pass 2: Schema.org itemprop="image" ---
    // e.g. <meta itemprop="image" content="https://..." />
    final schemaPatterns = [
      RegExp(
        r'''<meta[^>]+itemprop\s*=\s*["']image["'][^>]+content\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+content\s*=\s*["']([^"']+)["'][^>]+itemprop\s*=\s*["']image["']''',
        caseSensitive: false,
      ),
    ];

    for (final pattern in schemaPatterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final resolved = _resolveOgUrl(match.group(1));
        if (resolved != null) return resolved;
      }
    }

    // --- Pass 3: Apple Touch Icon (Often a high-quality logo/fallback) ---
    final iconPatterns = [
      RegExp(r'''<link[^>]+rel\s*=\s*["']apple-touch-icon["'][^>]+href\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''<link[^>]+href\s*=\s*["']([^"']+)["'][^>]+rel\s*=\s*["']apple-touch-icon["']''', caseSensitive: false),
      RegExp(r'''<link[^>]+rel\s*=\s*["']icon["'][^>]+href\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''<link[^>]+href\s*=\s*["']([^"']+)["'][^>]+rel\s*=\s*["']icon["']''', caseSensitive: false),
    ];
    for (final pattern in iconPatterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final resolved = _resolveOgUrl(match.group(1));
        if (resolved != null) return resolved;
      }
    }

    // --- Pass 4: First generic <img src="..."> ---
    final imgPattern = RegExp(r'''<img[^>]+src\s*=\s*["'](http[^"']+)["']''', caseSensitive: false);
    var match = imgPattern.firstMatch(html);
    if (match != null) {
      final resolved = _resolveOgUrl(match.group(1));
      if (resolved != null) return resolved;
    }

    // --- Pass 5: Bruteforce ANY absolute image URL in the raw HTML ---
    final rawUrlPattern = RegExp(r'''https?:\/\/[^\s"'<>{}]+?\.(?:jpg|jpeg|png|webp)''', caseSensitive: false);
    match = rawUrlPattern.firstMatch(html);
    if (match != null) {
      final resolved = _resolveOgUrl(match.group(0));
      if (resolved != null) return resolved;
    }

    return null;
  }

  /// Cleans and resolves a raw URL extracted from an HTML meta tag.
  ///
  /// Handles HTML entity decoding (`&amp;` → `&`) and protocol-relative
  /// URLs (`//cdn.example.com/...` → `https://cdn.example.com/...`).
  /// Returns `null` if the URL is not a valid HTTP(S) address.
  String? _resolveOgUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    // Decode common HTML entities
    var url = raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();

    // Handle protocol-relative URLs
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Only accept absolute HTTP(S) URLs
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return null;
  }
}
