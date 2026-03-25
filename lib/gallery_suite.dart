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
// export 'src/models/picker_config.dart' show PickerConfig;
// export 'src/models/google_photo_config.dart' show GooglePhotosConfig;
// export 'src/models/media_item.dart' show MediaItem;
// export 'src/models/picker_asset.dart';
// export 'src/models/picker_theme.dart' show PickerTheme;
// export 'src/models/exit_confirmation.dart';
export 'src/models/suite_models.dart';

// ── Services ────────────────────────────────────────────────────────────────
export 'src/services/media_service.dart' show MediaService;
export 'src/services/google_photos_service.dart' show GooglePhotosService;

// ── Camera ──────────────────────────────────────────────────────────────────
export 'src/pages/camera_screen.dart';

// ── Internationalization (Intl) ─────────────────────────────────────────────
export 'src/intl/picker_text_delegate.dart';
export 'src/intl/english_picker_text_delegate.dart';
export 'src/intl/french_picker_text_delegate.dart';

// ── Services ────────────────────────────────────────────────────────
export 'src/services/suite_services.dart';

// ── Enum ────────────────────────────────────────────────────────
export 'src/enum/enum.dart';

// ── Widgets ────────────────────────────────────────────────────────
export 'src/widgets/suite_widgets.dart';

// ── Pages ────────────────────────────────────────────────────────
export 'src/pages/suite_pages.dart';
