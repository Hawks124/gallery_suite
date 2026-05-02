/// Gallery Suite — Premium in-app media picker for Flutter.
///
/// This is the public API barrel file. Import *only* this file:
///
///
/// import 'package:gallery_suite/gallery_suite.dart';
///
library;

// ── Core entry point ────────────────────────────────────────────────────────
export 'src/picker_page.dart' show CustomMediaPicker;

export 'src/models/suite_models.dart';

// ── Services ────────────────────────────────────────────────────────────────
export 'src/services/suite_services.dart';

// ── Camera ──────────────────────────────────────────────────────────────────
export 'src/pages/camera_screen.dart';

// ── Internationalization (Intl) ─────────────────────────────────────────────
export 'src/intl/suite_intl.dart';

// ── Enum ────────────────────────────────────────────────────────
export 'src/enum/enum.dart';

// ── Widgets ────────────────────────────────────────────────────────
export 'src/widgets/suite_widgets.dart';

// ── Pages ────────────────────────────────────────────────────────
export 'src/pages/suite_pages.dart';

// ── Providers ────────────────────────────────────────────────────────
export 'src/providers/suite_provider.dart';

// ── Sources (MediaSource Abstraction) ────────────────────────────────
export 'src/sources/suite_sources.dart';

// ── Utils ────────────────────────────────────────────────────────
export 'src/utils/suite_utils.dart';
