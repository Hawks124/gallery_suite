import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class MediaService {
  static final Map<String, Uint8List> _thumbnailCache = {};

  static void clearCache() => _thumbnailCache.clear();

  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.isLimited;
  }

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

  Future<List<AssetEntity>> getAssets({
    required AssetPathEntity album,
    required int page,
    required int pageSize,
  }) async {
    return album.getAssetListPaged(page: page, size: pageSize);
  }

  /// High-quality thumbnail for masonry grid (400×400, quality 90)
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

  /// Medium thumbnail for bottom preview strip (120×120, quality 85)
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

  /// Small thumbnail for album cover (80×80, quality 70)
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
