import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'picker_asset.dart';

/// A lightweight convenience wrapper that represents a user-selected media item.
///
/// [MediaItem] can originate from either the **local device** gallery or from
/// a **remote cloud** source (e.g., Google Photos). Use [isRemote] to check
/// the source, then access the data via [asset] (local) or [remoteAsset] (cloud).
///
/// Example:
/// ```dart
/// final items = await CustomMediaPicker.show(context: context);
///
/// for (final item in items ?? []) {
///   if (item.isRemote) {
///     print('Cloud URL: ${item.remoteAsset!.fullUrl}');
///   } else {
///     final File? file = await item.toFile();
///     // upload or preview `file`
///   }
/// }
/// ```
class MediaItem {
  /// The underlying [AssetEntity] from `photo_manager` (local assets only).
  /// `null` for remote assets.
  final AssetEntity? asset;

  /// The underlying [RemotePickerAsset] (cloud assets only).
  /// `null` for local assets.
  final RemotePickerAsset? remoteAsset;

  /// Whether to fetch the absolute uncompressed original file from the OS.
  final bool useOriginalFile;

  /// An explicitly provided edited File (e.g. from an image cropper/editor).
  /// If provided, [file] will always return this instance instead of querying the OS.
  final File? editedFile;

  /// Creates a [MediaItem] wrapping a **local** asset.
  const MediaItem({
    required AssetEntity this.asset,
    this.useOriginalFile = false,
    this.editedFile,
  }) : remoteAsset = null;

  /// Creates a [MediaItem] wrapping a **remote/cloud** asset.
  const MediaItem.remote({
    required RemotePickerAsset this.remoteAsset,
    this.editedFile,
  })  : asset = null,
        useOriginalFile = false;

  /// `true` if this item originates from a remote cloud source.
  bool get isRemote => remoteAsset != null;

  /// `true` if this item originates from the local device gallery.
  bool get isLocal => asset != null;

  /// The unique identifier of this asset.
  String get id => isRemote ? remoteAsset!.id : asset!.id;

  /// Returns `true` if this asset is a video.
  bool get isVideo => isRemote
      ? remoteAsset!.type == AssetType.video
      : asset!.type == AssetType.video;

  /// Returns `true` if this asset is an image.
  bool get isImage => isRemote
      ? remoteAsset!.type == AssetType.image
      : asset!.type == AssetType.image;

  /// Returns `true` if this asset is an audio file.
  bool get isAudio => !isRemote && asset!.type == AssetType.audio;

  /// The pixel width of the image or video.
  int get width => isRemote ? remoteAsset!.width : asset!.width;

  /// The pixel height of the image or video.
  int get height => isRemote ? remoteAsset!.height : asset!.height;

  /// The title / filename of the asset, or `null` if unavailable.
  String? get title => isRemote ? remoteAsset!.title : asset!.title;

  /// The duration of the video or audio. Returns [Duration.zero] for images.
  Duration get videoDuration =>
      isRemote ? remoteAsset!.duration : asset!.videoDuration;

  /// The width / height aspect ratio, clamped to a sane range.
  ///
  /// Falls back to `1.0` (square) if dimensions are unavailable.
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1.0;
    return width / height;
  }

  /// Returns the local [File] for this asset, or `null` if inaccessible.
  ///
  /// For **remote assets**, this will automatically **download** the file
  /// to a temporary local cache using the provided authentication headers.
  Future<File?> get file {
    if (editedFile != null) return Future.value(editedFile);
    if (isRemote) return toLocalFile();
    return useOriginalFile ? asset!.originFile : asset!.file;
  }

  /// Downoads a remote asset if necessary and returns the cached [File].
  ///
  /// For local assets, this is equivalent to [file].
  Future<File?> toLocalFile() async {
    if (isLocal) return file;
    if (remoteAsset == null) return null;

    return MediaService.instance.downloadRemoteAsset(
      remoteAsset!.fullUrl,
      headers: remoteAsset!.headers,
      id: remoteAsset!.id,
    );
  }

  /// Helper method equivalent to the [file] getter.
  Future<File?> toFile() => file;
}
