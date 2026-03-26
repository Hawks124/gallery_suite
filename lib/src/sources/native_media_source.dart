// Mobile/macOS media source powered by `photo_manager`.
//
// This is a thin adapter around the existing [MediaService] singleton,
// translating its `AssetPathEntity`-based API into the platform-agnostic
// [MediaSource] interface.

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

import '../models/picker_asset.dart';
import '../services/media_service.dart';
import 'media_source.dart';

/// Media source backed by `photo_manager` for iOS, Android, and macOS.
///
/// Delegates all heavy lifting to the existing [MediaService] singleton,
/// preserving its performance optimizations (ThumbnailDecodeQueue, LRU cache).
class NativeMediaSource implements MediaSource {
  final MediaService _service = MediaService.instance;

  @override
  bool get supportsAlbumBrowsing => true;

  @override
  bool get supportsFileAddition => false;

  @override
  Future<bool> requestPermission() => _service.requestPermission();

  @override
  Future<List<AlbumDescriptor>> getAlbums(RequestType type) async {
    final albums = await _service.getAlbums(type);
    final descriptors = <AlbumDescriptor>[];
    for (final album in albums) {
      final count = await album.assetCountAsync;
      descriptors.add(AlbumDescriptor.fromNative(album, count));
    }
    return descriptors;
  }

  @override
  Future<List<PickerAsset>> getAssets({
    required AlbumDescriptor album,
    required int page,
    required int pageSize,
  }) async {
    if (album.nativeAlbum == null) return [];
    final entities = await _service.getAssets(
      album: album.nativeAlbum!,
      page: page,
      pageSize: pageSize,
    );
    return entities.map((e) => LocalPickerAsset(e)).toList();
  }

  @override
  Future<List<PickerAsset>> searchAssets(
      AlbumDescriptor album, String query) async {
    if (album.nativeAlbum == null) return [];
    final entities = await _service.searchAssets(album.nativeAlbum!, query);
    return entities.map((e) => LocalPickerAsset(e)).toList();
  }

  @override
  Future<Uint8List?> getThumbnail(PickerAsset asset, {int priority = 10}) {
    if (asset is! LocalPickerAsset) return Future.value(null);
    return _service.getThumbnail(asset.entity, priority: priority);
  }

  @override
  Future<Uint8List?> getPreviewThumbnail(PickerAsset asset) {
    if (asset is! LocalPickerAsset) return Future.value(null);
    return _service.getPreviewThumbnail(asset.entity);
  }

  @override
  Future<Uint8List?> getAlbumCoverThumbnail(AlbumDescriptor album) {
    if (album.nativeAlbum == null) return Future.value(null);
    return _service.getAlbumCoverThumbnail(album.nativeAlbum!);
  }

  @override
  void prefetchThumbnails(List<PickerAsset> assets) {
    final locals =
        assets.whereType<LocalPickerAsset>().map((a) => a.entity).toList();
    if (locals.isNotEmpty) _service.prefetchThumbnails(locals);
  }
}
