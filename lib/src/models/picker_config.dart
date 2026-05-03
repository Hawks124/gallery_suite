// Configuration models for the Gallery Suite picker.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:file_selector/file_selector.dart';

import '../../gallery_suite.dart';

// Configuration for [CustomMediaPicker].
//
// Pass a [PickerConfig] to [CustomMediaPicker.show] to control which media
// type is shown, how many items the user can select, the accent color,
// and the UI labels.
//
// Example:
// ```dart
// final assets = await CustomMediaPicker.show(
//   context: context,
//   config: PickerConfig(
//     requestType: RequestType.image,
//     maxSelection: 10,
//     primaryColor: Colors.deepPurple,
//     brightness: Theme.of(context).brightness,
//   ),
// );
// ```
class PickerConfig {
  // The type of media to request (image, video, or audio).
  final RequestType requestType;

  // Maximum number of selectable assets. Default is 10.
  final int maxSelection;

  // The visual grid layout behavior. Defaults to [PickerGridLayout.masonry].
  final PickerGridLayout gridLayout;

  // Bring Your Own Grid builder. Required if [gridLayout] is [PickerGridLayout.byog].
  //
  // It provides the [ScrollController], the total [itemCount], and an [itemBuilder]
  // that automatically wraps each item with the necessary GestureDetector, Hero,
  // Selection markers, and Player overlays. You simply return a grid/list widget.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilder,
  )? customGridBuilder;

  // The default sort order for local media. Defaults to [PickerSortOrder.newest].
  final PickerSortOrder defaultSortOrder;

  // Whether to show the sorting dropdown in the UI. Defaults to `true`.
  final bool enableSorting;

  // Whether to show the live Camera tile as the first item in the grid.
  // Defaults to `true`. Effective only for image and video modes.
  final bool showCameraTile;

  // Whether to enable iOS-style "swipe to select" when dragging across the grid.
  // Defaults to `true`.
  final bool enableSwipeToSelect;

  // Primary accent color used for selections, buttons, and animations.
  final Color primaryColor;

  // Force a specific brightness for the picker UI.
  //
  // When `null` (default), the picker reads [MediaQuery.platformBrightness]
  // from the surrounding context. Pass [Brightness.dark] or
  // [Brightness.light] to pin the theme regardless of system settings.
  final Brightness? brightness;

  // Label for the send / confirm button that appears in the AppBar once
  // at least one asset is selected. Defaults to `'Sélectionner'`.
  @Deprecated(
      'Use textDelegate.confirm instead. This field will be removed in v2.0.0.')
  final String confirmText;

  // Label for the cancel button that dismisses the picker without a
  // selection. Defaults to `'Annuler'`.
  @Deprecated(
      'Use textDelegate.cancel instead. This field will be removed in v2.0.0.')
  final String cancelText;

  // Handles all text localization within the picker.
  // Defaults to [EnglishPickerTextDelegate].
  final PickerTextDelegate textDelegate;

  // Whether to use the original, uncompressed file (guaranteed unchanged by the OS).
  //
  // On iOS, `photo_manager` may sometimes return a compressed or converted
  // image (e.g. HEIC -> JPG) when accessing the asset file. Setting this to
  // `true` ensures you receive the pristine `.originFile`.
  // Defaults to `false` (which prefers speed / OS-level compatibility over pristine quality).
  final bool useOriginalFile;

  // -- Performance Tuning ------------------------------------------------------

  // Maximum number of thumbnails kept in the LRU cache.
  //
  // Higher values use more memory but reduce re-decoding when scrolling
  // back and forth. Defaults to `200` (~2 3 screens of content).
  final int thumbnailCacheSize;

  // Maximum number of thumbnails decoded simultaneously.
  //
  // Lower values reduce frame drops at the cost of slightly slower
  // initial loading. Defaults to `3`.
  final int maxConcurrentDecodes;

  // Whether to pre-load thumbnails for items just off-screen during scroll.
  //
  // When `true` (default), the picker pre-warms the cache for the next
  // ~30 items in the scroll direction, eliminating visible pop-in.
  final bool prefetchEnabled;

  // Detailed theme overrides for backgrounds, surfaces, and text colors.
  //
  // When provided, these colors take precedence over the defaults resolved
  // from [brightness].
  final PickerThemeData? themeData;

  // Optional configuration to prevent accidental exits.
  //
  // If the user has selected or edited items and attempts to exit (via back button
  // or the Cancel button), this configuration will intercept the exit and show
  // a confirmation dialog. Use [StandardExitConfirmation] for a beautiful built-in
  // UI, or [CustomExitConfirmation] to return your own dialog Future.
  final ExitConfirmationConfig? exitConfirmation;

  // Callback fired when the user taps an image in the selected strip.
  //
  // You can use this to launch your own external image editor (like `pro_image_editor`).
  // If the user saves the edit, return the new [File]. The picker will instantly update
  // the UI and return the edited file in the final result.
  //
  // Requires [RequestType.image] or mixed mode.
  final Future<File?> Function(
      BuildContext context, AssetEntity asset, File originalFile)? onEditMedia;

  // Configuration for the Google Photos cloud provider.
  final GooglePhotosConfig googlePhotosConfig;

  // Pre-selected assets passed by the developer.
  //
  // Use this to re-open the picker with items already selected (e.g. editing
  // an existing post draft). The picker will automatically match the IDs of
  // these items and display them as selected in the grid.
  final List<MediaItem>? initialSelection;

  /// Whether to enable the Smart Clipboard integration.
  ///
  /// When `true`, the picker's album sheet will display a "Clipboard" tile
  /// (after Google Photos, before local albums). Tapping it scans the system
  /// clipboard for copied images, videos, audio files, or media URLs and
  /// displays them in an isolated grid for selection.
  ///
  /// **Android Setup Required:** This feature depends on the `pasteboard`
  /// package. On Android, you must add a `<provider>` entry and a
  /// `provider_paths.xml` file. See the README for the full setup guide.
  ///
  /// Defaults to `false` (opt-in).
  final bool enableSmartClipboard;

  // -- Hybrid Smart Compression -----------------------------------------------

  /// **Native Built-in Compressor**
  ///
  /// Set this to `true` to magically compress large local images using highly
  /// optimized native bridges (C/Objective-C/Swift via `flutter_image_compress`).
  /// This drastically reduces payload bytes with near zero visual quality loss.
  /// Disabled by default to prevent unexpected changes to legacy configurations.
  final bool autoCompressImages;

  /// The target JPEG compression quality (0-100) used when [autoCompressImages] is `true`.
  /// A value of 85 usually retains extremely high visual fidelity while significantly reducing file size.
  final int imageCompressionQuality;

  /// **BYOC (Bring Your Own Compressor) Hook**
  ///
  /// Use this callback to intercept the `originalFile` right before the picker confirms.
  /// This is incredibly powerful for compressing **video files** using external plugins
  /// like `video_compress` or applying strict dimension limits.
  ///
  /// If this hook returns a `File`, it perfectly overrides the payload.
  /// The Picker UI handles the async wait state automatically with a beautiful loading spinner.
  ///
  /// *Note: This hook takes priority over [autoCompressImages].*
  final Future<File?> Function(
          BuildContext context, AssetEntity asset, File originalFile)?
      onCompressMedia;

  /// **BYOD (Bring Your Own Drop) Hook**
  ///
  /// Use this optional wrapper to wrap the core picker UI with your favorite
  /// Desktop Drag and Drop package (like `desktop_drop`).
  ///
  /// When a user drags a file into the window, the Picker automatically parses
  /// the dropped [XFile]s, decodes their metadata, and adds them to the top of
  /// the media grid as selectable [FilePickerAsset]s — without closing the picker.
  ///
  /// The `onFilesDropped` callback accepts a [List<XFile>], which maps perfectly
  /// to the output of `desktop_drop`'s `DropTarget.onDragDone`.
  ///
  /// ```dart
  /// dropRegionBuilder: (context, child, onFilesDropped) {
  ///   return DropTarget(
  ///     onDragDone: (details) => onFilesDropped(details.files),
  ///     child: child,
  ///   );
  /// }
  /// ```
  final Widget Function(BuildContext context, Widget child,
      ValueChanged<List<XFile>> onFilesDropped)? dropRegionBuilder;

  // Creates a [PickerConfig] with the given options.
  //
  // All parameters are optional - calling `const PickerConfig()` gives you
  // a sensible image picker with up to 10 items selectable.
  const PickerConfig({
    this.requestType = RequestType.image,
    this.maxSelection = 10,
    this.gridLayout = PickerGridLayout.masonry,
    this.customGridBuilder,
    this.defaultSortOrder = PickerSortOrder.newest,
    this.enableSorting = true,
    this.showCameraTile = true,
    this.enableSwipeToSelect = true,
    this.useOriginalFile = false,
    this.primaryColor = const Color(0xFF04395E),
    // this.primaryColor = const Color(0xFF007AFF),
    this.brightness,
    this.confirmText = 'Select',
    this.cancelText = 'Cancel',
    this.thumbnailCacheSize = 200,
    this.maxConcurrentDecodes = 3,
    this.prefetchEnabled = true,
    this.onEditMedia,
    this.themeData,
    this.exitConfirmation,
    this.textDelegate = const EnglishPickerTextDelegate(),
    this.googlePhotosConfig = const GooglePhotosConfig(),
    this.initialSelection,
    this.enableSmartClipboard = false,
    this.autoCompressImages = false,
    this.imageCompressionQuality = 85,
    this.onCompressMedia,
    this.dropRegionBuilder,
  }) : assert(
          gridLayout != PickerGridLayout.byog || customGridBuilder != null,
          'customGridBuilder is required when gridLayout is PickerGridLayout.byog',
        );
}
