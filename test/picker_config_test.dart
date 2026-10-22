import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_suite/gallery_suite.dart';
import 'package:photo_manager/photo_manager.dart' show RequestType;

void main() {
  group('PickerConfig defaults', () {
    test('exposes sensible defaults for an image picker', () {
      const config = PickerConfig();

      expect(config.requestType, RequestType.image);
      expect(config.maxSelection, 10);
      expect(config.gridLayout, PickerGridLayout.masonry);
      expect(config.defaultSortOrder, PickerSortOrder.newest);
      expect(config.enableSorting, isTrue);
      expect(config.showCameraTile, isTrue);
      expect(config.enableSwipeToSelect, isTrue);
      expect(config.enableSmartClipboard, isFalse);
      expect(config.useOriginalFile, isFalse);
      expect(config.autoCompressImages, isFalse);
      expect(config.imageCompressionQuality, 85);
      expect(config.thumbnailCacheSize, 200);
      expect(config.maxConcurrentDecodes, 3);
      expect(config.prefetchEnabled, isTrue);
      expect(config.customGridBuilder, isNull);
    });
  });

  group('PickerConfig grid layout', () {
    test('accepts every built-in layout', () {
      for (final layout in PickerGridLayout.values) {
        final config = PickerConfig(
          gridLayout: layout,
          customGridBuilder: layout == PickerGridLayout.byog
              ? (context, scrollController, itemCount, itemBuilder) =>
                    const SizedBox.shrink()
              : null,
        );
        expect(config.gridLayout, layout);
      }
    });

    test('requires a customGridBuilder for the BYOG layout', () {
      expect(
        () => PickerConfig(gridLayout: PickerGridLayout.byog),
        throwsA(isA<AssertionError>()),
      );
    });

    test('does not require a customGridBuilder for the built-in layouts', () {
      expect(
        () => const PickerConfig(gridLayout: PickerGridLayout.quilted),
        returnsNormally,
      );
    });
  });

  group('PickerConfig hooks', () {
    test('keeps the BYOC compressor and the BYOE editor references', () {
      final config = PickerConfig(
        onCompressMedia: (context, asset, file) async => null,
        onEditMedia: (context, asset, file) async => null,
      );

      expect(config.onCompressMedia, isNotNull);
      expect(config.onEditMedia, isNotNull);
    });
  });

  group('PickerConfig theme', () {
    test('applies a custom theme on top of the default one', () {
      const config = PickerConfig(
        themeData: PickerThemeData(background: Color(0xFF102030)),
      );

      expect(config.themeData?.background, const Color(0xFF102030));
    });

    test('falls back to the default palette when no override is given', () {
      const theme = PickerTheme(false);

      expect(theme.background, const Color(0xFFF2F2F7));
      expect(theme.surface, const Color(0xFFFFFFFF));
    });

    test('applies the overrides on top of the default palette', () {
      const theme = PickerTheme(
        false,
        PickerThemeData(surface: Color(0xFF00FF00)),
      );

      expect(theme.surface, const Color(0xFF00FF00));
      expect(theme.background, const Color(0xFFF2F2F7));
    });
  });
}
