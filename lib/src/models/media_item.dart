// Core data models representing media assets within the picker.

import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import 'picker_asset.dart';

// A lightweight convenience wrapper that represents a user-selected media item.
//
// [MediaItem] can originate from either the **local device** gallery or from
// a **remote cloud** source (e.g., Google Photos). Use [isRemote] to check
// the source, then access the data via [asset] (local) or [remoteAsset] (cloud).
//
// Example:
// ```dart
// final items = await CustomMediaPicker.show(context: context);
//
// for (final item in items ?? []) {
//   if (item.isRemote) {
//     print('Cloud URL: ${item.remoteAsset!.fullUrl}');
//   } else {
//     final File? file = await item.toFile();
//     // upload or preview `file`
//   }
// }
// ```
class MediaItem {
  // The underlying [AssetEntity] from `photo_manager` (local assets only).
  // `null` for remote assets.
  final AssetEntity? asset;

  // The underlying [RemotePickerAsset] (cloud assets only).
  // `null` for local assets.
  final RemotePickerAsset? remoteAsset;

  // The underlying [FilePickerAsset] (Web/Desktop assets).
  // `null` for other sources.
  final FilePickerAsset? fileAsset;

  // Whether to fetch the absolute uncompressed original file from the OS.
  final bool useOriginalFile;

  // An explicitly provided edited File (e.g. from an image cropper/editor).
  // If provided, [file] will always return this instance instead of querying the OS.
  final File? editedFile;

  // Creates a [MediaItem] wrapping a **local** asset.
  const MediaItem({
    required AssetEntity this.asset,
    this.useOriginalFile = false,
    this.editedFile,
  })  : remoteAsset = null,
        fileAsset = null;

  // Creates a [MediaItem] wrapping a **remote/cloud** asset.
  const MediaItem.remote({
    required RemotePickerAsset this.remoteAsset,
    this.editedFile,
  })  : asset = null,
        fileAsset = null,
        useOriginalFile = false;

  // Creates a [MediaItem] wrapping a **Web/Desktop** raw asset.
  const MediaItem.file({
    required FilePickerAsset this.fileAsset,
    this.editedFile,
  })  : asset = null,
        remoteAsset = null,
        useOriginalFile = false;

  // Convenience factory to create a [MediaItem] from any [PickerAsset].
  factory MediaItem.fromAsset(PickerAsset asset,
      {bool useOriginalFile = false}) {
    if (asset is LocalPickerAsset) {
      return MediaItem(asset: asset.entity, useOriginalFile: useOriginalFile);
    } else if (asset is RemotePickerAsset) {
      return MediaItem.remote(remoteAsset: asset);
    } else if (asset is FilePickerAsset) {
      return MediaItem.file(fileAsset: asset);
    }
    throw UnsupportedError('Unsupported asset type: ${asset.runtimeType}');
  }

  // `true` if this item originates from a remote cloud source.
  bool get isRemote => remoteAsset != null;

  // `true` if this item originates from the local device gallery.
  bool get isLocal => asset != null;

  // `true` if this item is a raw file bytes payload (Web/Desktop).
  bool get isFile => fileAsset != null;

  // The unique identifier of this asset.
  String get id =>
      isRemote ? remoteAsset!.id : (isFile ? fileAsset!.id : asset!.id);

  // Returns `true` if this asset is a video.
  bool get isVideo => isRemote
      ? remoteAsset!.type == AssetType.video
      : (isFile
          ? fileAsset!.type == AssetType.video
          : asset!.type == AssetType.video);

  // Returns `true` if this asset is an image.
  bool get isImage => isRemote
      ? remoteAsset!.type == AssetType.image
      : (isFile
          ? fileAsset!.type == AssetType.image
          : asset!.type == AssetType.image);

  // Returns `true` if this asset is an audio file.
  bool get isAudio => isRemote
      ? remoteAsset!.type == AssetType.audio
      : (isFile
          ? fileAsset!.type == AssetType.audio
          : asset!.type == AssetType.audio);

  // The pixel width of the image or video.
  int get width => isRemote
      ? remoteAsset!.width
      : (isFile ? fileAsset!.width : asset!.width);

  // The pixel height of the image or video.
  int get height => isRemote
      ? remoteAsset!.height
      : (isFile ? fileAsset!.height : asset!.height);

  // The title / filename of the asset, or `null` if unavailable.
  String? get title => isRemote
      ? remoteAsset!.title
      : (isFile ? fileAsset!.title : asset!.title);

  // The duration of the video or audio. Returns [Duration.zero] for images.
  Duration get videoDuration => isRemote
      ? remoteAsset!.duration
      : (isFile ? fileAsset!.duration : asset!.videoDuration);

  // The width / height aspect ratio, clamped to a sane range.
  //
  // Falls back to `1.0` (square) if dimensions are unavailable.
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1.0;
    return width / height;
  }

  // Returns the raw bytes for this asset.
  //
  // Crucial for Web where [file] might be inaccessible or unsupported.
  Future<Uint8List?> get bytes async {
    if (isFile) return fileAsset!.bytes;
    if (isRemote) {
      return remoteAsset!.googleService?.getMediaBytes(remoteAsset!.fullUrl);
    }
    if (isLocal) {
      return asset!.originBytes;
    }
    return null;
  }

  // Returns the local [File] for this asset, or `null` if inaccessible.
  //
  // For **remote assets**, this will automatically **download** the file
  // to a temporary local cache using the provided authentication headers.
  // NOTE: Crashes on Web due to [path_provider] and [dart:io] limitations.
  Future<File?> get file {
    if (editedFile != null) return Future.value(editedFile);
    if (isRemote) return toLocalFile();
    if (isFile) return Future.value(fileAsset!.file);
    return useOriginalFile ? asset!.originFile : asset!.file;
  }

  // Downoads a remote asset if necessary and returns the cached [File].
  //
  // For local assets, this is equivalent to [file].
  Future<File?> toLocalFile() async {
    if (isLocal) return file;
    if (remoteAsset == null) return null;

    return MediaService.instance.downloadRemoteAsset(
      remoteAsset!.fullUrl,
      headers: remoteAsset!.headers,
      id: remoteAsset!.id,
    );
  }

  // Helper method equivalent to the [file] getter.
  Future<File?> toFile() => file;
}
