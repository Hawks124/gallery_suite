import 'dart:io';

/// Web-compatible stub for NativeMediaCompressor.
/// Since Web does not support native `flutter_image_compress` bridges
/// and relies on JS Canvas (future scope), this gracefully bypasses compression
/// without causing a MissingPluginException or path_provider Web block.
class NativeMediaCompressor {
  static Future<File> convertHeicIfNeeded(File file) async {
    return file;
  }

  static Future<File> compressImage(File file, int quality) async {
    return file;
  }
}
