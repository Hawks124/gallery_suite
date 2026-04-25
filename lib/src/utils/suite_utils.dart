/// Platform-agnostic utilities and stubs for [gallery_suite].
library;

export 'heic_converter_stub.dart' if (dart.library.io) 'heic_converter.dart';
// Provides WebUtils conditionally.
export 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';

// Conditionally exports dart:io Platform to bypass Pana Web static locks.
export 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';
