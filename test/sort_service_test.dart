import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_suite/gallery_suite.dart';
import 'package:photo_manager/photo_manager.dart' show BaseFilterType;

void main() {
  group('SortService', () {
    final service = SortService.instance;

    test('is a singleton', () {
      expect(SortService(), same(SortService.instance));
    });

    test('never needs a filter for the default order', () {
      expect(service.nativeFilter(PickerSortOrder.newest), isNull);
    });

    test('builds an ascending date filter for the oldest order', () {
      final filter = service.nativeFilter(PickerSortOrder.oldest);

      expect(filter, isNotNull);
      expect(filter!.type, BaseFilterType.classical);
    });

    test('only offers the size orders when the platform can resolve them', () {
      final supportsSize = service.supportedOrders.contains(
        PickerSortOrder.largest,
      );

      if (supportsSize) {
        expect(service.nativeFilter(PickerSortOrder.largest), isNotNull);
        expect(service.nativeFilter(PickerSortOrder.smallest), isNotNull);
      } else {
        // The size must never be faked: without a real size column the
        // order is simply not offered by the sort sheet.
        expect(service.nativeFilter(PickerSortOrder.largest), isNull);
        expect(service.nativeFilter(PickerSortOrder.smallest), isNull);
      }
    });

    test('always supports the date based orders', () {
      expect(service.isSupported(PickerSortOrder.newest), isTrue);
      expect(service.isSupported(PickerSortOrder.oldest), isTrue);
    });
  });

  group('PickerSortOrder', () {
    test('exposes the four documented orders', () {
      expect(PickerSortOrder.values, [
        PickerSortOrder.newest,
        PickerSortOrder.oldest,
        PickerSortOrder.largest,
        PickerSortOrder.smallest,
      ]);
    });
  });
}
