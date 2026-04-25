export 'heic_converter.dart';
export 'web_utils.dart';

/// Platform-agnostic Web Utilities Dispatcher
///
/// Conditionally exports the [`WebUtils`] implementation depending on the
/// compilation target. If `dart.library.html` is found (Web context), it uses
/// `web_utils_web.dart`. Otherwise, it injects the safe stub `web_utils_stub.dart`
/// to prevent `MissingPluginExceptions` and `dart:html` compilation errors on
/// iOS, Android, macOS, Linux, and Windows build environments.

export 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';
