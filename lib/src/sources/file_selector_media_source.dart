// Web/Desktop media source powered by `file_selector`.
//
// On platforms without a native photo library API (Web, Windows, Linux),
// this source opens the OS file dialog and loads selected files into the
// picker grid. All files live in-memory as [FilePickerAsset]s.

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart' show RequestType;

import '../models/picker_asset.dart';
import 'media_source.dart';

/// Media source using [file_selector] for Web, Windows, and Linux.
///
/// Instead of browsing a photo library, the user explicitly picks files
/// via the native OS file dialog. The selected files are held in-memory
/// and displayed in the masonry grid.
class FileSelectorMediaSource implements MediaSource {
  /// All files currently loaded by the user.
  final List<FilePickerAsset> _loadedAssets = [];

  /// The virtual album representing user-selected files.
  static const _virtualAlbum = AlbumDescriptor(
    id: '__file_selector__',
    name: 'Selected Files',
  );

  @override
  bool get supportsAlbumBrowsing => false;

  @override
  bool get supportsFileAddition => true;

  @override
  Future<bool> requestPermission() async =>
      true; // No gallery permission needed

  @override
  Future<List<AlbumDescriptor>> getAlbums(RequestType type) async {
    return [_virtualAlbum];
  }

  @override
  Future<List<PickerAsset>> getAssets({
    required AlbumDescriptor album,
    required int page,
    required int pageSize,
  }) async {
    // Simple paging over in-memory list
    final start = page * pageSize;
    if (start >= _loadedAssets.length) return [];
    final end = (start + pageSize).clamp(0, _loadedAssets.length);
    return _loadedAssets.sublist(start, end);
  }

  @override
  Future<List<PickerAsset>> searchAssets(
      AlbumDescriptor album, String query) async {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _loadedAssets
        .where((a) => (a.title?.toLowerCase() ?? '').contains(lowerQuery))
        .toList();
  }

  @override
  Future<Uint8List?> getThumbnail(PickerAsset asset,
      {int priority = 10}) async {
    if (asset is! FilePickerAsset) return null;

    // If pre-loaded bytes exist, return them
    if (asset.bytes != null) return asset.bytes;

    // Otherwise, read file bytes directly
    try {
      final file = File(asset.filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('[FileSelectorMediaSource] Error reading thumbnail: $e');
    }
    return null;
  }

  @override
  Future<Uint8List?> getPreviewThumbnail(PickerAsset asset) =>
      getThumbnail(asset);

  @override
  Future<Uint8List?> getAlbumCoverThumbnail(AlbumDescriptor album) async {
    if (_loadedAssets.isEmpty) return null;
    return getThumbnail(_loadedAssets.first);
  }

  @override
  void prefetchThumbnails(List<PickerAsset> assets) {
    // No-op: files are already in memory on web/desktop
  }

  /// Opens the native file dialog and adds the selected files to the grid.
  ///
  /// Returns the newly added [FilePickerAsset]s.
  Future<List<FilePickerAsset>> pickFiles({RequestType? requestType}) async {
    final typeGroups = <XTypeGroup>[];

    switch (requestType) {
      case RequestType.video:
        typeGroups.add(const XTypeGroup(
          label: 'Videos',
          extensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'],
        ));
        break;
      case RequestType.audio:
        typeGroups.add(const XTypeGroup(
          label: 'Audio',
          extensions: ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'],
        ));
        break;
      default:
        typeGroups.add(const XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
        ));
        break;
    }

    final files = await openFiles(acceptedTypeGroups: typeGroups);

    final newAssets = <FilePickerAsset>[];
    for (final xfile in files) {
      // Prevent duplicates
      if (_loadedAssets.any((a) => a.filePath == xfile.path)) continue;

      Uint8List? bytes;
      try {
        bytes = await xfile.readAsBytes();
      } catch (_) {}

      newAssets.add(FilePickerAsset(
        filePath: xfile.path,
        bytes: bytes,
      ));
    }

    _loadedAssets.addAll(newAssets);
    return newAssets;
  }

  /// Clears all loaded files.
  void clearAll() => _loadedAssets.clear();
}
