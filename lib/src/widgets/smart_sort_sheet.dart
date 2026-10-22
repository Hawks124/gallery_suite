import 'package:flutter/material.dart';
import '../../gallery_suite.dart';

/// A premium, glassmorphic-inspired bottom sheet for selecting the internal sorting
/// mechanism of local media assets.
class SmartSortSheet extends StatelessWidget {
  final PickerSortOrder currentSortOrder;
  final Color primaryColor;
  final PickerTheme theme;
  final PickerTextDelegate textDelegate;
  final ValueChanged<PickerSortOrder> onSelect;

  /// The orders the current media source is able to honour.
  ///
  /// Byte-size ordering is only offered when the underlying platform can
  /// really resolve the size of an asset.
  final Set<PickerSortOrder> supportedOrders;

  const SmartSortSheet({
    required this.currentSortOrder,
    required this.primaryColor,
    required this.theme,
    required this.textDelegate,
    required this.onSelect,
    this.supportedOrders = const {
      PickerSortOrder.newest,
      PickerSortOrder.oldest,
      PickerSortOrder.largest,
      PickerSortOrder.smallest,
    },
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: theme.separator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.primaryText, size: 22),
                const SizedBox(width: 12),
                Text(
                  textDelegate.sortMediaTitle,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, color: theme.divider),
          if (supportedOrders.contains(PickerSortOrder.newest))
            _buildSortTile(
              textDelegate.sortNewestFirst,
              PickerSortOrder.newest,
              Icons.access_time_rounded,
            ),
          if (supportedOrders.contains(PickerSortOrder.oldest)) ...[
            if (supportedOrders.contains(PickerSortOrder.newest))
              Divider(height: 0.5, color: theme.divider, indent: 56),
            _buildSortTile(
              textDelegate.sortOldestFirst,
              PickerSortOrder.oldest,
              Icons.history_rounded,
            ),
          ],
          if (supportedOrders.contains(PickerSortOrder.largest)) ...[
            Divider(height: 0.5, color: theme.divider, indent: 56),
            _buildSortTile(
              textDelegate.sortLargestFirst,
              PickerSortOrder.largest,
              Icons.arrow_circle_up_rounded,
            ),
          ],
          if (supportedOrders.contains(PickerSortOrder.smallest)) ...[
            Divider(height: 0.5, color: theme.divider, indent: 56),
            _buildSortTile(
              textDelegate.sortSmallestFirst,
              PickerSortOrder.smallest,
              Icons.arrow_circle_down_rounded,
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSortTile(String title, PickerSortOrder order, IconData icon) {
    final isSelected = currentSortOrder == order;
    return InkWell(
      onTap: () => onSelect(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.1)
                    : theme.elevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : theme.secondaryText,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? theme.primaryText : theme.secondaryText,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 24),
          ],
        ),
      ),
    );
  }
}
