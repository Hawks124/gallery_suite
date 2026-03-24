/// Configuration for the built-in Google Photos integration.
class GooglePhotosConfig {
  /// Whether the Google Photos tab is enabled. Defaults to `true`.
  final bool enabled;

  /// Optional Android/iOS OAuth client ID for non-Firebase setups.
  final String? clientId;

  /// Optional Web OAuth matching ID for backend exchanges.
  final String? serverClientId;

  const GooglePhotosConfig({
    this.enabled = true,
    this.clientId,
    this.serverClientId,
  });
}
