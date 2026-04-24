import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Background utility to safely convert iOS HEIC/HEVC photos to JPG and
/// dynamically compress images natively.
class NativeMediaCompressor {
  /// Inspects the file and converts it to JPG if it is a HEIC/HEVC file.
  /// Uses highly optimized native bridges (Objective-C/Swift) via `flutter_image_compress`.
  /// Safe to call on any file: if it's not HEIC, it is returned immediately.
  static Future<File> convertHeicIfNeeded(File file) async {
    if (kIsWeb) return file;

    final lowerPath = file.path.toLowerCase();
    final isHeic = lowerPath.endsWith('.heic') || lowerPath.endsWith('.hevc');

    if (!isHeic) {
      return file;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/heic_conv_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final xFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 95,
      );

      if (xFile != null) {
        return File(xFile.path);
      }
    } catch (e) {
      debugPrint(
          '[HeicConverter] Fallback - Native HEIC compression failed: $e');
    }

    // If conversion crashes (e.g unsupported device), return original defensively
    return file;
  }

  /// Drastically reduces image file sizes natively using highly optimized bridges.
  /// Does NOT process video files.
  static Future<File> compressImage(File file, int quality) async {
    if (kIsWeb) return file;

    try {
      final tempDir = await getTemporaryDirectory();
      // Keep the original extension, but inject a timestamp buffer
      final ext = file.path.split('.').last;
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final xFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
      );

      if (xFile != null) {
        return File(xFile.path);
      }
    } catch (e) {
      debugPrint(
          '[NativeMediaCompressor] General native compression failed: $e');
    }

    return file;
  }
}
