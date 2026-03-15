import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

/// A lightweight convenience wrapper around [AssetEntity].
///
/// [MediaItem] exposes the most commonly needed properties as typed getters
/// so you don't need to import `photo_manager` in every widget that just
/// needs to read file metadata.
///
/// You can always access the underlying [AssetEntity] via [asset] for
/// advanced use-cases.
///
/// Example:
/// ```dart
/// final assets = await CustomMediaPicker.show(context: context);
/// final items = assets?.map((e) => MediaItem(asset: e)).toList() ?? [];
///
/// for (final item in items) {
///   if (item.isVideo) {
///     print('Video: ${item.videoDuration.inSeconds}s');
///   } else {
///     print('Image: ${item.width}×${item.height}');
///   }
///   final File? file = await item.toFile();
/// }
/// ```
class MediaItem {
  /// The underlying [AssetEntity] from `photo_manager`.
  final AssetEntity asset;

  /// Creates a [MediaItem] wrapping the given [asset].
  const MediaItem({required this.asset});

  /// The unique identifier of this asset on the device.
  String get id => asset.id;

  /// Returns `true` if this asset is a video.
  bool get isVideo => asset.type == AssetType.video;

  /// Returns `true` if this asset is an image.
  bool get isImage => asset.type == AssetType.image;

  /// Returns `true` if this asset is an audio file.
  bool get isAudio => asset.type == AssetType.audio;

  /// The pixel width of the image or video.
  int get width => asset.width;

  /// The pixel height of the image or video.
  int get height => asset.height;

  /// The title / filename of the asset, or `null` if unavailable.
  String? get title => asset.title;

  /// The duration of the video or audio. Returns [Duration.zero] for images.
  Duration get videoDuration => asset.videoDuration;

  /// The width / height aspect ratio, clamped to a sane range.
  ///
  /// Falls back to `1.0` (square) if dimensions are unavailable.
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1.0;
    return width / height;
  }

  /// Returns the local [File] for this asset, or `null` if inaccessible.
  ///
  /// This is an async operation — the file may need to be downloaded from
  /// iCloud or Google Photos on first access.
  Future<File?> toFile() => asset.file;
}
