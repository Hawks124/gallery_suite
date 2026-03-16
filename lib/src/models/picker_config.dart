import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Configuration for [CustomMediaPicker].
///
/// Pass a [PickerConfig] to [CustomMediaPicker.show] to control which media
/// type is shown, how many items the user can select, the accent color,
/// and the UI labels.
///
/// Example:
/// ```dart
/// final assets = await CustomMediaPicker.show(
///   context: context,
///   config: PickerConfig(
///     requestType: RequestType.image,
///     maxSelection: 10,
///     primaryColor: Colors.deepPurple,
///     brightness: Theme.of(context).brightness,
///   ),
/// );
/// ```
class PickerConfig {
  /// The type of media to request (image, video, or audio).
  final RequestType requestType;

  /// Maximum number of selectable assets. Default is 10.
  final int maxSelection;

  /// Whether to show the live Camera tile as the first item in the grid.
  /// Defaults to `true`. Effective only for image and video modes.
  final bool showCameraTile;

  /// Whether to enable iOS-style "swipe to select" when dragging across the grid.
  /// Defaults to `true`.
  final bool enableSwipeToSelect;

  /// Primary accent color used for selections, buttons, and animations.
  final Color primaryColor;

  /// Force a specific brightness for the picker UI.
  ///
  /// When `null` (default), the picker reads [MediaQuery.platformBrightness]
  /// from the surrounding context. Pass [Brightness.dark] or
  /// [Brightness.light] to pin the theme regardless of system settings.
  final Brightness? brightness;

  /// Label for the send / confirm button that appears in the AppBar once
  /// at least one asset is selected. Defaults to `'Sélectionner'`.
  final String confirmText;

  /// Label for the cancel button that dismisses the picker without a
  /// selection. Defaults to `'Annuler'`.
  final String cancelText;

  /// Creates a [PickerConfig] with the given options.
  ///
  /// All parameters are optional — calling `const PickerConfig()` gives you
  /// a sensible image picker with up to 10 items selectable.
  const PickerConfig({
    this.requestType = RequestType.image,
    this.maxSelection = 10,
    this.showCameraTile = true,
    this.enableSwipeToSelect = true,
    this.primaryColor = const Color(0xFF007AFF),
    this.brightness,
    this.confirmText = 'Sélectionner',
    this.cancelText = 'Annuler',
  });
}
