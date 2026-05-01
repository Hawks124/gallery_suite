import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'picker_theme.dart';
import 'exit_confirmation.dart';
import '../intl/picker_text_delegate.dart';
import '../intl/english_picker_text_delegate.dart';

/// Configuration for the standalone [CustomMediaPicker.camera] entry point.
class CameraPickerConfig {
  /// Maximum number of photos a user can take in a single "rafale" session.
  /// If set to 1, the multiple-capture thumbnail strip automatically hides.
  /// Note: Video recording inherently restricts the session to 1 regardless of this value.
  final int maxSelection;

  /// Whether to allow recording video. Defaults to `true`.
  /// If `true`, a long press on the shutter will record video (if maxSelection permits).
  final bool enableVideo;

  /// Whether to record audio when capturing video. Defaults to `true`.
  final bool enableAudio;

  /// Primary action color for the camera UI elements (e.g. shutter ring, checkmark).
  final Color primaryColor;

  /// Fixed brightness of the camera. If null, follows the system brightness.
  /// (Standalone cameras usually default to Brightness.dark for contrast).
  final Brightness? brightness;

  /// Detailed token overrides for standardizing brand styling.
  final PickerThemeData? themeData;

  /// Optional BYOE (Bring Your Own Editor) hook.
  /// Standardizes editing behaviour in the full-screen capture preview.
  /// The `asset` argument is always `null` in standalone mode as the image is pure RAM/Disk.
  final Future<File?> Function(
      BuildContext context, AssetEntity? asset, File originalFile)? onEditMedia;

  /// Prevents accidental exits by warning the user if they press back while having captured photos.
  final ExitConfirmationConfig? exitConfirmation;

  /// Override the camera localization text.
  final PickerTextDelegate textDelegate;

  const CameraPickerConfig({
    this.maxSelection = 5,
    this.enableVideo = true,
    this.enableAudio = true,
    this.primaryColor = const Color(0xFF007AFF),
    this.brightness = Brightness.dark,
    this.themeData,
    this.onEditMedia,
    this.exitConfirmation,
    this.textDelegate = const EnglishPickerTextDelegate(),
  });
}
