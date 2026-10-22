// Enumerated types used throughout the Gallery Suite.

// The capture mode for the built-in camera screen.
enum CameraCaptureMode {
  // Capture a still photo.
  photo,

  // Record a video.
  video,
}

/// Defines the visual layout style of the media grid.
///
/// Each layout maps to a specific delegate from `flutter_staggered_grid_view`.
/// All layouts are fully scrollable and support lazy pagination.
enum PickerGridLayout {
  /// Default masonry layout with variable-height columns.
  /// Tiles are evenly divided into columns and can have different heights
  /// based on their natural aspect ratio.
  masonry,

  /// CSS Grid-style aligned layout.
  /// Rows can have different heights, but each tile in a given row shares
  /// the same height as the tallest tile in that row.
  aligned,

  /// Pattern-based layout that creates visual hierarchy using varied tile sizes.
  /// Tiles can span multiple rows and columns (e.g. 2×2, 1×1) following a
  /// repeating pattern. Uses [SliverQuiltedGridDelegate].
  quilted,

  /// Asymmetric interlocking layout where tiles occupy variable column spans,
  /// producing an organic, non-uniform visual pattern.
  /// Internally backed by [SliverQuiltedGridDelegate] with an asymmetric pattern
  /// to achieve scrollable staggered rendering.
  staggered,

  /// Bring Your Own Grid. Disables all built-in layouts and delegates rendering
  /// to the [PickerConfig.customGridBuilder] callback.
  byog,
}

/// Defines the sorting logic for local media assets.
enum PickerSortOrder {
  /// Most recent media first (Default).
  newest,

  /// Oldest media first.
  oldest,

  /// Largest file size first.
  largest,

  /// Smallest file size first.
  smallest,
}
