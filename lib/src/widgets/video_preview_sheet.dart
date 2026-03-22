import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../models/picker_theme.dart';

class VideoPreviewSheet extends StatefulWidget {
  final AssetEntity asset;
  final PickerTheme theme;
  final Color primaryColor;

  const VideoPreviewSheet({
    super.key,
    required this.asset,
    required this.theme,
    required this.primaryColor,
  });

  static Future<bool> show(
    BuildContext context,
    AssetEntity asset,
    PickerTheme theme,
    Color primaryColor,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85), // Deep cinematic background
      builder: (_) => VideoPreviewSheet(
        asset: asset,
        theme: theme,
        primaryColor: primaryColor,
      ),
    );
    return result == true;
  }

  @override
  State<VideoPreviewSheet> createState() => _VideoPreviewSheetState();
}

class _VideoPreviewSheetState extends State<VideoPreviewSheet>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    File? file;
    try {
      file = await widget.asset.file;
    } catch (_) {}

    if (file == null || !file.existsSync()) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      _fadeController.forward();
      // Auto-play immediately
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      if (ctrl.value.position >= ctrl.value.duration) {
        ctrl.seekTo(Duration.zero);
      }
      ctrl.play();
    }
    setState(() {});
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final ar = (widget.asset.width > 0 && widget.asset.height > 0)
        ? widget.asset.width / widget.asset.height
        : 16.0 / 9.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.92,
          decoration: BoxDecoration(
            color: widget.theme.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Pill handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.theme.primaryText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 8),

              // Glassmorphic Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aperçu Vidéo',
                            style: TextStyle(
                              color: widget.theme.secondaryText,
                              fontSize: 13,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.asset.title ?? 'Sans titre',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.theme.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.theme.primaryText.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            color: widget.theme.primaryText, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cinematic Video Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildVideoArea(ar),
                ),
              ),

              // Premium Controls
              FadeTransition(
                opacity: _fadeController,
                child: _buildControls(),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoArea(double ar) {
    if (_isInitializing) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: CircularProgressIndicator(
              color: widget.primaryColor, strokeWidth: 3),
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          color: widget.theme.elevated,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file_outlined,
                  color: widget.theme.secondaryText, size: 48),
              const SizedBox(height: 16),
              Text(
                'Impossible de lire cette vidéo.',
                style: TextStyle(
                    color: widget.theme.secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final ctrl = _controller!;
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: AspectRatio(
              aspectRatio: ar.clamp(0.4, 2.5),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  VideoPlayer(ctrl),
                  // Tap overlay: massive frosted play icon
                  Center(
                    child: AnimatedOpacity(
                      opacity: isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
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
    );
  }

  Widget _buildControls() {
    final ctrl = _controller;
    if (ctrl == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: _buildSelectButton(),
      );
    }

    final value = ctrl.value;
    final total = value.duration;
    final pos = value.position;
    final progress = total.inMilliseconds > 0
        ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause + Sleek Scrubber row
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7, elevation: 4),
                        activeTrackColor: widget.primaryColor,
                        inactiveTrackColor:
                            widget.theme.primaryText.withValues(alpha: 0.08),
                        thumbColor: widget.primaryColor,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: progress.toDouble(),
                        onChanged: (v) {
                          final ms = (v * total.inMilliseconds).round();
                          ctrl.seekTo(Duration(milliseconds: ms));
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fmt(pos),
                            style: TextStyle(
                              color: widget.theme.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _fmt(total),
                            style: TextStyle(
                              color: widget.theme.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildSelectButton(),
        ],
      ),
    );
  }

  Widget _buildSelectButton() {
    return GestureDetector(
      onTap: () {
        _controller?.pause();
        Navigator.of(context).pop(true);
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              widget.primaryColor,
              HSLColor.fromColor(widget.primaryColor)
                  .withLightness(0.4)
                  .toColor(),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Sélectionner cette vidéo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
