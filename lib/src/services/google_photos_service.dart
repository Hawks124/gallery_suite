// Google Photos Picker API service implementation.

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:photo_manager/photo_manager.dart';
import '../models/picker_asset.dart';

// A service that handles Google Sign-In authentication and securely communicates
// with the Google Photos Library API.
//
// On Android, this service uses PKCE OAuth2 via Chrome Custom Tabs to bypass
// the Android Credential Manager API limitation which blocks sensitive scopes.
// On iOS and Web, it uses the standard `google_sign_in` flow.
class GooglePhotosService {
  GooglePhotosService._();
  static final GooglePhotosService instance = GooglePhotosService._();

  // static const String _baseApiUrl =
  //     'https://photoslibrary.googleapis.com/v1/mediaItems';

  static const String _pickerApiUrl =
      'https://photospicker.googleapis.com/v1/sessions';

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/photospicker.mediaitems.readonly',
    'openid',
    'profile',
    'email',
  ];

  String? _redirectScheme;

  // [clientId] is used for PKCE flow on Android.
  //   On Android: This must be a "Desktop app" OAuth client ID from GCP.
  //   On iOS/Web: This is passed to google_sign_in (usually not needed there).
  String? _clientId;

  // [clientSecret] is only required on Android for the PKCE code exchange.
  // For Desktop app type OAuth clients, the secret is not sensitive.
  String? _clientSecret;

  // The OAuth2 Server/Web client ID, used by google_sign_in on iOS/Web.
  String? _serverClientId;

  GoogleSignInAccount? _currentUser;
  auth.AuthClient? _authClient;
  http.Client? _rawHttpClient;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  void setTokens(String? access, String? refresh, DateTime? expiry) {
    _accessToken = access;
    _refreshToken = refresh;
    _tokenExpiry = expiry;
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;

  String? apiKey;

  bool get isAuthenticated => _accessToken != null;
  String? get displayName => _currentUser?.displayName;
  String? get email => _currentUser?.email;
  String? get photoUrl => _currentUser?.photoUrl;

  static bool _initialized = false;

  void init({
    String? clientId,
    String? clientSecret,
    String? serverClientId,
    String? apiKey,
    String redirectScheme = 'gallerysuite',
  }) {
    _clientId = clientId;
    _clientSecret = clientSecret;
    _serverClientId = serverClientId;
    apiKey = apiKey;
    _redirectScheme = redirectScheme;
  }

  String get redirectScheme => _redirectScheme!;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: _clientId,
        serverClientId: _serverClientId,
      );
    } catch (e) {
      debugPrint('[GooglePhotosService] initialize() skipped: $e');
    }
    _initialized = true;
  }

  Future<bool> refreshAccessToken() async {
    if (_clientId == null || _refreshToken == null) return false;
    try {
      final tokenBody = {
        'client_id': _clientId!,
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
      };
      if (_clientSecret != null && _clientSecret!.isNotEmpty) {
        tokenBody['client_secret'] = _clientSecret!;
      }
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: tokenBody,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] as int? ?? 3599));
        
        // Re-authenticate the internal client
        if (_accessToken != null) {
          final credentials = auth.AccessCredentials(
            auth.AccessToken('Bearer', _accessToken!, _tokenExpiry!),
            _refreshToken,
            _scopes,
          );
          _authClient = auth.authenticatedClient(http.Client(), credentials);
          _currentUser = await _tryGetCurrentGoogleUser();
        }
        return true;
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] Error refreshing token: $e');
    }
    return false;
  }

  // Restore the AuthClient using passed tokens (used by Provider at startup)
  Future<void> restoreAuthClient() async {
    if (_accessToken == null) return;
    try {
      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', _accessToken!,
            _tokenExpiry ?? DateTime.now().add(const Duration(hours: 1))),
        _refreshToken,
        _scopes,
      );
      _authClient = auth.authenticatedClient(http.Client(), credentials);
      _currentUser = await _tryGetCurrentGoogleUser();
    } catch (e) {
      debugPrint('[GooglePhotosService] Error restoring AuthClient: $e');
    }
  }

  // -- PKCE helpers ------------------------------------------------------------

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  // -- Android-only PKCE via Chrome Custom Tabs ----------------------------

  Future<bool> _signInWithPKCE() async {
    if (_clientId == null) {
      debugPrint(
        '[GooglePhotosService] Android PKCE requires clientId (Desktop app client ID from GCP).',
      );
      return false;
    }

    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final redirectUri = '$_redirectScheme:/';
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId!,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      });

      debugPrint('[GooglePhotosService] OAuth Redirect URI used: $redirectUri');
      debugPrint('[GooglePhotosService] Opening OAuth URL via Custom Tabs...');

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _redirectScheme!,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null || code.isEmpty) {
        debugPrint(
            '[GooglePhotosService] PKCE: No authorization code received');
        return false;
      }

      debugPrint(
          '[GooglePhotosService] PKCE: authorization code received, exchanging...');

      // Exchange authorization code for access token
      final tokenBody = {
        'client_id': _clientId!,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
      };

      // Include client_secret only if provided (for Desktop app type)
      if (_clientSecret != null && _clientSecret!.isNotEmpty) {
        tokenBody['client_secret'] = _clientSecret!;
      }

      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: tokenBody,
      );

      if (tokenResponse.statusCode == 200) {
        final data = json.decode(tokenResponse.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        _refreshToken = data['refresh_token'] as String?;
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] as int? ?? 3599));

        if (_accessToken != null) {
          final returnedScopes = data['scope'] as String?;
          debugPrint('[GooglePhotosService] PKCE: Token exchange successful!');
          debugPrint(
              '[GooglePhotosService] PKCE: Scopes granted: $returnedScopes');

          // Create an AuthClient from the PKCE token
          final credentials = auth.AccessCredentials(
            auth.AccessToken('Bearer', _accessToken!,
                DateTime.now().add(const Duration(hours: 1)).toUtc()),
            null,
            _scopes,
          );
          _authClient = auth.authenticatedClient(http.Client(), credentials);

          if (returnedScopes != null &&
              !returnedScopes.contains('photoslibrary.readonly') &&
              !returnedScopes.contains('photoslibrary')) {
            debugPrint(
              '   ATTENTION: Le scope Google Photos n\'a PAS  t  accord  par l\'utilisateur sur l\' cran de consentement !',
            );
          }
          // Create a fake user stub so isAuthenticated returns true
          _currentUser = await _tryGetCurrentGoogleUser();
          return true;
        }
      } else {
        debugPrint(
          '[GooglePhotosService] PKCE: Token exchange failed: ${tokenResponse.statusCode} ${tokenResponse.body}',
        );
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] PKCE sign-in failed: $e');
    }
    return false;
  }

  Future<GoogleSignInAccount?> _tryGetCurrentGoogleUser() async {
    try {
      await _ensureInitialized();
      return await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------------------------

  Future<bool> trySilentSignIn() async {
    // On Android we don't support silent PKCE re-auth - token is in memory only
    if (!kIsWeb && Platform.isAndroid) return false;

    try {
      await _ensureInitialized();
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account != null) {
        _currentUser = account;
        final authData =
            await account.authorizationClient.authorizationForScopes(_scopes);
        if (authData != null) {
          _authClient = authData.authClient(scopes: _scopes);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] Silent sign-in failed: $e');
    }
    return false;
  }

  Future<bool> signIn() async {
    // Android: Use PKCE via Chrome Custom Tabs
    if (!kIsWeb && Platform.isAndroid) {
      return _signInWithPKCE();
    }

    // iOS / Web: Use google_sign_in
    try {
      await _ensureInitialized();
      final gSignIn = GoogleSignIn.instance;
      try {
        await gSignIn.disconnect();
      } catch (_) {}

      final account = await gSignIn.authenticate(scopeHint: _scopes);
      _currentUser = account;
      debugPrint('[GooglePhotosService] Authenticated as: ${account.email}');

      final authData =
          await account.authorizationClient.authorizeScopes(_scopes);
      _authClient = authData.authClient(scopes: _scopes);

      debugPrint('[GooglePhotosService] AuthClient obtained successfully');
      return true;
    } catch (e) {
      debugPrint('[GooglePhotosService] Sign-in failed: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _authClient?.close();
    _authClient = null;
    _currentUser = null;
    _rawHttpClient?.close();
    _rawHttpClient = null;

    if (!kIsWeb && Platform.isAndroid) return;

    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  // -- API calls ----------------------------------------------------------------

  Future<Map<String, String>?> createPickerSession() async {
    if (!isAuthenticated) return null;
    try {
      final url = Uri.parse(_pickerApiUrl);
      final body = json.encode({
        // The Picker API expects an empty payload or valid pickingMode.
        // `albumMode` is an invalid key and causes a 400 Bad Request error.
      });

      final response = await http.post(
        url,
        headers: {
          ..._authHeaders,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final id = data['id'] as String?;
        final pickerUri = data['pickerUri'] as String?;
        if (id != null && pickerUri != null) {
          return {'id': id, 'pickerUri': pickerUri};
        }
      } else {
        debugPrint(
            '[GooglePhotosService] Picker Session error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] createPickerSession error: $e');
    }
    return null;
  }

  Future<List<RemotePickerAsset>> fetchPickedPhotos(String sessionId) async {
    if (!isAuthenticated) return [];
    try {
      final url = Uri.parse('https://photospicker.googleapis.com/v1/mediaItems')
          .replace(queryParameters: {'sessionId': sessionId});

      debugPrint('[GooglePhotosService] fetchPickedPhotos URL: $url');
      final response = await http.get(url, headers: _authHeaders);
      debugPrint(
          '[GooglePhotosService] fetchPickedPhotos Status: ${response.statusCode}');
      debugPrint(
          '[GooglePhotosService] fetchPickedPhotos Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final items = body['mediaItems'] as List<dynamic>? ?? [];
        debugPrint(
            '[GooglePhotosService] Found ${items.length} media items in session');
        
        final List<RemotePickerAsset> newAssets = items
            .map((item) => _parseMediaItem(item as Map<String, dynamic>))
            .whereType<RemotePickerAsset>()
            .toList();

        return newAssets;
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] fetchPickedPhotos error: $e');
    }
    return [];
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // The legacy fetchPhotos (ListMediaItems) method was removed here
  // because it violates Google's March 2025 Privacy restrictions.
  // All fetching must now occur via `fetchPickedPhotos` utilizing the Picker API.

  PickerAsset? _parseMediaItem(Map<String, dynamic> item) {
    try {
      final id = item['id'] as String?;
      final mediaFile = item['mediaFile'] as Map<String, dynamic>? ?? {};

      // In the Picker API, the media details are nested inside 'mediaFile'.
      final remoteUrl =
          (mediaFile['baseUrl'] ?? item['mediaFileUri']) as String?;
      final mimeType = mediaFile['mimeType'] as String?;
      final filename = mediaFile['filename'] as String?;

      if (id == null) {
        debugPrint('[GooglePhotosService] Item ID is null: $item');
        return null;
      }
      if (remoteUrl == null) {
        debugPrint(
            '[GooglePhotosService] Item remoteUrl is null for ID: $id (Checked mediaFile.baseUrl and mediaFileUri)');
        return null;
      }

      final isVideo = mimeType?.startsWith('video/') ?? false;
      final metadata =
          mediaFile['mediaFileMetadata'] as Map<String, dynamic>? ?? {};
      final width = int.tryParse(metadata['width']?.toString() ?? '') ?? 0;
      final height = int.tryParse(metadata['height']?.toString() ?? '') ?? 0;
      final duration = isVideo
          ? _parseDuration(metadata['video'] as Map<String, dynamic>?)
          : null;

      return RemotePickerAsset(
        id: id,
        baseUrl: remoteUrl,
        type: isVideo ? AssetType.video : AssetType.image,
        width: width,
        height: height,
        duration: duration ?? Duration.zero,
        title: filename,
        headers: _accessToken != null
            ? {'Authorization': 'Bearer $_accessToken'}
            : null,
      );
    } catch (e) {
      debugPrint('[GooglePhotosService] Parsing error: $e');
      return null;
    }
  }

  Duration? _parseDuration(Map<String, dynamic>? videoMeta) {
    if (videoMeta == null) return null;
    final statusStr = videoMeta['status'] as String?;
    if (statusStr != 'READY') return null;
    return null;
  }
}
