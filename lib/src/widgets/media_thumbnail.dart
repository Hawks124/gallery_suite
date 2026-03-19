import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import '../pages/fullscreen_preview_page.dart';

class MediaThumbnailWidget extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionNumber;
  final Color primaryColor;
  final bool isDark;
  final bool showPlayOverlay;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MediaThumbnailWidget({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
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
  final MediaService _service = MediaService();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _isPressed = false;

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
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    final data = await _service.getThumbnail(widget.asset);
    if (mounted) {
      setState(() {
        _thumbnail = data;
        _loading = false;
      });
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
              if (widget.showPlayOverlay) _buildCenterPlayOverlay(),
              _buildSelectionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_loading || _thumbnail == null) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) {
          final base =
              widget.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA);
          final highlight =
              widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
          return ColoredBox(
            color: Color.lerp(base, highlight, _pulseAnim.value)!,
          );
        },
      );
    }
    return Image.memory(
      _thumbnail!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

  Widget _buildVideoBadge() {
    final d = widget.asset.videoDuration;
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
}

class SelectedPreviewItem extends StatefulWidget {
  final AssetEntity asset;
  final int index;
  final Color primaryColor;
  final VoidCallback onRemove;

  const SelectedPreviewItem({
    super.key,
    required this.asset,
    required this.index,
    required this.primaryColor,
    required this.onRemove,
  });

  @override
  State<SelectedPreviewItem> createState() => _SelectedPreviewItemState();
}

class _SelectedPreviewItemState extends State<SelectedPreviewItem>
    with SingleTickerProviderStateMixin {
  Uint8List? _data;
  final MediaService _service = MediaService();
  late AnimationController _enterCtrl;
  late Animation<double> _enterAnim;

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
    final data = await _service.getPreviewThumbnail(widget.asset);
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => FullscreenPreviewPage(
                      asset: widget.asset,
                      thumbnail: _data,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _data != null
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
                      ),
              ),
            ),
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
}
