import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'video_preview_sheet.dart';
import '../sources/media_source_factory.dart';
import '../pages/fullscreen_preview_page.dart';
import '../models/picker_asset.dart';
import '../models/picker_theme.dart';
import '../intl/picker_text_delegate.dart';
import '../services/google_photos_service.dart';
import 'auth_image.dart';

class MediaThumbnailWidget extends StatefulWidget {
  final PickerAsset asset;
  final bool isSelected;
  final int? selectionNumber;
  final Color primaryColor;
  final bool isDark;
  final bool showPlayOverlay;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final GooglePhotosService? googleService;
  final PickerTheme theme;

  const MediaThumbnailWidget({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
    required this.theme,
    this.googleService,
    this.showPlayOverlay = false,
    this.selectionNumber,
    this.onLongPress,
  });

  @override
  State<MediaThumbnailWidget> createState() => _MediaThumbnailWidgetState();
}

class _MediaThumbnailWidgetState extends State<MediaThumbnailWidget>
    with SingleTickerProviderStateMixin {
  Uint8List? _thumbnail;
  bool _loading = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _isPressed = false;
  bool _isLocallyAvailable = true;
  VideoPlayerController? _videoThumbnailController;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(MediaThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _pulseCtrl.repeat(reverse: true);
      setState(() {
        _thumbnail = null;
        _loading = true;
      });
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _videoThumbnailController?.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    final asset = widget.asset;

    if (asset is RemotePickerAsset) {
      // Remote assets don't need manual thumbnail loading.
      if (mounted) {
        _pulseCtrl.stop();
        setState(() => _loading = false);
      }
      return;
    }

    if (asset is LocalPickerAsset) {
      // Check iCloud status
      final isLocal = await asset.entity.isLocallyAvailable();
      if (mounted) setState(() => _isLocallyAvailable = isLocal);
    }

    if (asset is FilePickerAsset &&
        asset.bytes == null &&
        asset.type == AssetType.video) {
      _initVideoThumbnail();
      return;
    }

    if (asset is FilePickerAsset) {
      if (asset.bytes != null && asset.bytes!.isNotEmpty) {
        if (mounted) {
          _pulseCtrl.stop();
          setState(() {
            _thumbnail = asset.bytes;
            _loading = false;
          });
        }
        return;
      }

      if (asset.type == AssetType.image) {
        try {
          final file = File(asset.filePath);
          if (file.existsSync() && !kIsWeb) {
            final data = await file.readAsBytes();
            if (mounted) {
              _pulseCtrl.stop();
              setState(() {
                _thumbnail = data;
                _loading = false;
              });
            }
            return;
          }
        } catch (_) {}
      }
    }

    final source = MediaSourceFactory.activeSource;
    final data = await source.getThumbnail(asset);

    if (mounted) {
      _pulseCtrl.stop();
      setState(() {
        _thumbnail = data;
        _loading = false;
      });
    }
  }

  Future<void> _initVideoThumbnail() async {
    final asset = widget.asset;
    if (asset is! FilePickerAsset) return;

    try {
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(asset.filePath))
          : VideoPlayerController.file(File(asset.filePath));

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _pulseCtrl.stop();
      setState(() {
        _videoThumbnailController = controller;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[MediaThumbnail] Video init error: $e');
      if (mounted) {
        _pulseCtrl.stop();
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : (widget.isSelected ? 0.96 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              if (widget.asset.type == AssetType.video) _buildVideoBadge(),
              if (!_isLocallyAvailable && widget.asset is LocalPickerAsset)
                _buildCloudBadge(),
              if (widget.showPlayOverlay) _buildCenterPlayOverlay(),
              _buildSelectionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final asset = widget.asset;

    if (asset is RemotePickerAsset) {
      return AuthImage(
        imageUrl: asset.thumbUrl,
        googleService: widget.googleService,
        theme: widget.theme,
        headers: asset.headers,
      );
    }

    if (_loading) {
      return _buildShimmer();
    }

    if (_thumbnail == null) {
      if (asset.type == AssetType.video) {
        if (_videoThumbnailController != null &&
            _videoThumbnailController!.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _videoThumbnailController!.value.size.width,
              height: _videoThumbnailController!.value.size.height,
              child: VideoPlayer(_videoThumbnailController!),
            ),
          );
        }
        return Container(
          color: _themeBase(),
          child: Center(
            child: Icon(Icons.video_camera_back_outlined,
                color: widget.isDark ? Colors.white30 : Colors.black26,
                size: 32),
          ),
        );
      }
      return _buildShimmer();
    }

    return Image.memory(
      _thumbnail!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

  Color _themeBase() =>
      widget.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
  Color _themeHighlight() =>
      widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        return ColoredBox(
          color: Color.lerp(_themeBase(), _themeHighlight(), _pulseAnim.value)!,
        );
      },
    );
  }

  Widget _buildVideoBadge() {
    final d = widget.asset.duration;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Positioned(
      bottom: 6,
      right: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 11),
                const SizedBox(width: 2),
                Text(
                  '$mm:$ss',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPlayOverlay() {
    return Center(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    final isSelected = widget.isSelected;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isSelected ? 1.0 : 0.0,
          child: ColoredBox(
            color: widget.primaryColor.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          top: 7,
          right: 7,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: child,
            ),
            child: isSelected
                ? Container(
                    key: const ValueKey('sel'),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.selectionNumber ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('unsel'),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloudBadge() {
    return Positioned(
      top: 7,
      left: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.cloud_queue_rounded,
              color: Colors.white,
              size: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedPreviewItem extends StatefulWidget {
  final PickerAsset asset;
  final int index;
  final Color primaryColor;
  final VoidCallback onRemove;
  final PickerTheme theme;
  final GooglePhotosService? googleService;
  final File? editedFile;
  final Future<File?> Function()? onEdit;
  final PickerTextDelegate textDelegate;

  const SelectedPreviewItem({
    super.key,
    required this.asset,
    required this.index,
    required this.primaryColor,
    required this.onRemove,
    required this.theme,
    this.googleService,
    this.editedFile,
    this.onEdit,
    required this.textDelegate,
  });

  @override
  State<SelectedPreviewItem> createState() => _SelectedPreviewItemState();
}

class _SelectedPreviewItemState extends State<SelectedPreviewItem>
    with SingleTickerProviderStateMixin {
  Uint8List? _data;
  late AnimationController _enterCtrl;
  late Animation<double> _enterAnim;
  bool _isLocallyAvailable = true;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack);
    _load();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final asset = widget.asset;
    if (asset is RemotePickerAsset) return;

    if (asset is LocalPickerAsset) {
      final isLocal = await asset.entity.isLocallyAvailable();
      if (mounted) setState(() => _isLocallyAvailable = isLocal);
    }

    // Short-circuit for file-based assets (clipboard, desktop drop, etc.)
    // NativeMediaSource.getPreviewThumbnail() ignores these, returning null.
    if (asset is FilePickerAsset) {
      Uint8List? data;
      if (asset.bytes != null && asset.bytes!.isNotEmpty) {
        data = asset.bytes;
      } else if (!kIsWeb) {
        try {
          final f = File(asset.filePath);
          if (f.existsSync()) data = await f.readAsBytes();
        } catch (_) {}
      }
      if (mounted) setState(() => _data = data);
      return;
    }

    final source = MediaSourceFactory.activeSource;
    final data = await source.getPreviewThumbnail(asset);
    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _enterAnim,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                if (widget.asset.type == AssetType.video) {
                  VideoPreviewSheet.show(
                    context,
                    widget.asset,
                    widget.theme,
                    widget.primaryColor,
                    widget.textDelegate,
                    widget.googleService,
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => FullscreenPreviewPage(
                        asset: widget.asset,
                        thumbnail: _data,
                        editedFile: widget.editedFile,
                        onEdit: widget.onEdit,
                        theme: widget.theme,
                        googleService: widget.googleService,
                      ),
                    ),
                  );
                }
              },
              child: Hero(
                tag: 'preview_${widget.asset.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.editedFile != null
                      ? Image.file(
                          widget.editedFile!,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : (widget.asset is RemotePickerAsset)
                          ? AuthImage(
                              imageUrl:
                                  (widget.asset as RemotePickerAsset).thumbUrl,
                              googleService: widget.googleService,
                              theme: widget.theme,
                              headers:
                                  (widget.asset as RemotePickerAsset).headers,
                              width: 66,
                              height: 66,
                            )
                          : (_data != null
                              ? Image.memory(
                                  _data!,
                                  width: 66,
                                  height: 66,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : Container(
                                  width: 66,
                                  height: 66,
                                  color: const Color(0xFF2C2C2E),
                                )),
                ),
              ),
            ),
            if (!_isLocallyAvailable && widget.asset is LocalPickerAsset)
              _buildCloudBadge(),
            Positioned(
              top: -5,
              right: -5,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.black,
                    size: 13,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudBadge() {
    return Positioned(
      top: 5,
      left: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.cloud_queue_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),
        ),
      ),
    );
  }
}
