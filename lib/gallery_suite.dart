/// Gallery Suite — Premium in-app media picker for Flutter.
///
/// This is the public API barrel file. Import *only* this file:
///
/// ```dart
/// import 'package:gallery_suite/gallery_suite.dart';
/// ```
library;

// ── Core entry point ────────────────────────────────────────────────────────
export 'src/picker_page.dart' show CustomMediaPicker;

// ── Configuration & models ──────────────────────────────────────────────────
export 'src/models/picker_config.dart' show PickerConfig;
export 'src/models/media_item.dart' show MediaItem;
export 'src/models/picker_theme.dart' show PickerTheme;

// ── Services ────────────────────────────────────────────────────────────────
export 'src/services/media_service.dart' show MediaService;

// ── Camera ──────────────────────────────────────────────────────────────────
export 'src/pages/camera_screen.dart' show CameraCaptureMode;
