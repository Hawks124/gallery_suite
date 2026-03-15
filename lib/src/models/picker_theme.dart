import 'package:flutter/services.dart';

class PickerTheme {
  final bool isDark;

  const PickerTheme(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  Color get surface =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  Color get elevated =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  Color get primaryText =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get secondaryText =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
  Color get separator =>
      isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
  Color get divider =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
  Color get shimmerBase =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
  Color get shimmerHighlight =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  SystemUiOverlayStyle get overlayStyle =>
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}
