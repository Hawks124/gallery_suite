// Database-level ordering for the media grid.
//
// The order is pushed down to the operating system whenever the platform
// exposes a sortable column. This keeps the pagination intact and avoids
// materialising the whole library in Dart just to reorder it.

import 'package:photo_manager/photo_manager.dart';

import '../enum/enum.dart';
import '../utils/suite_utils.dart' show Platform;

/// Builds the native gallery filters used to order the media grid.
class SortService {
  /// The singleton instance of [SortService].
  static final SortService instance = SortService._internal();

  /// Returns the global instance of [SortService].
  factory SortService() => instance;

  SortService._internal();

  /// The sort orders the current platform can express natively.
  ///
  /// Byte-size ordering requires the gallery database to expose a size
  /// column, which only Android does (`MediaStore._size`). iOS and macOS do
  /// not expose the byte size of an asset, so the option is simply not
  /// offered there instead of faking it with a resolution proxy.
  Set<PickerSortOrder> get supportedOrders {
    if (Platform.isAndroid) {
      return const {
        PickerSortOrder.newest,
        PickerSortOrder.oldest,
        PickerSortOrder.largest,
        PickerSortOrder.smallest,
      };
    }
    return const {PickerSortOrder.newest, PickerSortOrder.oldest};
  }

  /// Whether [sortOrder] can be honoured by the current platform.
  bool isSupported(PickerSortOrder sortOrder) =>
      supportedOrders.contains(sortOrder);

  /// Returns the native filter ordering the gallery by [sortOrder].
  ///
  /// Returns `null` when [sortOrder] is the default one — the gallery is
  /// already returned newest first — or when the platform cannot express
  /// the order natively.
  PMFilter? nativeFilter(PickerSortOrder sortOrder) {
    switch (sortOrder) {
      case PickerSortOrder.newest:
        return null;
      case PickerSortOrder.oldest:
        return FilterOptionGroup(orders: [const OrderOption(asc: true)]);
      case PickerSortOrder.largest:
        return _sizeFilter(isAsc: false);
      case PickerSortOrder.smallest:
        return _sizeFilter(isAsc: true);
    }
  }

  /// Orders the gallery by the real byte size of each asset.
  ///
  /// Only Android exposes the size as a sortable database column, so the
  /// filter is `null` everywhere else.
  PMFilter? _sizeFilter({required bool isAsc}) {
    if (!Platform.isAndroid) return null;
    return AdvancedCustomFilter().addOrderBy(
      column: CustomColumns.android.size,
      isAsc: isAsc,
    );
  }
}
