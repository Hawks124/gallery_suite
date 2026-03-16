import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'models/picker_config.dart';
import 'models/picker_theme.dart';
import 'pages/audio_picker_page.dart';
import 'pages/camera_screen.dart';
import 'services/media_service.dart';
import 'widgets/camera_tile.dart';
import 'widgets/media_thumbnail.dart';
import 'widgets/video_preview_sheet.dart';
import 'widgets/send_button.dart';
import 'widgets/pulsing_skeleton_grid.dart';
import 'widgets/album_selector_sheet.dart';

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
  /// Returns `null` if the user cancels, or a non-empty [List<AssetEntity>]
  /// with the selected assets.
  static Future<List<AssetEntity>?> show({
    required BuildContext context,
    PickerConfig config = const PickerConfig(),
  }) {
    final isAudio = config.requestType == RequestType.audio;

    return Navigator.of(context).push<List<AssetEntity>?>(
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
  final MediaService _service = MediaService();
  final ScrollController _scrollController = ScrollController();

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _permissionDenied = false;
  int _page = 0;

  static const int _pageSize = 80;

  late AnimationController _chevronCtrl;

  late PickerTheme _theme;

  bool get _isVideoMode => widget.config.requestType == RequestType.video;

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    _chevronCtrl.dispose();
    MediaService.cancelAll();
    super.dispose();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 800) {
      if (!_isLoadingMore && _hasMore && !_isLoading) _loadAssets();
    }
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
      final AssetEntity? savedAsset = await (
        _isVideoMode
          ? PhotoManager.editor.saveVideo(
              file,
              title: 'Captured_${DateTime.now().millisecondsSinceEpoch}.mp4',
            )
          : PhotoManager.editor.saveImageWithPath(
              file.path,
              title: 'Captured_${DateTime.now().millisecondsSinceEpoch}.jpg',
            )
      );

      if (savedAsset != null) {
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
    Navigator.of(context).pop(
      _selected.isEmpty ? null : List<AssetEntity>.from(_selected),
    );
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
        expand: false,
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

  Widget _buildGrid() {
    if (_isLoading) return PulsingSkeletonGrid(theme: _theme);

    if (_assets.isEmpty) {
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
    final showCamera = widget.config.showCameraTile;
    final cameraOffset = showCamera ? 1 : 0;

    return MasonryGridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(1.5),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      mainAxisSpacing: 1.5,
      crossAxisSpacing: 1.5,
      itemCount: _assets.length + cameraOffset + (_isLoadingMore ? 3 : 0),
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

        if (assetIndex >= _assets.length) {
          return AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(color: _theme.shimmerBase),
          );
        }
        final asset = _assets[assetIndex];
        final selIdx = _selectionIndex(asset);
        final isSelected = selIdx >= 0;

        final double ar = (asset.width > 0 && asset.height > 0)
            ? asset.width / asset.height
            : 1.0;

        return AspectRatio(
          aspectRatio: ar.clamp(0.35, 2.8),
          child: MediaThumbnailWidget(
            key: ValueKey(asset.id),
            asset: asset,
            isSelected: isSelected,
            selectionNumber: isSelected ? selIdx + 1 : null,
            primaryColor: widget.config.primaryColor,
            isDark: _theme.isDark,
            showPlayOverlay: _isVideoMode || asset.type == AssetType.video,
            onTap: () =>
                _isVideoMode ? _onVideoTap(asset) : _toggleSelection(asset),
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _selected.length,
            itemBuilder: (_, i) => SelectedPreviewItem(
              key: ValueKey(_selected[i].id),
              asset: _selected[i],
              index: i + 1,
              primaryColor: widget.config.primaryColor,
              onRemove: () => _toggleSelection(_selected[i]),
            ),
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
