// Data structures for unified local and remote media assets.

import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

// A unified representation of any media asset that the picker can display,
// whether from the local device gallery or from a remote cloud source
// like Google Photos.
//
// The picker's internal grid uses [PickerAsset] to render items uniformly
// regardless of their origin.
sealed class PickerAsset {
  // A stable, unique identifier for this asset.
  String get id;

  // The display title or filename.
  String? get title;

  // The asset type (image, video, audio).
  AssetType get type;

  // The pixel width (may be 0 for remote assets where metadata is unavailable).
  int get width;

  // The pixel height (may be 0 for remote assets where metadata is unavailable).
  int get height;

  // The duration (non-zero for video / audio assets).
  Duration get duration;
}

// A media asset originating from the **local device** gallery.
//
// Wraps the underlying [AssetEntity] from `photo_manager`.
class LocalPickerAsset implements PickerAsset {
  // The underlying [AssetEntity] from the device gallery.
  final AssetEntity entity;

  // Creates a [LocalPickerAsset] wrapping a local [entity].
  const LocalPickerAsset(this.entity);

  @override
  String get id => entity.id;

  @override
  String? get title => entity.title;

  @override
  AssetType get type => entity.type;

  @override
  int get width => entity.width;

  @override
  int get height => entity.height;

  @override
  Duration get duration => entity.videoDuration;

  // Convenience: fetch the local [File].
  Future<File?> get file => entity.file;

  // Convenience: fetch the original uncompressed [File].
  Future<File?> get originFile => entity.originFile;
}

// A media asset originating from a **remote cloud** source (e.g. Google Photos).
//
// Does not reference any local file - everything is URL-based.
class RemotePickerAsset implements PickerAsset {
  @override
  final String id;

  @override
  final String? title;

  @override
  final AssetType type;

  @override
  final int width;

  @override
  final int height;

  @override
  final Duration duration;

  // The base URL of the image (from Google Photos API, S3, etc.).
  // For Google Photos, append `=w400-h400-c` for thumbnails or `=d` for full-res download.
  final String baseUrl;

  // Optional HTTP headers required to access the URL (e.g., Authorization headers).
  final Map<String, String>? headers;

  // Creates a [RemotePickerAsset] representing a cloud-hosted item.
  const RemotePickerAsset({
    required this.id,
    required this.baseUrl,
    this.title,
    this.type = AssetType.image,
    this.width = 0,
    this.height = 0,
    this.duration = Duration.zero,
    this.headers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.index,
        'width': width,
        'height': height,
        'duration_ms': duration.inMilliseconds,
        'baseUrl': baseUrl,
      };

  factory RemotePickerAsset.fromJson(Map<String, dynamic> json,
      {Map<String, String>? injectedHeaders}) {
    return RemotePickerAsset(
      id: json['id'] as String,
      baseUrl: json['baseUrl'] as String,
      title: json['title'] as String?,
      type: AssetType.values[json['type'] as int? ?? 1],
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      duration: Duration(milliseconds: json['duration_ms'] as int? ?? 0),
      headers: injectedHeaders,
    );
  }

  // Returns a thumbnail URL optimized for grid display.
  //
  // For Google Photos API, this appends dimensions and crop directives.
  // Videos MUST include `-v` to return an image thumbnail instead of video bytes.
  String get thumbUrl {
    if (type == AssetType.video) {
      return '$baseUrl=w400-h400-c-v';
    }
    return '$baseUrl=w400-h400-c';
  }

  // Returns the full-resolution download URL.
  // Videos use `=dv` to download the video file, images use `=d`.
  String get fullUrl {
    if (type == AssetType.video) {
      return '$baseUrl=dv';
    }
    return '$baseUrl=d';
  }
}

// A media asset originating from the platform **file selector** (Web/Desktop).
//
// Unlike [LocalPickerAsset] (which wraps `photo_manager`'s AssetEntity),
// this holds a raw file path and in-memory bytes for thumbnails.
class FilePickerAsset implements PickerAsset {
  @override
  final String id;

  @override
  final String? title;

  @override
  final AssetType type;

  @override
  final int width;

  @override
  final int height;

  @override
  final Duration duration;

  // The absolute path to the selected file.
  final String filePath;

  // Pre-loaded raw bytes of the file (used for thumbnail generation).
  final Uint8List? bytes;

  // Creates a [FilePickerAsset] from a file path.
  FilePickerAsset({
    required this.filePath,
    this.bytes,
    this.width = 0,
    this.height = 0,
    this.duration = Duration.zero,
  })  : id = filePath.hashCode.toRadixString(36),
        title = filePath.split(Platform.pathSeparator).last,
        type = _inferType(filePath);

  // Convenience: return the local [File].
  File get file => File(filePath);

  // Infers [AssetType] from the file extension.
  static AssetType _inferType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if ({'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'}.contains(ext)) {
      return AssetType.video;
    }
    if ({'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'}.contains(ext)) {
      return AssetType.audio;
    }
    return AssetType.image;
  }
}
