import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/picker_asset.dart';
import '../services/google_photos_service.dart';

/// Manages the state and persistence of Google Photos authentication and imported assets.
///
/// This provider uses [ValueNotifier] to expose reactive state to the UI without requiring
/// heavy external state management packages. It uses `path_provider` and `dart:io` to
/// persist data as lightweight JSON files.
class GooglePhotosProvider {
  GooglePhotosProvider._();
  static final GooglePhotosProvider instance = GooglePhotosProvider._();

  /// Reactive list of assets imported from Google Photos.
  final ValueNotifier<List<RemotePickerAsset>> importedAssets =
      ValueNotifier([]);

  /// Indicating whether the authentication state is currently being loaded from disk.
  final ValueNotifier<bool> isAuthStateLoading = ValueNotifier(false);

  // Persistence File Paths
  Future<File> get _authFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/gallery_suite_google_auth.json');
  }

  Future<File> get _assetsFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/gallery_suite_google_assets.json');
  }

  /// Restores the authentication state and imported assets from disk.
  /// Should be called early when the picker is initialized.
  Future<void> restoreState() async {
    isAuthStateLoading.value = true;
    try {
      final service = GooglePhotosService.instance;

      // 1. Restore Auth
      final authFile = await _authFile;
      if (authFile.existsSync()) {
        final content = await authFile.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        final access = data['access_token'] as String?;
        final refresh = data['refresh_token'] as String?;
        final expiryStr = data['expiry'] as String?;

        DateTime? expiry;
        if (expiryStr != null) {
          expiry = DateTime.tryParse(expiryStr);
        }

        service.setTokens(access, refresh, expiry);

        // Check token expiry
        if (access != null &&
            expiry != null &&
            DateTime.now().isAfter(expiry)) {
          debugPrint(
              '[GooglePhotosProvider] Access token expired. Attempting refresh.');
          if (refresh != null) {
            final refreshed = await service.refreshAccessToken();
            if (refreshed) {
              await saveState(); // Save the newly minted tokens
            } else {
              service.setTokens(null, null, null);
            }
          } else {
            service.setTokens(null, null, null);
          }
        }

        if (service.accessToken != null) {
          await service.restoreAuthClient();
        }
      }

      // 2. Restore Imported Assets
      final assetsFile = await _assetsFile;
      if (assetsFile.existsSync()) {
        final content = await assetsFile.readAsString();
        final List<dynamic> decoded = json.decode(content);

        // If authenticated, inject the authorization headers so images can actually load
        final headers = service.accessToken != null
            ? {'Authorization': 'Bearer ${service.accessToken}'}
            : null;

        final loadedAssets = decoded
            .map((e) => RemotePickerAsset.fromJson(e as Map<String, dynamic>,
                injectedHeaders: headers?.cast<String, String>()))
            .toList();

        importedAssets.value = loadedAssets;
        debugPrint(
            '[GooglePhotosProvider] Restored ${loadedAssets.length} assets');
      }
    } catch (e) {
      debugPrint('[GooglePhotosProvider] Error restoring state: $e');
    } finally {
      isAuthStateLoading.value = false;
    }
  }

  /// Persists the current authentication state and imported assets to disk.
  Future<void> saveState() async {
    try {
      final service = GooglePhotosService.instance;

      // Save Auth State
      final authFile = await _authFile;
      if (service.accessToken != null || service.refreshToken != null) {
        await authFile.writeAsString(json.encode({
          'access_token': service.accessToken,
          'refresh_token': service.refreshToken,
          'expiry': service.tokenExpiry?.toIso8601String(),
        }));
      } else {
        if (authFile.existsSync()) authFile.deleteSync();
      }

      // Save Imported Assets
      final assetsFile = await _assetsFile;
      final assetsJson = importedAssets.value.map((e) => e.toJson()).toList();
      await assetsFile.writeAsString(json.encode(assetsJson));
    } catch (e) {
      debugPrint('[GooglePhotosProvider] Error saving state: $e');
    }
  }

  /// Appends new photos to the import list, preventing duplicates.
  Future<void> importPhotos(List<RemotePickerAsset> newPhotos) async {
    if (newPhotos.isEmpty) return;

    final current = List<RemotePickerAsset>.from(importedAssets.value);
    final existingIds = current.map((e) => e.id).toSet();

    for (final asset in newPhotos) {
      if (!existingIds.contains(asset.id)) {
        current.add(asset);
      }
    }

    importedAssets.value = current;
    await saveState();
  }

  /// Removes an asset from the imported list.
  Future<void> removePhoto(String id) async {
    final current = List<RemotePickerAsset>.from(importedAssets.value);
    current.removeWhere((a) => a.id == id);
    importedAssets.value = current;
    await saveState();
  }

  /// Signs out and completely clears all persisted Google Photos data.
  Future<void> clearAll() async {
    importedAssets.value = [];
    final service = GooglePhotosService.instance;
    await service.signOut(); // Disconnects Google SignIn & clears memory tokens

    try {
      final authFile = await _authFile;
      if (authFile.existsSync()) authFile.deleteSync();
      final assetsFile = await _assetsFile;
      if (assetsFile.existsSync()) assetsFile.deleteSync();
    } catch (_) {}
  }
}
