import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../gallery_suite.dart';

/// Routes the media grid to the correct layout delegate based on [PickerGridLayout].
///
/// All built-in layouts are fully scrollable and support lazy item building.
/// When [layout] is [PickerGridLayout.byog], rendering is delegated entirely
/// to the [customGridBuilder] callback provided via [PickerConfig].
class DynamicGridLayout extends StatelessWidget {
  final PickerGridLayout layout;
  final ScrollController scrollController;
  final int crossAxisCount;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilder,
  )? customGridBuilder;

  const DynamicGridLayout({
    super.key,
    required this.layout,
    required this.scrollController,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.customGridBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // BYOG: delegate rendering entirely to the consumer.
    if (layout == PickerGridLayout.byog && customGridBuilder != null) {
      return customGridBuilder!(
        context,
        scrollController,
        itemCount,
        itemBuilder,
      );
    }

    const double spacing = 1.5;
    const EdgeInsets padding = EdgeInsets.all(1.5);

    switch (layout) {
      case PickerGridLayout.aligned:
        return AlignedGridView.count(
          controller: scrollController,
          padding: padding,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );

      case PickerGridLayout.quilted:
        return GridView.builder(
          controller: scrollController,
          padding: padding,
          gridDelegate: SliverQuiltedGridDelegate(
            crossAxisCount: crossAxisCount.clamp(3, 12),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            repeatPattern: QuiltedGridRepeatPattern.inverted,
            pattern: const [
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 3),
            ],
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );

      case PickerGridLayout.staggered:
        // Asymmetric interlocking pattern backed by Quilted delegate
        // to achieve a scrollable staggered visual.
        return GridView.builder(
          controller: scrollController,
          padding: padding,
          gridDelegate: SliverQuiltedGridDelegate(
            crossAxisCount: crossAxisCount.clamp(3, 12),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            repeatPattern: QuiltedGridRepeatPattern.inverted,
            pattern: const [
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
            ],
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );

      case PickerGridLayout.masonry:
      default:
        return MasonryGridView.builder(
          controller: scrollController,
          padding: padding,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
    }
  }
}
