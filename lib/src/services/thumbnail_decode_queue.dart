import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:photo_manager/photo_manager.dart';

/// A performance-optimized thumbnail loading system for large photo libraries.
///
/// [ThumbnailDecodeQueue] implements:
/// - **LRU caching** with configurable entry count and byte-size limits
/// - **Concurrency throttling** to prevent frame drops during rapid scrolling
/// - **Priority ordering** so on-screen tiles load before prefetched ones
///
/// Usage is managed internally by [MediaService]. You do not need to
/// interact with this class directly.
class ThumbnailDecodeQueue {
  /// Creates a decode queue with the given concurrency and cache limits.
  ThumbnailDecodeQueue({
    this.maxConcurrent = 3,
    this.maxCacheEntries = 200,
    this.maxCacheBytes = 50 * 1024 * 1024, // 50 MB
  });

  /// Maximum number of thumbnail decodes that can run simultaneously.
  final int maxConcurrent;

  /// Maximum number of entries in the LRU cache before eviction starts.
  final int maxCacheEntries;

  /// Maximum total bytes of cached thumbnails before eviction starts.
  final int maxCacheBytes;

  // ── LRU Cache ──────────────────────────────────────────────────────────────
  /// Ordered map: most-recently-used entries are at the **end**.
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap<String, Uint8List>();

  /// Running total of bytes stored in the cache.
  int _currentCacheBytes = 0;

  // ── Decode Queue ───────────────────────────────────────────────────────────
  final List<_DecodeRequest> _queue = [];
  int _activeDecodes = 0;
  bool _drainScheduled = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a cached thumbnail for [key], or `null` if not found.
  ///
  /// Accessing a cached entry moves it to the most-recently-used position.
  Uint8List? get(String key) {
    final data = _cache.remove(key);
    if (data != null) {
      // Re-insert at end (most recently used).
      _cache[key] = data;
    }
    return data;
  }

  /// Manually inserts [data] into the cache under [key].
  void put(String key, Uint8List data) {
    // If it already exists, remove it first so we can re-insert at end.
    final existing = _cache.remove(key);
    if (existing != null) {
      _currentCacheBytes -= existing.lengthInBytes;
    }
    _cache[key] = data;
    _currentCacheBytes += data.lengthInBytes;
    _evictIfNeeded();
  }

  /// Schedules a thumbnail decode for the given [asset] at the specified
  /// [size] and [quality].
  ///
  /// If the thumbnail is already cached, [onComplete] fires immediately.
  /// [priority] controls ordering: higher values are decoded first.
  /// Typical usage: on-screen = 10, prefetch = 1.
  void enqueue({
    required AssetEntity asset,
    required String cacheKey,
    required ThumbnailSize size,
    required int quality,
    required void Function(Uint8List? data) onComplete,
    int priority = 5,
  }) {
    // Fast path: already cached.
    final cached = get(cacheKey);
    if (cached != null) {
      onComplete(cached);
      return;
    }

    // Check for existing request to avoid duplicates.
    final existingIdx = _queue.indexWhere((r) => r.cacheKey == cacheKey);
    if (existingIdx >= 0) {
      // Update the callback to the latest consumer.
      _queue[existingIdx].onComplete = onComplete;
      _queue[existingIdx].priority = priority;
      return;
    }

    _queue.add(_DecodeRequest(
      asset: asset,
      cacheKey: cacheKey,
      size: size,
      quality: quality,
      onComplete: onComplete,
      priority: priority,
    ));

    _scheduleDrain();
  }

  /// Cancels all pending (not-yet-started) decode requests.
  ///
  /// In-flight decodes will still complete and be cached, but their callbacks
  /// won't be invoked.
  void cancelPending() {
    for (final req in _queue) {
      req.cancelled = true;
    }
    _queue.clear();
  }

  /// Removes all entries from the cache and cancels pending decodes.
  void clearAll() {
    cancelPending();
    _cache.clear();
    _currentCacheBytes = 0;
  }

  /// Current number of entries in the cache.
  int get cacheEntryCount => _cache.length;

  /// Current total bytes used by cached thumbnails.
  int get cacheByteCount => _currentCacheBytes;

  /// Number of decode requests waiting in the queue.
  int get pendingCount => _queue.length;

  // ── Internals ──────────────────────────────────────────────────────────────

  void _scheduleDrain() {
    if (_drainScheduled) return;
    _drainScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _drainScheduled = false;
      _drainQueue();
    });
  }

  void _drainQueue() {
    while (_activeDecodes < maxConcurrent && _queue.isNotEmpty) {
      // Sort descending by priority so highest-priority items fire first.
      _queue.sort((a, b) => b.priority.compareTo(a.priority));
      final request = _queue.removeAt(0);
      if (request.cancelled) continue;
      _activeDecodes++;
      _executeRequest(request);
    }
  }

  Future<void> _executeRequest(_DecodeRequest request) async {
    try {
      final data = await request.asset.thumbnailDataWithSize(
        request.size,
        quality: request.quality,
      );
      if (data != null) {
        put(request.cacheKey, data);
      }
      if (!request.cancelled) {
        request.onComplete(data);
      }
    } catch (_) {
      if (!request.cancelled) {
        request.onComplete(null);
      }
    } finally {
      _activeDecodes--;
      if (_queue.isNotEmpty) {
        _scheduleDrain();
      }
    }
  }

  void _evictIfNeeded() {
    while ((_cache.length > maxCacheEntries ||
            _currentCacheBytes > maxCacheBytes) &&
        _cache.isNotEmpty) {
      // Remove from the FRONT (least recently used).
      final firstKey = _cache.keys.first;
      final evicted = _cache.remove(firstKey);
      if (evicted != null) {
        _currentCacheBytes -= evicted.lengthInBytes;
      }
    }
  }
}

/// Internal request descriptor for the decode queue.
class _DecodeRequest {
  final AssetEntity asset;
  final String cacheKey;
  final ThumbnailSize size;
  final int quality;
  void Function(Uint8List? data) onComplete;
  int priority;
  bool cancelled = false;

  _DecodeRequest({
    required this.asset,
    required this.cacheKey,
    required this.size,
    required this.quality,
    required this.onComplete,
    this.priority = 5,
  });
}
