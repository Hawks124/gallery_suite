import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_suite/gallery_suite.dart';

void main() {
  group('ThumbnailDecodeQueue cache', () {
    test('stores and returns an entry', () {
      final queue = ThumbnailDecodeQueue();
      final data = Uint8List.fromList([1, 2, 3]);

      queue.put('a', data);
      final cached = queue.get('a');
      final state = (count: queue.cacheEntryCount, bytes: queue.cacheByteCount);

      expect(cached, data);
      expect(state.count, 1);
      expect(state.bytes, 3);
    });

    test('returns null for an unknown key', () {
      final queue = ThumbnailDecodeQueue();

      expect(queue.get('missing'), isNull);
    });

    test('evicts the least recently used entry when the cache is full', () {
      final queue = ThumbnailDecodeQueue(maxCacheEntries: 2);

      for (final key in ['a', 'b', 'c']) {
        queue.put(key, Uint8List(1));
      }

      final state = (
        count: queue.cacheEntryCount,
        a: queue.get('a'),
        b: queue.get('b'),
        c: queue.get('c'),
      );

      expect(state.count, 2);
      expect(state.a, isNull);
      expect(state.b, isNotNull);
      expect(state.c, isNotNull);
    });

    test('keeps the entry that was just read', () {
      final queue = ThumbnailDecodeQueue(maxCacheEntries: 2);

      for (final key in ['a', 'b']) {
        queue.put(key, Uint8List(1));
      }
      // Reading 'a' makes it the most recently used entry.
      final firstRead = queue.get('a');
      queue.put('c', Uint8List(1));

      final state = (a: queue.get('a'), b: queue.get('b'));
      expect(firstRead, isNotNull);
      expect(state.a, isNotNull);
      expect(state.b, isNull);
    });

    test('evicts the oldest entries when the byte budget is exceeded', () {
      final queue = ThumbnailDecodeQueue(maxCacheBytes: 10);

      for (final key in ['a', 'b']) {
        queue.put(key, Uint8List(6));
      }

      final state = (count: queue.cacheEntryCount, bytes: queue.cacheByteCount);
      expect(state.bytes, lessThanOrEqualTo(10));
      expect(state.count, 1);
    });

    test('replacing an entry does not double count its bytes', () {
      final queue = ThumbnailDecodeQueue();

      for (var i = 0; i < 2; i++) {
        queue.put('a', Uint8List(4));
      }

      final state = (count: queue.cacheEntryCount, bytes: queue.cacheByteCount);
      expect(state.bytes, 4);
      expect(state.count, 1);
    });

    test('clearAll resets the cache', () {
      final queue = ThumbnailDecodeQueue();

      queue.put('a', Uint8List(4));
      queue.clearAll();

      final state = (count: queue.cacheEntryCount, bytes: queue.cacheByteCount);
      expect(state.count, 0);
      expect(state.bytes, 0);
    });
  });

  group('ThumbnailDecodeQueue queue', () {
    test('starts with nothing pending', () {
      final queue = ThumbnailDecodeQueue();

      expect(queue.pendingCount, 0);
    });

    test('cancelPending drops every scheduled request', () {
      final queue = ThumbnailDecodeQueue();

      queue.cancelPending();
      final pending = queue.pendingCount;

      expect(pending, 0);
    });
  });
}
