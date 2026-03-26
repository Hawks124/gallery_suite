/// Configuration for Google Photos cloud integration.
library;

/// Configuration for the built-in Google Photos integration.
class GooglePhotosConfig {
  /// Whether the Google Photos tab is enabled. Defaults to `true`.
  final bool enabled;

  /// Deprecated('Pass the clientId directly to GooglePhotosService.instance.init() instead.')
  final String? clientId;

  /// Deprecated('The Picker API uses PKCE and does not require a serverClientId.')
  final String? serverClientId;

  /// Creates a [GooglePhotosConfig] instance.
  const GooglePhotosConfig({
    this.enabled = true,
    @Deprecated('Use GooglePhotosService.instance.init()') this.clientId,
    @Deprecated('Use GooglePhotosService.instance.init()') this.serverClientId,
  });
}
