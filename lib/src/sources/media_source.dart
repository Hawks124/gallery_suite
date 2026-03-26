// Abstract interface for all media source providers.
//
// This abstraction enables the picker to work seamlessly across platforms:
// - Mobile (iOS/Android/macOS): wraps `photo_manager` via [NativeMediaSource]
// - Web/Desktop (Windows/Linux): wraps `file_selector` via [FileSelectorMediaSource]

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart' show RequestType;

import '../models/picker_asset.dart';
import 'album_descriptor.dart';

export 'album_descriptor.dart';

/// Unified interface for fetching media from any platform.
///
/// Implementations provide platform-specific logic while the picker UI
/// consumes this interface uniformly.
abstract class MediaSource {
  /// Requests permission from the OS to access the photo library.
  ///
  /// On Web/Desktop (file_selector), this always returns `true`
  /// since no gallery permission is needed — files are explicitly chosen.
  Future<bool> requestPermission();

  /// Returns the list of available albums/folders.
  ///
  /// On mobile, these are real albums from the device gallery.
  /// On Web/Desktop, this returns a single virtual "Selected Files" album.
  Future<List<AlbumDescriptor>> getAlbums(RequestType type);

  /// Returns a page of assets from the given [album].
  Future<List<PickerAsset>> getAssets({
    required AlbumDescriptor album,
    required int page,
    required int pageSize,
  });

  /// Searches for assets within [album] matching [query] by title/filename.
  Future<List<PickerAsset>> searchAssets(AlbumDescriptor album, String query);

  /// Returns a high-quality 400×400 thumbnail for grid display.
  Future<Uint8List?> getThumbnail(PickerAsset asset, {int priority = 10});

  /// Returns a medium 120×120 thumbnail for the bottom preview strip.
  Future<Uint8List?> getPreviewThumbnail(PickerAsset asset);

  /// Returns a small 80×80 thumbnail for album covers in the switcher sheet.
  Future<Uint8List?> getAlbumCoverThumbnail(AlbumDescriptor album);

  /// Pre-loads thumbnails for [assets] at low priority.
  void prefetchThumbnails(List<PickerAsset> assets);

  /// Whether this source supports album browsing (mobile) vs file selection (web/desktop).
  bool get supportsAlbumBrowsing;

  /// Whether this source supports adding more files incrementally (web/desktop).
  bool get supportsFileAddition;
}
