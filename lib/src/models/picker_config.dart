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
  /// The type of media to display.
  ///
  /// Use [RequestType.image] (default) for the masonry image grid,
  /// [RequestType.video] for the video grid with inline preview sheet,
  /// or [RequestType.audio] for the audio list with inline playback.
  final RequestType requestType;

  /// Maximum number of assets the user can select.
  ///
  /// Only applies to [RequestType.image]. Video and audio pickers
  /// are always single-select. Defaults to `10`.
  final int maxSelection;

  /// The primary accent color used for selection badges, the send button,
  /// seek bar tracks, and other interactive elements.
  ///
  /// Defaults to `Color(0xFF2E7D32)` (Material green 800).
  final Color primaryColor;

  /// Force a specific brightness for the picker UI.
  ///
  /// When `null` (default), the picker reads [MediaQuery.platformBrightness]
  /// from the surrounding context. Pass [Brightness.dark] or
  /// [Brightness.light] to pin the theme regardless of system settings.
  final Brightness? brightness;

  /// Label for the send / confirm button that appears in the AppBar once
  /// at least one asset is selected. Defaults to `'Envoyer'`.
  final String confirmText;

  /// Label for the cancel button that dismisses the picker without a
  /// selection. Defaults to `'Annuler'`.
  final String cancelText;

  /// Creates a [PickerConfig] with the given options.
  ///
  /// All parameters are optional — calling `const PickerConfig()` gives you
  /// a sensible image picker with up to 10 items selectable.
  const PickerConfig({
    this.maxSelection = 10,
    this.requestType = RequestType.image,
    this.primaryColor = const Color(0xFF2E7D32),
    this.brightness,
    this.confirmText = 'Envoyer',
    this.cancelText = 'Annuler',
  });
}
