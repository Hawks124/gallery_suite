/// Internal implementation of the main picker UI.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:file_selector/file_selector.dart';

import '../gallery_suite.dart';
import 'utils/heic_converter.dart';

/// The main entry point for the custom media picker.
///
/// Call [CustomMediaPicker.show] to open an in-app, full-screen media picker
/// that slides up from the bottom. The returned [AssetEntity] list contains
/// every selected asset, or `null` if the user dismissed without selecting.
///
/// The picker automatically routes to the correct UI based on
/// [PickerConfig.requestType]:
/// - [RequestType.image]   3-column masonry grid with multi-select.
/// - [RequestType.video]   3-column masonry grid; tap   inline preview sheet.
/// - [RequestType.audio]   scrollable list with inline `just_audio` playback.
///
/// ### Example
/// ```dart
/// import 'package:custom_media_picker/custom_media_picker.dart';
/// import 'package:photo_manager/photo_manager.dart';
///
/// final assets = await CustomMediaPicker.show(
///   context: context,
///   config: PickerConfig(
///     requestType: RequestType.image,
///     maxSelection: 5,
///     primaryColor: Colors.indigo,
///     brightness: Theme.of(context).brightness,
///   ),
/// );
///
/// if (assets != null) {
///   for (final asset in assets) {
///     final file = await asset.file;
///     // upload or preview `file`
///   }
/// }
/// ```
class CustomMediaPicker {
  /// Opens the media picker as a full-screen route that slides up from the
  /// bottom.
  ///
  /// - [context] - the [BuildContext] used to push the route.
  /// - [config] - optional [PickerConfig]; defaults to an image picker with
  ///   up to 10 items selectable.
  ///
  /// Returns `null` if the user cancels, or a non-empty [List<MediaItem>]
  /// with the selected assets.
  static Future<List<MediaItem>?> show({
    required BuildContext context,
    PickerConfig config = const PickerConfig(),
  }) async {
    final isAudio = config.requestType == RequestType.audio;

    return await Navigator.of(context).push<List<MediaItem>?>(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        // Cross-platform picker routing.
        // Audio uses the specialized list-based AudioPickerPage (now cross-platform).
        // Photo/Video use the grid-based _MediaPickerPage.
        pageBuilder: (ctx, animation, _) => isAudio
            ? AudioPickerPage(config: config)
            : _MediaPickerPage(config: config),
        transitionsBuilder: (ctx, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image + Video picker page
// ---------------------------------------------------------------------------
class _MediaPickerPage extends StatefulWidget {
  final PickerConfig config;

  const _MediaPickerPage({required this.config});

  @override
  State<_MediaPickerPage> createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<_MediaPickerPage>
    with SingleTickerProviderStateMixin {
  final MediaSource _source = MediaSourceFactory.activeSource;
  final ScrollController _scrollController = ScrollController();

  List<AlbumDescriptor> _albums = [];
  AlbumDescriptor? _currentAlbum;
  List<PickerAsset> _assets = [];
  final List<PickerAsset> _selected = [];

  // BYOE Edited Files State
  final Map<String, File> _editedFiles = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _permissionDenied = false;
  int _page = 0;

  // Search State
  bool _isSearching = false;
  String _searchQuery = '';
  List<PickerAsset> _searchResults = [];
  bool _isSearchLoading = false;
  Timer? _searchDebounce;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // -- Google Photos Cloud State ----------------------------------------------
  final GooglePhotosService _googleService = GooglePhotosService.instance;
  final GooglePhotosProvider _googleProvider = GooglePhotosProvider.instance;
  bool _isCloudMode = false;
  bool _isCloudLoading = false;
  bool _isSignOutLoading = false;
  StreamSubscription<bool>? _authSubscription;

  // -- Smart Clipboard State --------------------------------------------------
  bool _isClipboardMode = false;
  bool _isClipboardLoading = false;
  List<PickerAsset> _clipboardAssets = [];

  // -- Conversion State -------------------------------------------------------
  bool _isConverting = false;

  /// Initial page loads 80 items; subsequent pages fetch 120 for fewer
  /// round-trips on large libraries.
  int get _pageSize => _page == 0 ? 80 : 120;

  late AnimationController _chevronCtrl;

  late PickerTheme _theme;

  bool get _isVideoMode => widget.config.requestType == RequestType.video;

  @override
  void initState() {
    super.initState();

    // Map any passed initial selection into the internal state.
    if (widget.config.initialSelection != null) {
      for (final item in widget.config.initialSelection!) {
        if (item.asset != null) {
          _selected.add(LocalPickerAsset(item.asset!));
        } else if (item.remoteAsset != null) {
          _selected.add(item.remoteAsset!);
        } else if (item.fileAsset != null) {
          _selected.add(item.fileAsset!);
        }

        if (item.editedFile != null) {
          _editedFiles[item.asset?.id ??
              item.remoteAsset?.id ??
              item.fileAsset?.id ??
              ''] = item.editedFile!;
        }
      }
    }

    // Apply performance config to the shared native decode queue (if applicable).
    // The FileSelectorMediaSource handles its own loading.
    // photo_manager is unavailable on Web/Desktop — skip native decode queue.
    final isDesktopOrWeb =
        kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux));
    if (!isDesktopOrWeb) {
      MediaService.instance.decodeQueue = ThumbnailDecodeQueue(
        maxConcurrent: widget.config.maxConcurrentDecodes,
        maxCacheEntries: widget.config.thumbnailCacheSize,
      );
    }

    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scrollController.addListener(_onScroll);

    // Restore preserved cloud assets from disk asynchronously
    _googleProvider.restoreState();

    // Listen for auth changes (crucial for Web's async GIS flow)
    _authSubscription =
        _googleService.onAuthStateChanged.listen((isAuthenticated) {
      if (mounted) {
        setState(() {}); // Re-build to hide placeholder/show albums
      }
    });

    // Trigger silent sign-in to pre-initialize Google SignIn scripts for Web
    // and attempt auto-login for all platforms.
    _googleService.trySilentSignIn();

    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = widget.config.brightness == Brightness.dark ||
        (widget.config.brightness == null &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    _theme = PickerTheme(isDark, widget.config.themeData);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _chevronCtrl.dispose();
    _authSubscription?.cancel();
    // Reclaim temporary disk space when picker is closed
    if (widget.config.enableSmartClipboard) {
      ClipboardService.instance.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _isSearchLoading = false;
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _searchQuery = trimmed;
        _isSearchLoading = true;
        _isSearching = true;
      });

      try {
        if (_currentAlbum != null) {
          final results = await _source.searchAssets(_currentAlbum!, trimmed);
          if (mounted && _searchQuery == trimmed) {
            setState(() {
              _searchResults = results;
              _isSearchLoading = false;
            });
            if (results.isNotEmpty && widget.config.prefetchEnabled) {
              _source.prefetchThumbnails(results.take(30).toList());
            }
          }
        }
      } catch (e) {
        debugPrint('Search error: $e');
        if (mounted) setState(() => _isSearchLoading = false);
      }
    });
  }

  Future<void> _initialize() async {
    final granted = await _source.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
      }
      return;
    }
    await _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await _source.getAlbums(widget.config.requestType);
    if (!mounted) return;
    if (albums.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _albums = albums;
      _currentAlbum = albums.first;
    });
    await _loadAssets(reset: true);
  }

  Future<void> _loadAssets({bool reset = false}) async {
    if (_currentAlbum == null) return;
    if (reset) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => reset ? _isLoading = true : _isLoadingMore = true);

    final assets = (await _source.getAssets(
      album: _currentAlbum!,
      page: _page,
      pageSize: _pageSize,
    ))
        .where((a) => a.type != AssetType.audio)
        .toList();

    if (!mounted) return;
    setState(() {
      if (reset) {
        _assets = assets;
        _isLoading = false;
      } else {
        _assets.addAll(assets);
        _isLoadingMore = false;
      }
      _hasMore = assets.length >= _pageSize;
      _page++;
    });
  }

  void _onScroll() {
    // -- Pagination trigger (1500px = ~2 screens ahead) --------------------
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 1500) {
      if (!_isLoadingMore && _hasMore && !_isLoading) _loadAssets();
    }

    // -- Prefetch thumbnails for items about to come on screen ------------
    if (widget.config.prefetchEnabled && _assets.isNotEmpty) {
      _prefetchVisibleRange();
    }
  }

  /// Pre-loads thumbnails for the next ~30 items beyond the current viewport.
  void _prefetchVisibleRange() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final viewportHeight = position.viewportDimension;
    final scrollPixels = position.pixels;

    // Estimate which asset index we're at (~110px per row, 3 columns).
    final estimatedRowHeight = 110.0;
    final currentRow = (scrollPixels / estimatedRowHeight).floor();
    final visibleRows = (viewportHeight / estimatedRowHeight).ceil();
    final startIdx = (currentRow + visibleRows) * 3; // just past viewport
    final endIdx = math.min(startIdx + 30, _assets.length);

    if (startIdx >= _assets.length) return;
    _source.prefetchThumbnails(_assets.sublist(startIdx, endIdx));
  }

  Future<void> _switchAlbum(AlbumDescriptor album) async {
    if (album.id == _currentAlbum?.id) return;
    setState(() {
      _currentAlbum = album;
      _selected.clear();
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
    await _loadAssets(reset: true);
  }

  void _toggleSelection(PickerAsset asset) {
    if (_isVideoMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _selectionIndex(asset.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        if (_selected.length < widget.config.maxSelection) {
          _selected.add(asset);
        } else {
          HapticFeedback.heavyImpact();
        }
      }
    });
  }

  Future<void> _onCameraCaptured(File file) async {
    // On Web/Desktop, PhotoManager.editor is unavailable — return file as FilePickerAsset
    final isDesktopOrWeb =
        kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux));
    if (isDesktopOrWeb) {
      final bytes = await file.readAsBytes();
      final title = 'Captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      int width = 0;
      int height = 0;
      try {
        final image = await decodeImageFromList(bytes);
        width = image.width;
        height = image.height;
        image.dispose();
      } catch (_) {}
      final asset = FilePickerAsset(
        filePath: file.path,
        title: title,
        bytes: bytes,
        width: width,
        height: height,
      );
      if (mounted) {
        Navigator.of(context).pop([MediaItem.file(fileAsset: asset)]);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final savedAsset = await (_isVideoMode
          ? PhotoManager.editor.saveVideo(
              file,
              title: 'Captured_${DateTime.now().millisecondsSinceEpoch}.mp4',
            )
          : PhotoManager.editor.saveImageWithPath(
              file.path,
              title: 'Captured_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));

      if (savedAsset == null) return; // ignore: unnecessary_null_comparison

      if (_isVideoMode || widget.config.maxSelection == 1) {
        // Single select: return immediately
        if (mounted) Navigator.of(context).pop([LocalPickerAsset(savedAsset)]);
      } else {
        // Multi select: add to selection and reload grid
        setState(() {
          if (_selected.length < widget.config.maxSelection) {
            _selected.add(LocalPickerAsset(savedAsset));
          }
        });
        // Reload the current album to show the new picture at the top
        await _loadAssets(reset: true);
      }
    } catch (e) {
      debugPrint('Error saving captured media: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    if (_source is FileSelectorMediaSource) {
      final newAssets = await (_source as FileSelectorMediaSource).pickFiles(
        requestType: widget.config.requestType,
      );
      if (newAssets.isNotEmpty) {
        setState(() {
          // Add newly picked files to the top of the grid
          _assets.insertAll(0, newAssets);
        });
      }
    }
  }

  Future<void> _onVideoTap(PickerAsset asset) async {
    final confirmed = await VideoPreviewSheet.show(
      context,
      asset,
      _theme,
      widget.config.primaryColor,
      widget.config.textDelegate,
      _googleService,
      isMultiSelect: widget.config.maxSelection > 1,
    );
    if (confirmed && mounted) {
      if (widget.config.maxSelection > 1) {
        if (!_selected.any((e) => e.id == asset.id)) {
          _toggleSelection(asset);
        }
      } else {
        if (asset is LocalPickerAsset) {
          Navigator.of(context).pop([MediaItem(asset: asset.entity)]);
        } else if (asset is RemotePickerAsset) {
          Navigator.of(context).pop([MediaItem.remote(remoteAsset: asset)]);
        } else if (asset is FilePickerAsset) {
          Navigator.of(context).pop([MediaItem.file(fileAsset: asset)]);
        }
      }
    }
  }

  int _selectionIndex(String id) => _selected.indexWhere((e) => e.id == id);

  Future<void> _handleExit() async {
    final hasChanges = _selected.isNotEmpty || _editedFiles.isNotEmpty;
    if (!hasChanges || widget.config.exitConfirmation == null) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
      return;
    }

    final shouldExit = await widget.config.exitConfirmation!.show(
      context,
      widget.config.primaryColor,
    );

    if (!mounted) return;
    if (shouldExit) {
      Navigator.of(context).pop(null);
    }
  }

  Future<void> _onConfirm() async {
    if (_selected.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isConverting = true;
    });

    final items = <MediaItem>[];
    for (final asset in _selected) {
      if (asset is LocalPickerAsset) {
        File? processedFile;
        final originalFile = widget.config.useOriginalFile
            ? await asset.originFile
            : await asset.file;

        if (originalFile != null) {
          // Native defense: always rescue HEIC to JPG to avoid downstream crashes
          File safeFile =
              await NativeMediaCompressor.convertHeicIfNeeded(originalFile);
          bool wasHeicConverted = safeFile.path != originalFile.path;

          // Compression Pipeline priority 1: BYOC Hook
          if (widget.config.onCompressMedia != null) {
            if (!mounted) return;
            processedFile = await widget.config.onCompressMedia!(
                context, asset.entity, safeFile);
          }
          // Compression Pipeline priority 2: Native Built-in
          else if (widget.config.autoCompressImages &&
              asset.entity.type == AssetType.image) {
            processedFile = await NativeMediaCompressor.compressImage(
                safeFile, widget.config.imageCompressionQuality);
          }

          // If no compression was applied but HEIC was rescued, use rescued file
          if (processedFile == null && wasHeicConverted) {
            processedFile = safeFile;
          }
        }

        items.add(MediaItem(
          asset: asset.entity,
          useOriginalFile: widget.config.useOriginalFile,
          editedFile: _editedFiles[asset.id],
          processedFile: processedFile,
        ));
      } else if (asset is RemotePickerAsset) {
        items.add(MediaItem.remote(
          remoteAsset: asset,
          editedFile: _editedFiles[asset.id],
        ));
      } else if (asset is FilePickerAsset) {
        items.add(MediaItem.file(
          fileAsset: asset,
          editedFile: _editedFiles[asset.id],
        ));
      }
    }

    if (mounted) {
      setState(() {
        _isConverting = false;
      });
      Navigator.of(context).pop(items);
    }
  }

  // -- Google Photos Cloud Methods --------------------------------------------

  void _enterCloudMode() {
    setState(() {
      _isCloudMode = true;
    });
  }

  void _exitCloudMode() {
    setState(() {
      _isCloudMode = false;
    });
  }

  Future<void> _connectGoogle() async {
    setState(() => _isCloudLoading = true);

    await _googleService.signIn();

    if (mounted) {
      setState(() => _isCloudLoading = false);
    }
  }

  Future<void> _pickFromGooglePhotos() async {
    setState(() => _isCloudLoading = true);
    try {
      final sessionData = await _googleService.createPickerSession();
      if (sessionData == null) return;

      final pickedUrl = sessionData['pickerUri'];
      final sessionId = sessionData['id'];

      if (pickedUrl != null && sessionId != null) {
        // Launch Google Photos Picker UI
        try {
          await FlutterWebAuth2.authenticate(
            url: pickedUrl,
            callbackUrlScheme: _googleService.redirectScheme,
          ).timeout(const Duration(seconds: 60));
        } catch (e) {
          debugPrint('WebAuth2 flow ended or timed out: $e');
        }

        // Fetch what the user actually picked in the session
        final newPhotos = await _googleService.fetchPickedPhotos(sessionId);
        await _googleProvider.importPhotos(newPhotos);
      }
    } finally {
      if (mounted) setState(() => _isCloudLoading = false);
    }
  }

  Future<void> _handleGooglePhotosSignOut() async {
    // Show confirmation dialog
    final confirmation = StandardExitConfirmation(
      title: widget.config.textDelegate.googlePhotosDisconnectConfirmationTitle,
      content:
          widget.config.textDelegate.googlePhotosDisconnectConfirmationSubtitle,
      confirmText: widget.config.textDelegate.googlePhotosDisconnect,
      cancelText: widget.config.textDelegate.cancel,
    );

    final shouldSignOut = await confirmation.show(
      context,
      widget.config.primaryColor,
    );

    if (!shouldSignOut || !mounted) return;

    setState(() => _isSignOutLoading = true);

    try {
      await _googleProvider.clearAll();
      if (_isCloudMode) _exitCloudMode();
    } finally {
      if (mounted) {
        setState(() => _isSignOutLoading = false);
      }
    }
  }

  // -- Smart Clipboard Methods ------------------------------------------------

  void _enterClipboardMode() {
    setState(() {
      _isClipboardMode = true;
      _isCloudMode = false;
      _isClipboardLoading = true;
      _clipboardAssets.clear(); // Clear previous fetch if any
    });

    _fetchClipboard();
  }

  void _exitClipboardMode() {
    setState(() {
      _isClipboardMode = false;
      _isClipboardLoading = false;
    });
  }

  Future<void> _fetchClipboard() async {
    try {
      debugPrint(
          '📋 [PickerPage] _fetchClipboard -> calling ClipboardService.instance.fetchAssets()...');
      final assets = await ClipboardService.instance.fetchAssets();
      debugPrint(
          '📋 [PickerPage] _fetchClipboard -> got ${assets.length} assets');
      if (!mounted) return;

      setState(() {
        _clipboardAssets = assets;
      });

      // Visible feedback for debugging
      if (mounted && assets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📋 Clipboard: No media detected. Copy an image or media URL first.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('📋 [PickerPage] _fetchClipboard -> ERROR: $e');
    } finally {
      if (mounted) {
        setState(() => _isClipboardLoading = false);
      }
    }
  }

  // Legacy _loadCloudPhotos has been permanently removed
  // to comply with Google's March 2025 Privacy Rules.

  void _showAlbumSheet() {
    final bool canShowGoogle = widget.config.googlePhotosConfig.enabled;
    final bool canShowClipboard = widget.config.enableSmartClipboard;
    if (_albums.length <= 1 && !canShowGoogle && !canShowClipboard) return;
    HapticFeedback.lightImpact();
    _chevronCtrl.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.48,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: true,
        snap: true,
        snapSizes: const [0.48, 0.88],
        builder: (_, scrollController) => AlbumSelectorSheet(
          albums: _albums,
          currentAlbum:
              (_isCloudMode || _isClipboardMode) ? null : _currentAlbum,
          primaryColor: widget.config.primaryColor,
          theme: _theme,
          textDelegate: widget.config.textDelegate,
          scrollController: scrollController,
          source: _source,
          onSelect: (album) {
            Navigator.pop(context);
            if (_isCloudMode) _exitCloudMode();
            if (_isClipboardMode) _exitClipboardMode();
            _switchAlbum(album);
          },
          onGooglePhotosTap: (widget.config.googlePhotosConfig.enabled)
              ? () {
                  Navigator.pop(context);
                  _enterCloudMode();
                }
              : null,
          isGooglePhotosConnected: _googleService.isAuthenticated,
          onGooglePhotosSignOut: () {
            Navigator.pop(context);
            _handleGooglePhotosSignOut();
          },
          enableSmartClipboard: widget.config.enableSmartClipboard,
          onClipboardTap: widget.config.enableSmartClipboard
              ? () {
                  Navigator.pop(context);
                  _enterClipboardMode();
                }
              : null,
        ),
      ),
    ).whenComplete(() {
      if (mounted) _chevronCtrl.reverse();
    });
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty || !_source.supportsFileAddition || _isCloudMode) return;

    final newAssets = <FilePickerAsset>[];
    for (final file in files) {
      // Prevent duplicates
      if (_assets.any((a) => a is FilePickerAsset && a.filePath == file.path)) {
        continue;
      }

      Uint8List? bytes;
      int width = 0;
      int height = 0;

      try {
        final ext = file.name.split('.').last.toLowerCase();
        final isVideoOrAudio = {
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
          '3gp',
          'mp3',
          'wav',
          'aac',
          'flac',
          'ogg',
          'm4a'
        }.contains(ext);

        // On Web, do not read huge video/audio blobs eagerly to avoid RAM issues
        if (!isVideoOrAudio) {
          bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            final image = await decodeImageFromList(bytes);
            width = image.width;
            height = image.height;
            image.dispose();
          }
        }
      } catch (e) {
        debugPrint('Error decoding dropped file specs: $e');
      }

      newAssets.add(FilePickerAsset(
        filePath: file.path,
        title: file.name,
        bytes: bytes,
        width: width,
        height: height,
      ));
    }

    if (newAssets.isNotEmpty) {
      setState(() {
        _assets.insertAll(0, newAssets);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _selected.isNotEmpty || _editedFiles.isNotEmpty;
    final canPop = !hasChanges || widget.config.exitConfirmation == null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _handleSelectAll,
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            _handleSelectAll,
      },
      child: Focus(
        autofocus: true,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _theme.overlayStyle,
          child: PopScope(
            canPop: canPop,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final shouldExit = await widget.config.exitConfirmation!.show(
                context,
                widget.config.primaryColor,
              );

              if (!context.mounted) return;
              if (shouldExit) {
                Navigator.of(context).pop(null);
              }
            },
            child: Scaffold(
              backgroundColor: _theme.background,
              appBar: _buildAppBar(),
              body: DragAndDropOverlay(
                theme: _theme,
                primaryColor: widget.config.primaryColor,
                label: 'Drop files to add',
                onDropped: _handleDroppedFiles,
                child: Stack(
                  children: [
                    _buildBody(),
                    if (_isSignOutLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _theme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: CircularProgressIndicator(
                              color: widget.config.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelectAll() {
    if (widget.config.maxSelection <= 1) return;

    final targetList = _isCloudMode
        ? _googleProvider.importedAssets.value
        : (_isSearching && _searchQuery.isNotEmpty)
            ? _searchResults
            : _assets;

    if (targetList.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selected.clear();
      _selected.addAll(targetList.take(widget.config.maxSelection));
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: _theme.surface,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: TextButton(
                    onPressed: _handleExit,
                    style: TextButton.styleFrom(
                      foregroundColor: _theme.secondaryText,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      widget.config.textDelegate.cancel,
                      style: TextStyle(
                        color: _theme.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showAlbumSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 56, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _isVideoMode
                                ? widget.config.textDelegate.videosLabel
                                : _isCloudMode
                                    ? widget.config.textDelegate.googlePhotos
                                    : _isClipboardMode
                                        ? widget.config.textDelegate.clipboard
                                        : (_currentAlbum?.name ??
                                            widget.config.textDelegate
                                                .imagesLabel),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _theme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (_albums.length > 1 ||
                            widget.config.googlePhotosConfig.enabled) ...[
                          const SizedBox(width: 3),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5)
                                .animate(_chevronCtrl),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _theme.secondaryText,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_source.supportsFileAddition &&
                          !_isCloudMode &&
                          !_isClipboardMode)
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded,
                              color: widget.config.primaryColor),
                          onPressed: _pickFiles,
                          tooltip: 'Add Files',
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: CurvedAnimation(
                              parent: anim, curve: Curves.easeOutBack),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: (_selected.isNotEmpty)
                            ? SendButton(
                                key: const ValueKey('send'),
                                label: widget.config.textDelegate.confirm,
                                count: _selected.length,
                                color: widget.config.primaryColor,
                                onTap: _isConverting ? () {} : _onConfirm,
                                isLoading: _isConverting,
                              )
                            : SizedBox(
                                key: const ValueKey('empty'),
                                width: (_source.supportsFileAddition &&
                                        !_isCloudMode)
                                    ? 40
                                    : 80,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return PermissionDeniedWidget(
        theme: _theme,
        title: widget.config.textDelegate.permissionDeniedTitle,
        subtitle: widget.config.textDelegate.permissionDeniedSubtitle,
        buttonText: widget.config.textDelegate.permissionDeniedButton,
      );
    }

    return Column(
      children: [
        Container(height: 0.5, color: _theme.separator),
        if (!_isCloudMode && !_isClipboardMode)
          InlineSearchBar(
            theme: _theme,
            hintText: widget.config.textDelegate.searchPlaceholder,
            searchQuery: _searchQuery,
            searchCtrl: _searchCtrl,
            searchFocus: _searchFocus,
            onChanged: _onSearchChanged,
            onCancel: () {
              _searchCtrl.clear();
              _onSearchChanged('');
              _searchFocus.unfocus();
            },
          ),
        Expanded(
          child: _isCloudMode
              ? _buildCloudBody()
              : _isClipboardMode
                  ? _buildClipboardBody()
                  : _buildGrid(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: _selected.isNotEmpty
              ? _buildSelectedStrip()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCloudBody() {
    // Show the gorgeous connect placeholder when not authenticated
    if (!_googleService.isAuthenticated) {
      return GooglePhotosConnectPlaceholder(
        theme: _theme,
        primaryColor: widget.config.primaryColor,
        textDelegate: widget.config.textDelegate,
        onConnect: _connectGoogle,
      );
    }

    return ValueListenableBuilder<List<RemotePickerAsset>>(
        valueListenable: _googleProvider.importedAssets,
        builder: (context, cloudAssets, _) {
          // Show loading spinner on first fetch
          if (cloudAssets.isEmpty && _isCloudLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          // Show empty state with Import Button
          if (cloudAssets.isEmpty && !_isCloudLoading) {
            return Container(
              color: _theme.background,
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/sad-cloud.png',
                            width: 200,
                            height: 200,
                            package: 'gallery_suite',
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            widget.config.textDelegate
                                .googlePhotosEmptyStateTitle,
                            style: TextStyle(
                              color: _theme.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.config.textDelegate
                                .googlePhotosEmptyStateSubtitle,
                            style: TextStyle(
                              color: _theme.secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _pickFromGooglePhotos,
                            icon: const Icon(Icons.add_photo_alternate_outlined,
                                size: 20),
                            label: Text(widget
                                .config.textDelegate.googlePhotosImportButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.config.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (cloudAssets.isNotEmpty) _buildImportButton(),
                ],
              ),
            );
          }

          // Show cloud photos grid
          return Stack(
            children: [
              DraggableSelectionGrid(
                scrollController: _scrollController,
                enabled: (widget.config.maxSelection > 1) &&
                    widget.config.enableSwipeToSelect,
                onAssetHover: (asset) {
                  final idx = _selectionIndex(asset.id);
                  if (idx == -1 &&
                      _selected.length < widget.config.maxSelection) {
                    HapticFeedback.selectionClick();
                    setState(() => _selected.add(asset));
                  }
                },
                child: MasonryGridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  itemCount: cloudAssets.length + (_isCloudLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the bottom
                    if (index >= cloudAssets.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Center(child: CircularProgressIndicator.adaptive()),
                      );
                    }

                    final asset = cloudAssets[index];
                    final selIdx =
                        _selected.indexWhere((e) => e.id == asset.id);
                    final isSelected = selIdx >= 0;

                    // Calculate aspect ratio for masonry
                    final aspectRatio = (asset.width > 0 && asset.height > 0)
                        ? asset.width / asset.height
                        : 1.0;

                    return AspectRatio(
                      aspectRatio: aspectRatio.clamp(0.5, 2.0),
                      child: MetaData(
                        metaData: asset,
                        behavior: HitTestBehavior.translucent,
                        child: GestureDetector(
                          onTap: () {
                            if (_isVideoMode &&
                                widget.config.maxSelection <= 1) {
                              _onVideoTap(asset);
                            } else {
                              _toggleSelection(asset);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? AuthImage(
                                      imageUrl: asset.thumbUrl,
                                      googleService: _googleService,
                                      theme: _theme,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: asset.thumbUrl,
                                      httpHeaders: asset.headers,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: _theme.elevated,
                                      ),
                                      errorBuilder: (_, __, ___) => Container(
                                        color: _theme.elevated,
                                        child: Icon(Icons.broken_image_rounded,
                                            color: _theme.secondaryText,
                                            size: 28),
                                      ),
                                    ),
                              if (isSelected)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: widget.config.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${selIdx + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildDeleteButton(),
              _buildImportButton(),
            ],
          );
        });
  }

  Widget _buildClipboardBody() {
    if (_isClipboardLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(widget.config.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              widget.config.textDelegate.clipboardLoading,
              style: TextStyle(
                color: _theme.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_clipboardAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_paste_off_rounded,
                size: 64, color: _theme.elevated),
            const SizedBox(height: 16),
            Text(
              widget.config.textDelegate.clipboardEmpty,
              style: TextStyle(
                color: _theme.secondaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return DraggableSelectionGrid(
      scrollController: _scrollController,
      enabled:
          (widget.config.maxSelection > 1) && widget.config.enableSwipeToSelect,
      onAssetHover: (asset) {
        final idx = _selectionIndex(asset.id);
        if (idx == -1 && _selected.length < widget.config.maxSelection) {
          HapticFeedback.selectionClick();
          setState(() => _selected.add(asset));
        }
      },
      child: MasonryGridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        itemCount: _clipboardAssets.length,
        itemBuilder: (context, index) {
          final asset = _clipboardAssets[index];
          final selIdx = _selected.indexWhere((e) => e.id == asset.id);
          final isSelected = selIdx >= 0;

          // Compute aspect ratio from asset dimensions; default to 1:1 square
          // if dimensions are unknown (prevents infinite height crash).
          final double aspectRatio = (asset.width > 0 && asset.height > 0)
              ? asset.width / asset.height
              : 1.0;

          return AspectRatio(
            aspectRatio: aspectRatio,
            child: MediaThumbnailWidget(
              asset: asset,
              isSelected: isSelected,
              selectionNumber: selIdx >= 0 ? selIdx + 1 : null,
              primaryColor: widget.config.primaryColor,
              isDark: _theme.isDark,
              theme: _theme,
              onTap: () {
                if (_isVideoMode && widget.config.maxSelection <= 1) {
                  _onVideoTap(asset);
                } else {
                  _toggleSelection(asset);
                }
              },
              onLongPress: () {
                HapticFeedback.lightImpact();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildImportButton() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _pickFromGooglePhotos,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(
                  color: _theme.isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                widget.config.textDelegate.googlePhotosImportButton,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _theme.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Material(
              color: _theme.isDark ? Colors.white : const Color(0xFF1E1E1E),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _pickFromGooglePhotos,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: _theme.isDark ? Colors.black : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final count = _selected.whereType<RemotePickerAsset>().length;
    // Don't build at all if selected strip completely covers it, but with AnimatedScale
    // it smoothly disappears instead.
    if (!_isCloudMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 84, // Sit gracefully above the import button
      left: 24,
      right: 24,
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedScale(
          scale: count > 0 ? 1.0 : 0.0,
          curve: Curves.easeOutBack,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: count == 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final idsToDelete = _selected
                      .whereType<RemotePickerAsset>()
                      .map((e) => e.id)
                      .toList();

                  for (final id in idsToDelete) {
                    await _googleProvider.removePhoto(id);
                  }

                  if (mounted) {
                    setState(() {
                      _selected.removeWhere((e) =>
                          e is RemotePickerAsset && idsToDelete.contains(e.id));
                    });
                  }
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), // Dense semantic red
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.config.textDelegate.googlePhotosDeleteButton} ($count)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading || (_isSearching && _isSearchLoading)) {
      return PulsingSkeletonGrid(theme: _theme);
    }

    if (_isSearching && _searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: _theme.secondaryText),
            const SizedBox(height: 16),
            Text(
              '${widget.config.textDelegate.searchNoResults} "$_searchQuery"',
              style: TextStyle(
                color: _theme.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final List<PickerAsset> totalAssets = _isCloudMode
        ? _googleProvider.importedAssets.value
        : (_isSearching && _searchQuery.isNotEmpty)
            ? _searchResults
            : _assets;

    final displayAssets = totalAssets.where((a) {
      if (widget.config.requestType == RequestType.video) {
        return a.type == AssetType.video;
      }
      if (widget.config.requestType == RequestType.image) {
        return a.type == AssetType.image;
      }
      if (widget.config.requestType == RequestType.audio) {
        return a.type == AssetType.audio;
      }
      // For combined types (common, all), show both images and videos in the grid,
      // but exclude audio as it uses the specialized list-based picker.
      return a.type == AssetType.image || a.type == AssetType.video;
    }).toList();

    if (!_isSearching && _assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVideoMode
                  ? Icons.videocam_outlined
                  : (_isCloudMode
                      ? Icons.cloud_outlined
                      : Icons.photo_library_outlined),
              size: 56,
              color: _theme.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              _isCloudMode
                  ? widget.config.textDelegate.googlePhotosEmptyStateTitle
                  : widget.config.textDelegate.noMediaFound,
              style: TextStyle(
                color: _theme.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_source.supportsFileAddition && !_isCloudMode) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Select Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.config.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
            if (_isCloudMode) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFromGooglePhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label:
                    Text(widget.config.textDelegate.googlePhotosImportButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.config.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.config.textDelegate.googlePhotosEmptyStateSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _theme.secondaryText, fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Determine if the camera tile should be shown
    // Hide camera tile on Web/Desktop (WebRTC flash/torch causes crashes, no native integration)
    final isDesktopOrWeb =
        kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux));
    final showCamera =
        !isDesktopOrWeb && !_isSearching && widget.config.showCameraTile;
    final cameraOffset = showCamera ? 1 : 0;
    final enableSwipe =
        !isDesktopOrWeb && !_isVideoMode && widget.config.enableSwipeToSelect;

    // Pagination only when not searching
    final bool isLoadingMoreAssets = _isSearching ? false : _isLoadingMore;
    final int extraLoadingItems = isLoadingMoreAssets ? 3 : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop responsive grid: 3 columns minimum, add 1 for every 160px > 500px
        int crossAxisCount = 3;
        if (constraints.maxWidth > 500) {
          crossAxisCount = (constraints.maxWidth / 160).floor();
        }

        return DraggableSelectionGrid(
          scrollController: _scrollController,
          enabled: enableSwipe,
          onAssetHover: (asset) {
            // Toggle selection during swipe
            final idx = _selectionIndex(asset.id);
            if (idx == -1 && _selected.length < widget.config.maxSelection) {
              HapticFeedback.selectionClick();
              setState(() => _selected.add(asset));
            }
          },
          child: MasonryGridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(1.5),
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
            mainAxisSpacing: 1.5,
            crossAxisSpacing: 1.5,
            itemCount: displayAssets.length + cameraOffset + extraLoadingItems,
            itemBuilder: (ctx, i) {
              // Camera tile at position 0
              if (showCamera && i == 0) {
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: CameraTileWidget(
                    primaryColor: widget.config.primaryColor,
                    isDark: _theme.isDark,
                    captureMode: _isVideoMode
                        ? CameraCaptureMode.video
                        : CameraCaptureMode.photo,
                    onCaptured: _onCameraCaptured,
                  ),
                );
              }

              final assetIndex = i - cameraOffset;

              if (assetIndex >= displayAssets.length) {
                return AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(color: _theme.shimmerBase),
                );
              }
              final asset = displayAssets[assetIndex];
              final selIdx = _selectionIndex(asset.id);
              final isSelected = selIdx >= 0;

              final double ar = (asset.width > 0 && asset.height > 0)
                  ? asset.width / asset.height
                  : 1.0;

              return AspectRatio(
                aspectRatio: ar.clamp(0.35, 2.8),
                child: MetaData(
                  metaData: asset,
                  behavior: HitTestBehavior.translucent,
                  child: MediaThumbnailWidget(
                    key: ValueKey(asset.id),
                    asset: asset,
                    isSelected: isSelected,
                    selectionNumber: isSelected ? selIdx + 1 : null,
                    primaryColor: widget.config.primaryColor,
                    isDark: _theme.isDark,
                    theme: _theme,
                    googleService: _googleService,
                    showPlayOverlay:
                        _isVideoMode || asset.type == AssetType.video,
                    onTap: () {
                      if (_isVideoMode && widget.config.maxSelection <= 1) {
                        _onVideoTap(asset);
                      } else {
                        _toggleSelection(asset);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedStrip() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: _theme.surface.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(color: _theme.separator, width: 0.5),
            ),
          ),
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _selected.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final asset = _selected.removeAt(oldIndex);
                _selected.insert(newIndex, asset);
              });
              HapticFeedback.selectionClick();
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final animValue = Curves.easeInOut.transform(animation.value);
                  final scale =
                      Tween<double>(begin: 1.0, end: 1.05).transform(animValue);
                  final elevation =
                      Tween<double>(begin: 0.0, end: 8.0).transform(animValue);
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      color: Colors.transparent,
                      elevation: elevation,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            itemBuilder: (_, i) {
              final asset = _selected[i];
              return SelectedPreviewItem(
                key: ValueKey(asset.id),
                asset: asset,
                index: i + 1,
                primaryColor: widget.config.primaryColor,
                onRemove: () => _toggleSelection(asset),
                theme: _theme,
                googleService: _googleService,
                textDelegate: widget.config.textDelegate,
                editedFile: _editedFiles[asset.id],
                onEdit: (widget.config.onEditMedia != null &&
                        asset is LocalPickerAsset &&
                        asset.type == AssetType.image)
                    ? () async {
                        HapticFeedback.lightImpact();
                        try {
                          final originalFile = widget.config.useOriginalFile
                              ? await asset.originFile
                              : await asset.file;

                          if (originalFile == null || !mounted) return null;

                          final newFile = await widget.config.onEditMedia!(
                            context,
                            asset.entity,
                            originalFile,
                          );

                          if (newFile != null && mounted) {
                            setState(() {
                              _editedFiles[asset.id] = newFile;
                            });
                          }
                          return newFile;
                        } catch (e) {
                          debugPrint('Error invoking onEditMedia: $e');
                          return null;
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
