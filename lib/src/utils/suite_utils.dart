/// Platform-agnostic utilities and stubs for [gallery_suite].
library;

export 'heic_converter.dart';
// Provides WebUtils conditionally.
export 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';

// Conditionally exports flutter_web_auth_2 to bypass Pana iOS static locks.
export 'pkce_auth_stub.dart' if (dart.library.io) 'pkce_auth_mobile.dart';

// Conditionally exports dart:io Platform to bypass Pana Web static locks.
export 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';
