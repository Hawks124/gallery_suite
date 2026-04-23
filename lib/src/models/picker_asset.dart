// Data structures for unified local and remote media assets.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
export 'package:photo_manager/photo_manager.dart' show AssetType;

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

  // Reference to the authenticated service to handle Web-specific byte fetching.
  // Using [dynamic] to avoid circular dependency with GooglePhotosService.
  final dynamic googleService;

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
    this.googleService,
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
      {Map<String, String>? injectedHeaders, dynamic googleService}) {
    return RemotePickerAsset(
      id: json['id'] as String,
      baseUrl: json['baseUrl'] as String,
      title: json['title'] as String?,
      type: AssetType.values[json['type'] as int? ?? 1],
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      duration: Duration(milliseconds: json['duration_ms'] as int? ?? 0),
      headers: injectedHeaders,
      googleService: googleService,
    );
  }

  // Returns a thumbnail URL optimized for grid display.
  //
  // For Google Photos API, this appends dimensions and crop directives.
  // Videos MUST include `-v` to return an image thumbnail instead of video bytes.
  String get thumbUrl {
    // For Google Photos Picker API 2025 signed URLs (ppa/), appending parameters
    // often fails due to signature mismatch or CORS on all platforms it breaks the signature.
    if (baseUrl.contains('/ppa/')) {
      return baseUrl;
    }

    if (type == AssetType.video) {
      return '$baseUrl=w400-h400-c-v';
    }
    return '$baseUrl=w400-h400-c';
  }

  // Returns the full-resolution download URL.
  // Videos use `=dv` to download the video file, images use `=d`.
  String get fullUrl {
    // For Google Photos Picker API 2025 signed URLs (ppa/), appending parameters
    // often fails due to signature mismatch or CORS on all platforms it breaks the signature.
    if (baseUrl.contains('/ppa/')) {
      return baseUrl;
    }

    if (type == AssetType.video) {
      // Use =m18 for Web (transcoded mp4) for better compatibility
      // Use =dv for other platforms (direct video)
      final suffix = kIsWeb ? '=m18' : '=dv';
      return '$baseUrl$suffix';
    }
    return '$baseUrl=w2048-h2048'; // High resolution for photos
  }

  /// Returns the raw bytes for this asset.
  ///
  /// Fetches from Google Photos using the authenticated service.
  Future<Uint8List?> get bytes async {
    return googleService?.getMediaBytes(fullUrl);
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
    String? title,
    this.bytes,
    this.width = 0,
    this.height = 0,
    this.duration = Duration.zero,
  })  : id = filePath.hashCode.toRadixString(36),
        title = title ?? filePath.split('/').last.split('\\').last,
        type = _inferType(title ?? filePath);

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
