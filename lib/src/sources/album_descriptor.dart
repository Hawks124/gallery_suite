// Platform-agnostic album descriptor.
//
// On mobile, this wraps an [AssetPathEntity] from `photo_manager`.
// On web/desktop, this represents a virtual "Selected Files" collection.

import 'package:photo_manager/photo_manager.dart' show AssetPathEntity;

/// A lightweight, platform-agnostic descriptor for a media album or folder.
///
/// This decouples the picker UI from `photo_manager` types, allowing
/// Web and Desktop sources to provide virtual albums.
class AlbumDescriptor {
  /// A unique identifier for this album.
  final String id;

  /// The human-readable name of this album (e.g. "Camera Roll", "Selected Files").
  final String name;

  /// The total number of assets in this album (-1 if unknown).
  final int assetCount;

  /// The underlying [AssetPathEntity] from `photo_manager`, if this
  /// descriptor was created from a native album. `null` on web/desktop.
  final AssetPathEntity? nativeAlbum;

  const AlbumDescriptor({
    required this.id,
    required this.name,
    this.assetCount = -1,
    this.nativeAlbum,
  });

  /// Creates a descriptor wrapping a native [AssetPathEntity].
  factory AlbumDescriptor.fromNative(AssetPathEntity entity, int count) {
    return AlbumDescriptor(
      id: entity.id,
      name: entity.name,
      assetCount: count,
      nativeAlbum: entity,
    );
  }
}
