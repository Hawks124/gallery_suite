import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

Future<String> authenticate({
  required String url,
  required String callbackUrlScheme,
}) {
  return FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrlScheme,
  );
}
