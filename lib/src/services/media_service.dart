import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'thumbnail_decode_queue.dart';

/// Service that handles media permissions, album fetching, asset loading,
/// and high-performance thumbnail caching for the Gallery Suite picker.
///
/// [MediaService] is a **singleton** — every widget shares the same instance
/// and therefore the same [ThumbnailDecodeQueue] / LRU cache. Access it via
/// [MediaService.instance] or the default constructor, which returns the
/// singleton.
///
/// ### Performance Features
/// - **LRU thumbnail cache** with configurable entry count and byte-size limits
/// - **Concurrency-throttled decoding** to keep scrolling at 60 fps+
/// - **Priority queue** so on-screen tiles decode before prefetched tiles
///
/// Example:
/// ```dart
/// final service = MediaService.instance;
/// final hasAccess = await service.requestPermission();
/// if (hasAccess) {
///   final albums = await service.getAlbums(RequestType.image);
/// }
/// ```
class MediaService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final MediaService _instance = MediaService._internal();

  /// The shared singleton instance.
  static MediaService get instance => _instance;

  /// Returns the singleton [MediaService]. Equivalent to [MediaService.instance].
  factory MediaService() => _instance;

  MediaService._internal();

  // ── Decode Queue (replaces the old static Map cache) ───────────────────────
  /// The thumbnail decode queue / LRU cache backing all thumbnail requests.
  ///
  /// Consumers can tune [ThumbnailDecodeQueue.maxConcurrent],
  /// [ThumbnailDecodeQueue.maxCacheEntries], and
  /// [ThumbnailDecodeQueue.maxCacheBytes] by replacing this field before
  /// opening the picker.
  ThumbnailDecodeQueue decodeQueue = ThumbnailDecodeQueue();

  /// Clears all cached thumbnails and cancels pending decodes.
  ///
  /// Call this when you want to free memory — typically when the picker
  /// is dismissed.
  static void clearCache() => _instance.decodeQueue.clearAll();

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Requests permission from the OS to access the photo library.
  ///
  /// Returns `true` if the user granted full or limited access.
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.isLimited;
  }

  // ── Albums & Assets ────────────────────────────────────────────────────────

  /// Fetches the list of albums (aka asset paths) for the given [requestType].
  ///
  /// Albums are ordered by creation date (newest first).
  Future<List<AssetPathEntity>> getAlbums(RequestType requestType) async {
    return PhotoManager.getAssetPathList(
      type: requestType,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
  }

  /// Fetches a page of assets from the given [album].
  ///
  /// Uses cursor-based pagination via [page] and [pageSize].
  Future<List<AssetEntity>> getAssets({
    required AssetPathEntity album,
    required int page,
    required int pageSize,
  }) async {
    return album.getAssetListPaged(page: page, size: pageSize);
  }

  /// Searches for assets within the given [album] that match [query].
  ///
  /// This performs an extremely fast Dart-side memory filter, fetching
  /// the full asset list first and matching against `asset.title`.
  /// This works robustly across Android, iOS, macOS, and Web.
  Future<List<AssetEntity>> searchAssets(
      AssetPathEntity album, String query) async {
    final count = await album.assetCountAsync;
    if (count == 0 || query.trim().isEmpty) return [];

    final allAssets = await album.getAssetListRange(start: 0, end: count);
    final lowerQuery = query.toLowerCase();

    return allAssets.where((asset) {
      final title = asset.title?.toLowerCase() ?? '';
      return title.contains(lowerQuery);
    }).toList();
  }

  // ── Thumbnails (backed by ThumbnailDecodeQueue) ────────────────────────────

  /// Returns a high-quality 400×400 thumbnail for the masonry grid.
  ///
  /// If cached, returns immediately. Otherwise the request is enqueued
  /// in the [decodeQueue] with the given [priority].
  ///
  /// [priority] controls decode order: higher = sooner. Typical values:
  /// - On-screen tile: `10`
  /// - Prefetch: `1`
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int priority = 10,
  }) async {
    // Fast path: LRU cache hit.
    final cached = decodeQueue.get(asset.id);
    if (cached != null) return cached;

    // Enqueue and await completion.
    final completer = _ThumbnailCompleter();
    decodeQueue.enqueue(
      asset: asset,
      cacheKey: asset.id,
      size: const ThumbnailSize(400, 400),
      quality: 90,
      priority: priority,
      onComplete: completer.complete,
    );
    return completer.future;
  }

  /// Returns a medium 120×120 thumbnail for the bottom preview strip.
  ///
  /// Uses a `_preview` suffixed cache key to avoid collisions with
  /// the higher-resolution grid thumbnail.
  Future<Uint8List?> getPreviewThumbnail(AssetEntity asset) async {
    final key = '${asset.id}_preview';
    final cached = decodeQueue.get(key);
    if (cached != null) return cached;

    final completer = _ThumbnailCompleter();
    decodeQueue.enqueue(
      asset: asset,
      cacheKey: key,
      size: const ThumbnailSize(120, 120),
      quality: 85,
      priority: 8,
      onComplete: completer.complete,
    );
    return completer.future;
  }

  /// Returns a small 80×80 thumbnail used as the album cover in the
  /// album-switcher bottom sheet.
  ///
  /// Returns `null` if the album is empty.
  Future<Uint8List?> getAlbumCoverThumbnail(AssetPathEntity album) async {
    final key = 'album_cover_${album.id}';
    final cached = decodeQueue.get(key);
    if (cached != null) return cached;

    final assets = await album.getAssetListRange(start: 0, end: 1);
    if (assets.isEmpty) return null;

    final completer = _ThumbnailCompleter();
    decodeQueue.enqueue(
      asset: assets.first,
      cacheKey: key,
      size: const ThumbnailSize(80, 80),
      quality: 70,
      priority: 3,
      onComplete: completer.complete,
    );
    return completer.future;
  }

  // ── Prefetching ────────────────────────────────────────────────────────────

  /// Pre-loads thumbnails for the given [assets] at low priority.
  ///
  /// This is called by the picker when the user scrolls, to pre-warm
  /// the cache for items that are about to appear on screen.
  void prefetchThumbnails(List<AssetEntity> assets) {
    for (final asset in assets) {
      final cached = decodeQueue.get(asset.id);
      if (cached != null) continue; // already cached

      decodeQueue.enqueue(
        asset: asset,
        cacheKey: asset.id,
        size: const ThumbnailSize(400, 400),
        quality: 90,
        priority: 1, // low priority
        onComplete: (_) {}, // fire-and-forget
      );
    }
  }
  // ── Remote Downloads ───────────────────────────────────────────────────────

  /// Downloads a remote asset from [url] to a local temporary file.
  ///
  /// Returns the [File] object pointing to the downloaded data, or `null`
  /// if the download fails. Uses [id] to name the file and avoid redundant
  /// downloads if already cached in the temp directory.
  Future<File?> downloadRemoteAsset(
    String url, {
    Map<String, String>? headers,
    required String id,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/remote_asset_$id');

      // Simple cache check: if file exists and has content, return it.
      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('[MediaService] Error downloading remote asset: $e');
      return null;
    }
  }
}

/// Simple helper that wraps a one-shot callback into a [Future].
class _ThumbnailCompleter {
  final _completer = Completer<Uint8List?>();

  Future<Uint8List?> get future => _completer.future;

  void complete(Uint8List? data) {
    if (!_completer.isCompleted) {
      _completer.complete(data);
    }
  }
}
