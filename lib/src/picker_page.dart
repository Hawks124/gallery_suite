import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../gallery_suite.dart';
import 'enum/enum.dart';
import 'pages/audio_picker_page.dart';
import 'services/thumbnail_decode_queue.dart';
import 'widgets/suite_widgets.dart';

/// The main entry point for the custom media picker.
///
/// Call [CustomMediaPicker.show] to open an in-app, full-screen media picker
/// that slides up from the bottom. The returned [AssetEntity] list contains
/// every selected asset, or `null` if the user dismissed without selecting.
///
/// The picker automatically routes to the correct UI based on
/// [PickerConfig.requestType]:
/// - [RequestType.image] → 3-column masonry grid with multi-select.
/// - [RequestType.video] → 3-column masonry grid; tap → inline preview sheet.
/// - [RequestType.audio] → scrollable list with inline `just_audio` playback.
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
  /// - [context] — the [BuildContext] used to push the route.
  /// - [config] — optional [PickerConfig]; defaults to an image picker with
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
  final MediaService _service = MediaService.instance;
  final ScrollController _scrollController = ScrollController();

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];

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
  List<AssetEntity> _searchResults = [];
  bool _isSearchLoading = false;
  Timer? _searchDebounce;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Initial page loads 80 items; subsequent pages fetch 120 for fewer
  /// round-trips on large libraries.
  int get _pageSize => _page == 0 ? 80 : 120;

  late AnimationController _chevronCtrl;

  late PickerTheme _theme;

  bool get _isVideoMode => widget.config.requestType == RequestType.video;

  @override
  void initState() {
    super.initState();

    // Apply performance config to the shared decode queue.
    _service.decodeQueue = ThumbnailDecodeQueue(
      maxConcurrent: widget.config.maxConcurrentDecodes,
      maxCacheEntries: widget.config.thumbnailCacheSize,
    );

    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness =
        widget.config.brightness ?? MediaQuery.of(context).platformBrightness;
    _theme = PickerTheme(brightness == Brightness.dark);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _chevronCtrl.dispose();
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
          final results = await _service.searchAssets(_currentAlbum!, trimmed);
          if (mounted && _searchQuery == trimmed) {
            setState(() {
              _searchResults = results;
              _isSearchLoading = false;
            });
            if (results.isNotEmpty && widget.config.prefetchEnabled) {
              _service.prefetchThumbnails(results.take(30).toList());
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
    final granted = await _service.requestPermission();
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
    final albums = await _service.getAlbums(widget.config.requestType);
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

    final assets = await _service.getAssets(
      album: _currentAlbum!,
      page: _page,
      pageSize: _pageSize,
    );

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
    // ── Pagination trigger (1500px = ~2 screens ahead) ────────────────────
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 1500) {
      if (!_isLoadingMore && _hasMore && !_isLoading) _loadAssets();
    }

    // ── Prefetch thumbnails for items about to come on screen ────────────
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
    _service.prefetchThumbnails(_assets.sublist(startIdx, endIdx));
  }

  Future<void> _switchAlbum(AssetPathEntity album) async {
    if (album.id == _currentAlbum?.id) return;
    setState(() {
      _currentAlbum = album;
      _selected.clear();
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
    await _loadAssets(reset: true);
  }

  void _toggleSelection(AssetEntity asset) {
    HapticFeedback.selectionClick();
    final idx = _selected.indexWhere((e) => e.id == asset.id);
    if (idx >= 0) {
      setState(() => _selected.removeAt(idx));
    } else if (_selected.length < widget.config.maxSelection) {
      setState(() => _selected.add(asset));
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _onCameraCaptured(File file) async {
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
        if (mounted) Navigator.of(context).pop([savedAsset]);
      } else {
        // Multi select: add to selection and reload grid
        setState(() {
          if (_selected.length < widget.config.maxSelection) {
            _selected.add(savedAsset);
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

  Future<void> _onVideoTap(AssetEntity asset) async {
    final confirmed = await VideoPreviewSheet.show(
      context,
      asset,
      _theme,
      widget.config.primaryColor,
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop([asset]);
    }
  }

  int _selectionIndex(AssetEntity asset) =>
      _selected.indexWhere((e) => e.id == asset.id);

  void _onConfirm() {
    if (_selected.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    final items = _selected.map((asset) {
      return MediaItem(
        asset: asset,
        useOriginalFile: widget.config.useOriginalFile,
        editedFile: _editedFiles[asset.id],
      );
    }).toList();

    Navigator.of(context).pop(items);
  }

  void _showAlbumSheet() {
    if (_albums.length <= 1) return;
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
          currentAlbum: _currentAlbum,
          primaryColor: widget.config.primaryColor,
          theme: _theme,
          scrollController: scrollController,
          service: _service,
          onSelect: (album) {
            Navigator.pop(context);
            _switchAlbum(album);
          },
        ),
      ),
    ).whenComplete(() {
      if (mounted) _chevronCtrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _theme.overlayStyle,
      child: Scaffold(
        backgroundColor: _theme.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
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
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: _theme.secondaryText,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      widget.config.cancelText,
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
                                ? 'Vidéos'
                                : (_currentAlbum?.name ?? 'Photos'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _theme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (_albums.length > 1 && !_isVideoMode) ...[
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                          parent: anim, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: (!_isVideoMode && _selected.isNotEmpty)
                        ? SendButton(
                            key: const ValueKey('send'),
                            label: widget.config.confirmText,
                            count: _selected.length,
                            color: widget.config.primaryColor,
                            onTap: _onConfirm,
                          )
                        : const SizedBox(key: ValueKey('empty'), width: 80),
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
    if (_permissionDenied) return _buildPermissionDenied();

    return Column(
      children: [
        Container(height: 0.5, color: _theme.separator),
        _buildInlineSearchBar(),
        Expanded(child: _buildGrid()),
        if (!_isVideoMode)
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

  Widget _buildInlineSearchBar() {
    return Container(
      color: _theme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _theme.background, // Contrast against surface
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style: TextStyle(color: _theme.primaryText, fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom...',
            hintStyle:
                TextStyle(color: _theme.secondaryText.withValues(alpha: 0.5)),
            prefixIcon:
                Icon(Icons.search, color: _theme.secondaryText, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel,
                        color: _theme.secondaryText, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      _searchFocus.unfocus();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: _theme.elevated),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 9.5),
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
              'Aucun résultat pour "$_searchQuery"',
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

    final displayAssets =
        (_isSearching && _searchQuery.isNotEmpty) ? _searchResults : _assets;

    if (!_isSearching && _assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVideoMode
                  ? Icons.videocam_outlined
                  : Icons.photo_library_outlined,
              size: 56,
              color: _theme.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              _isVideoMode ? 'Aucune vidéo trouvée' : 'Aucune photo trouvée',
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

    // Determine if the camera tile should be shown
    final showCamera = !_isSearching && widget.config.showCameraTile;
    final cameraOffset = showCamera ? 1 : 0;
    final enableSwipe = !_isVideoMode && widget.config.enableSwipeToSelect;

    // Pagination only when not searching
    final bool isLoadingMoreAssets = _isSearching ? false : _isLoadingMore;
    final int extraLoadingItems = isLoadingMoreAssets ? 3 : 0;

    return DraggableSelectionGrid(
        scrollController: _scrollController,
        enabled: enableSwipe,
        onAssetHover: (asset) {
          // Toggle selection during swipe (only add or remove once per drag pass)
          final idx = _selectionIndex(asset);
          if (idx == -1 && _selected.length < widget.config.maxSelection) {
            HapticFeedback.selectionClick();
            setState(() => _selected.add(asset));
          }
        },
        child: MasonryGridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(1.5),
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
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
            final selIdx = _selectionIndex(asset);
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
                  showPlayOverlay:
                      _isVideoMode || asset.type == AssetType.video,
                  onTap: () => _isVideoMode
                      ? _onVideoTap(asset)
                      : _toggleSelection(asset),
                ),
              ),
            );
          },
        ));
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _selected.length,
            itemBuilder: (_, i) {
              final asset = _selected[i];
              return SelectedPreviewItem(
                key: ValueKey(asset.id),
                asset: asset,
                index: i + 1,
                primaryColor: widget.config.primaryColor,
                onRemove: () => _toggleSelection(asset),
                editedFile: _editedFiles[asset.id],
                onEdit: (widget.config.onEditMedia != null && asset.type == AssetType.image)
                    ? () async {
                        HapticFeedback.lightImpact();
                        try {
                          final originalFile = widget.config.useOriginalFile 
                              ? await asset.originFile 
                              : await asset.file;
                          
                          if (originalFile == null || !mounted) return;

                          final newFile = await widget.config.onEditMedia!(
                            context,
                            asset,
                            originalFile,
                          );

                          if (newFile != null && mounted) {
                            setState(() {
                              _editedFiles[asset.id] = newFile;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error invoking onEditMedia: $e');
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

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(color: _theme.elevated, shape: BoxShape.circle),
              child: Icon(Icons.image_not_supported_outlined,
                  size: 38, color: _theme.secondaryText),
            ),
            const SizedBox(height: 24),
            Text(
              'Accès aux photos refusé',
              style: TextStyle(
                color: _theme.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Autorisez l\'accès dans les réglages pour continuer.',
              style: TextStyle(
                  color: _theme.secondaryText, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => PhotoManager.openSetting(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.config.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Ouvrir les réglages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
