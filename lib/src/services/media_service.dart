import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// Service that handles media permissions, album fetching, asset loading,
/// and thumbnail caching for the Gallery Suite picker.
///
/// [MediaService] wraps the `photo_manager` plugin and adds an in-memory
/// [Uint8List] thumbnail cache so the same thumbnail is never decoded twice
/// during a single picker session.
///
/// Example:
/// ```dart
/// final service = MediaService();
/// final hasAccess = await service.requestPermission();
/// if (hasAccess) {
///   final albums = await service.getAlbums(RequestType.image);
/// }
/// ```
class MediaService {
  /// In-memory thumbnail cache keyed by asset ID (or a derived key).
  static final Map<String, Uint8List> _thumbnailCache = {};

  /// Clears all cached thumbnails.
  ///
  /// Call this when you want to free memory – typically when the picker
  /// is dismissed.
  static void clearCache() => _thumbnailCache.clear();

  /// Requests permission from the OS to access the photo library.
  ///
  /// Returns `true` if the user granted full or limited access.
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.isLimited;
  }

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

  /// Returns a high-quality 400×400 thumbnail for the masonry grid.
  ///
  /// Results are cached in memory so subsequent calls for the same [asset]
  /// return instantly.
  Future<Uint8List?> getThumbnail(AssetEntity asset) async {
    final cached = _thumbnailCache[asset.id];
    if (cached != null) return cached;

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(400, 400),
      quality: 90,
    );
    if (data != null) {
      _thumbnailCache[asset.id] = data;
    }
    return data;
  }

  /// Returns a medium 120×120 thumbnail for the bottom preview strip.
  ///
  /// The cache key is suffixed with `_preview` to avoid collisions with the
  /// higher-resolution grid thumbnail.
  Future<Uint8List?> getPreviewThumbnail(AssetEntity asset) async {
    final key = '${asset.id}_preview';
    final cached = _thumbnailCache[key];
    if (cached != null) return cached;

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(120, 120),
      quality: 85,
    );
    if (data != null) {
      _thumbnailCache[key] = data;
    }
    return data;
  }

  /// Returns a small 80×80 thumbnail used as the album cover in the
  /// album-switcher bottom sheet.
  ///
  /// Returns `null` if the album is empty.
  Future<Uint8List?> getAlbumCoverThumbnail(AssetPathEntity album) async {
    final key = 'album_cover_${album.id}';
    final cached = _thumbnailCache[key];
    if (cached != null) return cached;

    final assets = await album.getAssetListRange(start: 0, end: 1);
    if (assets.isEmpty) return null;

    final data = await assets.first.thumbnailDataWithSize(
      const ThumbnailSize(80, 80),
      quality: 70,
    );
    if (data != null) {
      _thumbnailCache[key] = data;
    }
    return data;
  }
}
