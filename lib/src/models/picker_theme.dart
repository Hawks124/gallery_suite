import 'package:flutter/services.dart';

/// Provides a set of colors and styles for the picker UI based on brightness.
///
/// [PickerTheme] is used internally by the picker to resolve surface colors,
/// text colors, separators, and shimmer tones for both dark and light modes.
///
/// You do not need to construct this directly — the picker creates one based
/// on [PickerConfig.brightness] (or the system brightness if `null`).
class PickerTheme {
  /// Whether the current theme is dark (`true`) or light (`false`).
  final bool isDark;

  /// Creates a [PickerTheme] for the given brightness mode.
  const PickerTheme(this.isDark);

  /// The main background color of the picker.
  Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);

  /// The surface color for cards, sheets, and dialogs.
  Color get surface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);

  /// The elevated surface color (e.g. for hovered or pressed states).
  Color get elevated =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  /// The primary text color.
  Color get primaryText =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  /// The secondary (muted) text color.
  Color get secondaryText =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);

  /// The color used for thin separators and borders.
  Color get separator =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);

  /// The color used for thicker visual dividers.
  Color get divider =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  /// The base color for shimmer / skeleton loading placeholders.
  Color get shimmerBase =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);

  /// The highlight color for shimmer / skeleton loading placeholders.
  Color get shimmerHighlight =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

  /// The system overlay style (status bar icons, etc.) matching this theme.
  SystemUiOverlayStyle get overlayStyle =>
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}
