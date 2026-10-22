import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_suite/gallery_suite.dart';

void main() {
  group('RemotePickerAsset', () {
    const remote = RemotePickerAsset(
      id: 'remote-1',
      baseUrl: 'https://example.com/media/photo',
      title: 'Cloud photo',
      width: 1920,
      height: 1080,
    );

    test('exposes the cloud metadata', () {
      expect(remote.id, 'remote-1');
      expect(remote.title, 'Cloud photo');
      expect(remote.width, 1920);
      expect(remote.height, 1080);
      expect(remote.type, AssetType.image);
      expect(remote.duration, Duration.zero);
    });

    test('builds a resized thumbnail url for images', () {
      expect(remote.thumbUrl, 'https://example.com/media/photo=w400-h400-c');
    });

    test('builds a video thumbnail url with the -v flag', () {
      const video = RemotePickerAsset(
        id: 'remote-2',
        baseUrl: 'https://example.com/media/clip',
        type: AssetType.video,
      );

      expect(video.thumbUrl, 'https://example.com/media/clip=w400-h400-c-v');
    });

    test('keeps signed picker-api urls untouched', () {
      const signed = RemotePickerAsset(
        id: 'remote-3',
        baseUrl: 'https://example.com/ppa/signed-blob',
      );

      expect(signed.thumbUrl, 'https://example.com/ppa/signed-blob');
      expect(signed.fullUrl, 'https://example.com/ppa/signed-blob');
    });

    test('round-trips through json', () {
      final restored = RemotePickerAsset.fromJson(remote.toJson());

      expect(restored.id, remote.id);
      expect(restored.baseUrl, remote.baseUrl);
      expect(restored.title, remote.title);
      expect(restored.width, remote.width);
      expect(restored.height, remote.height);
      expect(restored.type, remote.type);
      expect(restored.duration, remote.duration);
    });
  });

  group('FilePickerAsset', () {
    test('infers the asset type from the extension', () {
      expect(FilePickerAsset(filePath: '/tmp/a.jpg').type, AssetType.image);
      expect(FilePickerAsset(filePath: '/tmp/a.MP4').type, AssetType.video);
      expect(FilePickerAsset(filePath: '/tmp/a.mp3').type, AssetType.audio);
    });

    test('derives the title from the file name', () {
      expect(
        FilePickerAsset(filePath: '/tmp/holiday.jpg').title,
        'holiday.jpg',
      );
    });

    test('keeps the real byte size and modification date', () {
      final asset = FilePickerAsset(
        filePath: '/tmp/a.jpg',
        byteSize: 4096,
        lastModified: DateTime.utc(2026, 1, 2),
      );

      expect(asset.byteSize, 4096);
      expect(asset.lastModified, DateTime.utc(2026, 1, 2));
    });
  });

  group('MediaItem', () {
    test('wraps a remote asset', () {
      const item = MediaItem.remote(
        remoteAsset: RemotePickerAsset(
          id: 'remote-1',
          baseUrl: 'https://example.com/media/photo',
        ),
      );

      expect(item.isRemote, isTrue);
      expect(item.isLocal, isFalse);
      expect(item.isFile, isFalse);
      expect(item.id, 'remote-1');
      expect(item.isImage, isTrue);
      expect(item.isVideo, isFalse);
      expect(item.isAudio, isFalse);
    });

    test('wraps a file asset', () {
      final item = MediaItem.file(
        fileAsset: FilePickerAsset(filePath: '/tmp/clip.mp4'),
      );

      expect(item.isFile, isTrue);
      expect(item.isRemote, isFalse);
      expect(item.isVideo, isTrue);
      expect(item.title, 'clip.mp4');
    });

    test('falls back to a square aspect ratio when dimensions are unknown', () {
      final item = MediaItem.file(
        fileAsset: FilePickerAsset(filePath: '/tmp/a.jpg'),
      );

      expect(item.aspectRatio, 1.0);
    });

    test('computes the aspect ratio from the real dimensions', () {
      final item = MediaItem.file(
        fileAsset: FilePickerAsset(
          filePath: '/tmp/a.jpg',
          width: 1920,
          height: 1080,
        ),
      );

      expect(item.aspectRatio, closeTo(16 / 9, 0.0001));
    });
  });
}
