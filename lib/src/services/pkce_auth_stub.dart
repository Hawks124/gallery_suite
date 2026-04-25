Future<String> authenticate({
  required String url,
  required String callbackUrlScheme,
}) {
  throw UnsupportedError('PKCE not supported on this platform');
}
