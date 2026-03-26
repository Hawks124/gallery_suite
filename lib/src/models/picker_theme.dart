// UI styling and theme configuration tokens.

import 'package:flutter/services.dart';

// A set of optional color overrides for the [CustomMediaPicker].
//
// Use this to precisely control the background, surface, and text colors
// of the picker when the default light/dark themes are not enough.
//
// If a property is `null`, the picker will fall back to its intelligent
// default based on the provided [Brightness].
class PickerThemeData {
  // The main background color of the picker.
  final Color? background;

  // The surface color for cards, sheets, and dialogs.
  final Color? surface;

  // The elevated surface color (e.g. for hovered or pressed states).
  final Color? elevated;

  // The primary text color.
  final Color? primaryText;

  // The secondary (muted) text color.
  final Color? secondaryText;

  // The color used for thin separators and borders.
  final Color? separator;

  // The color used for thicker visual dividers.
  final Color? divider;

  // The base color for shimmer / skeleton loading placeholders.
  final Color? shimmerBase;

  // The highlight color for shimmer / skeleton loading placeholders.
  final Color? shimmerHighlight;

  // Creates a [PickerThemeData] with the specified color overrides.
  const PickerThemeData({
    this.background,
    this.surface,
    this.elevated,
    this.primaryText,
    this.secondaryText,
    this.separator,
    this.divider,
    this.shimmerBase,
    this.shimmerHighlight,
  });
}

// Provides a set of colors and styles for the picker UI based on brightness
// and optional [PickerThemeData] overrides.
class PickerTheme {
  // Whether the current theme is dark (`true`) or light (`false`).
  final bool isDark;

  // Optional custom color overrides.
  final PickerThemeData? _overrides;

  // Creates a [PickerTheme] for the given brightness mode and optional overrides.
  const PickerTheme(this.isDark, [this._overrides]);

  // The main background color of the picker.
  Color get background =>
      _overrides?.background ??
      (isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7));

  // The surface color for cards, sheets, and dialogs.
  Color get surface =>
      _overrides?.surface ??
      (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));

  // The elevated surface color (e.g. for hovered or pressed states).
  Color get elevated =>
      _overrides?.elevated ??
      (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));

  // The primary text color.
  Color get primaryText =>
      _overrides?.primaryText ??
      (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));

  // The secondary (muted) text color.
  Color get secondaryText =>
      _overrides?.secondaryText ??
      (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73));

  // The color used for thin separators and borders.
  Color get separator =>
      _overrides?.separator ??
      (isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8));

  // The color used for thicker visual dividers.
  Color get divider =>
      _overrides?.divider ??
      (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));

  // The base color for shimmer / skeleton loading placeholders.
  Color get shimmerBase =>
      _overrides?.shimmerBase ??
      (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA));

  // The highlight color for shimmer / skeleton loading placeholders.
  Color get shimmerHighlight =>
      _overrides?.shimmerHighlight ??
      (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7));

  // The system overlay style (status bar icons, etc.) matching this theme.
  SystemUiOverlayStyle get overlayStyle =>
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}
