// Web/Desktop media source powered by `file_selector`.
//
// On platforms without a native photo library API (Web, Windows, Linux),
// this source opens the OS file dialog and loads selected files into the
// picker grid. All files live in-memory as [FilePickerAsset]s.

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show decodeImageFromList;
import 'package:photo_manager/photo_manager.dart' show RequestType;
import 'package:video_player/video_player.dart';

import '../enum/enum.dart';
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
  Future<bool> requestPermission() async => true; // No gallery permission needed

  @override
  Future<List<AlbumDescriptor>> getAlbums(RequestType type) async {
    return [_virtualAlbum];
  }

  @override
  Set<PickerSortOrder> get supportedSortOrders => const {
    PickerSortOrder.newest,
    PickerSortOrder.oldest,
    PickerSortOrder.largest,
    PickerSortOrder.smallest,
  };

  @override
  Future<List<PickerAsset>> getAssets({
    required AlbumDescriptor album,
    required int page,
    required int pageSize,
    PickerSortOrder? sortOrder,
  }) async {
    // Simple paging over the in-memory list, ordered on the real file
    // metadata reported by the OS when the files were picked.
    final ordered = _orderedAssets(sortOrder);
    final start = page * pageSize;
    if (start >= ordered.length) return [];
    final end = (start + pageSize).clamp(0, ordered.length);
    return ordered.sublist(start, end);
  }

  /// Returns the loaded files ordered according to [sortOrder].
  List<FilePickerAsset> _orderedAssets(PickerSortOrder? sortOrder) {
    final order = sortOrder ?? PickerSortOrder.newest;
    final ordered = List<FilePickerAsset>.of(_loadedAssets);
    switch (order) {
      case PickerSortOrder.newest:
        ordered.sort(_byLastModifiedDescending);
      case PickerSortOrder.oldest:
        ordered.sort(_byLastModifiedAscending);
      case PickerSortOrder.largest:
        ordered.sort(_byByteSizeDescending);
      case PickerSortOrder.smallest:
        ordered.sort(_byByteSizeAscending);
    }
    return ordered;
  }

  static int _compareNullableInt(int? a, int? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static int _compareNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static int _byByteSizeDescending(FilePickerAsset a, FilePickerAsset b) =>
      _compareNullableInt(b.byteSize, a.byteSize);

  static int _byByteSizeAscending(FilePickerAsset a, FilePickerAsset b) =>
      _compareNullableInt(a.byteSize, b.byteSize);

  static int _byLastModifiedDescending(FilePickerAsset a, FilePickerAsset b) =>
      _compareNullableDate(b.lastModified, a.lastModified);

  static int _byLastModifiedAscending(FilePickerAsset a, FilePickerAsset b) =>
      _compareNullableDate(a.lastModified, b.lastModified);

  @override
  Future<List<PickerAsset>> searchAssets(
    AlbumDescriptor album,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _loadedAssets
        .where((a) => (a.title?.toLowerCase() ?? '').contains(lowerQuery))
        .toList();
  }

  @override
  Future<Uint8List?> getThumbnail(
    PickerAsset asset, {
    int priority = 10,
  }) async {
    if (asset is! FilePickerAsset) return null;

    // If pre-loaded bytes exist, return them
    if (asset.bytes != null) return asset.bytes;

    // Otherwise, read file bytes directly
    if (!kIsWeb) {
      try {
        final file = File(asset.filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('[FileSelectorMediaSource] Error reading thumbnail: $e');
      }
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
        typeGroups.add(
          const XTypeGroup(
            label: 'Videos',
            extensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'],
          ),
        );
        break;
      case RequestType.audio:
        typeGroups.add(
          const XTypeGroup(
            label: 'Audio',
            extensions: ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'],
          ),
        );
        break;
      default:
        typeGroups.add(
          const XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
          ),
        );
        break;
    }

    final files = await openFiles(acceptedTypeGroups: typeGroups);

    final newAssets = <FilePickerAsset>[];
    for (final xfile in files) {
      // Prevent duplicates
      if (_loadedAssets.any((a) => a.filePath == xfile.path)) continue;

      Uint8List? bytes;
      int width = 0;
      int height = 0;
      Duration duration = Duration.zero;

      try {
        final ext = xfile.name.split('.').last.toLowerCase();
        final isVideo = {
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
          '3gp',
        }.contains(ext);
        final isAudio = {
          'mp3',
          'wav',
          'aac',
          'flac',
          'ogg',
          'm4a',
        }.contains(ext);

        if (isVideo || isAudio) {
          VideoPlayerController? ctrl;
          try {
            if (kIsWeb) {
              ctrl = VideoPlayerController.networkUrl(Uri.parse(xfile.path));
            } else {
              ctrl = VideoPlayerController.file(File(xfile.path));
            }
            await ctrl.initialize();
            duration = ctrl.value.duration;
          } catch (_) {}
          ctrl?.dispose();
        } else {
          bytes = await xfile.readAsBytes();
          if (bytes.isNotEmpty) {
            final image = await decodeImageFromList(bytes);
            width = image.width;
            height = image.height;
            image.dispose();
          }
        }
      } catch (e) {
        debugPrint('[FileSelectorMediaSource] Error decoding file: $e');
      }

      newAssets.add(
        FilePickerAsset(
          filePath: xfile.path,
          title: xfile.name,
          bytes: bytes,
          byteSize: await _safeLength(xfile),
          lastModified: await _safeLastModified(xfile),
          width: width,
          height: height,
          duration: duration,
        ),
      );
    }

    _loadedAssets.addAll(newAssets);
    return newAssets;
  }

  /// Reads the real byte size of [file] without throwing.
  static Future<int?> _safeLength(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  /// Reads the last modification date of [file] without throwing.
  static Future<DateTime?> _safeLastModified(XFile file) async {
    try {
      return await file.lastModified();
    } catch (_) {
      return null;
    }
  }

  /// Clears all loaded files.
  void clearAll() => _loadedAssets.clear();
}
