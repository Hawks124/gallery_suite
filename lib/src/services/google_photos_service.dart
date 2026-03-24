import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import '../models/picker_asset.dart';

/// A service that handles Google Sign-In authentication and fetching media
/// items from the Google Photos Library API.
///
/// This is a singleton — access it via [GooglePhotosService.instance].
class GooglePhotosService {
  GooglePhotosService._();
  static final GooglePhotosService instance = GooglePhotosService._();

  static const String _baseApiUrl =
      'https://photoslibrary.googleapis.com/v1/mediaItems';

  /// The scopes we request from the user.
  /// `photoslibrary.readonly` gives read-only access to the user's library.
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ];

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  Map<String, String>? _authHeaders;

  String? _clientId;
  String? _serverClientId;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Initializes the service with optional explicit OAuth Client IDs.
  /// Used for environments not heavily integrated with Firebase `google-services.json`.
  void init({String? clientId, String? serverClientId}) {
    _clientId = clientId;
    _serverClientId = serverClientId;
  }

  /// Whether the user is currently authenticated with Google.
  bool get isAuthenticated => _currentUser != null && _authHeaders != null;

  /// The display name of the signed-in user (if available).
  String? get displayName => _currentUser?.displayName;

  /// The email of the signed-in user (if available).
  String? get email => _currentUser?.email;

  /// The profile photo URL of the signed-in user (if available).
  String? get photoUrl => _currentUser?.photoUrl;

  /// Attempts to silently restore a previous Google session.
  ///
  /// Returns `true` if a session was found and the auth headers are ready.
  Future<bool> trySilentSignIn() async {
    try {
      _googleSignIn ??= GoogleSignIn(
        scopes: _scopes,
        clientId: _clientId,
        serverClientId: _serverClientId,
      );
      final account = await _googleSignIn!.signInSilently();
      if (account != null) {
        _currentUser = account;
        _authHeaders = await account.authHeaders;
        return true;
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] Silent sign-in failed: $e');
    }
    return false;
  }

  /// Launches the interactive Google Sign-In flow.
  ///
  /// Returns `true` if the user successfully signed in, `false` otherwise.
  Future<bool> signIn() async {
    try {
      _googleSignIn ??= GoogleSignIn(
        scopes: _scopes,
        clientId: _clientId,
        serverClientId: _serverClientId,
      );
      final account = await _googleSignIn!.signIn();
      if (account != null) {
        _currentUser = account;
        _authHeaders = await account.authHeaders;
        return true;
      }
    } catch (e) {
      debugPrint('[GooglePhotosService] Sign-in failed: $e');
    }
    return false;
  }

  /// Signs the user out and clears cached auth data.
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    _currentUser = null;
    _authHeaders = null;
  }

  /// Fetches a page of media items from the user's Google Photos library.
  ///
  /// Returns a tuple-like record containing:
  /// - A list of [RemotePickerAsset] items for the current page.
  /// - The `nextPageToken` string (or `null` if there are no more pages).
  ///
  /// Throws if the user is not authenticated.
  Future<({List<RemotePickerAsset> items, String? nextPageToken})> fetchPhotos({
    String? pageToken,
    int pageSize = 50,
  }) async {
    assert(isAuthenticated, 'User must be authenticated before fetching photos');

    // Refresh headers in case the token expired
    _authHeaders = await _currentUser!.authHeaders;

    final uri = Uri.parse(_baseApiUrl).replace(queryParameters: {
      'pageSize': '$pageSize',
      if (pageToken != null) 'pageToken': pageToken,
    });

    final response = await http.get(uri, headers: _authHeaders);

    if (response.statusCode != 200) {
      debugPrint(
          '[GooglePhotosService] API error ${response.statusCode}: ${response.body}');
      return (items: <RemotePickerAsset>[], nextPageToken: null);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final mediaItems = json['mediaItems'] as List<dynamic>? ?? [];
    final nextToken = json['nextPageToken'] as String?;

    final assets = mediaItems
        .map((item) => _parseMediaItem(item as Map<String, dynamic>))
        .whereType<RemotePickerAsset>()
        .toList();

    return (items: assets, nextPageToken: nextToken);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Parses a single Google Photos API `mediaItem` JSON object into a
  /// [RemotePickerAsset].
  RemotePickerAsset? _parseMediaItem(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String;
      final baseUrl = json['baseUrl'] as String;
      final filename = json['filename'] as String?;
      final mimeType = json['mimeType'] as String? ?? '';

      final metadata = json['mediaMetadata'] as Map<String, dynamic>? ?? {};
      final width = int.tryParse('${metadata['width']}') ?? 0;
      final height = int.tryParse('${metadata['height']}') ?? 0;

      // Determine asset type from MIME
      AssetType type;
      if (mimeType.startsWith('video/')) {
        type = AssetType.video;
      } else {
        type = AssetType.image;
      }

      // Parse video duration if available
      Duration duration = Duration.zero;
      if (type == AssetType.video && metadata.containsKey('video')) {
        final videoMeta = metadata['video'] as Map<String, dynamic>? ?? {};
        final fps = double.tryParse('${videoMeta['fps']}') ?? 0;
        // Google sometimes returns processingStatus instead of duration
        // We'll rely on fps or default to zero
        if (fps > 0) {
          // Duration will be populated when we actually play the video
          duration = Duration.zero;
        }
      }

      return RemotePickerAsset(
        id: id,
        baseUrl: baseUrl,
        title: filename,
        type: type,
        width: width,
        height: height,
        duration: duration,
        headers: _authHeaders,
      );
    } catch (e) {
      debugPrint('[GooglePhotosService] Failed to parse media item: $e');
      return null;
    }
  }
}
