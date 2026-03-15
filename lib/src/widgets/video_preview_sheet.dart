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
      barrierColor: Colors.black87,
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

class _VideoPreviewSheetState extends State<VideoPreviewSheet> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
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

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.theme.separator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.asset.title ?? 'Vidéo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.theme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: widget.theme.elevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: widget.theme.secondaryText, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: widget.theme.separator),
          // Video area
          Expanded(child: _buildVideoArea(ar)),
          // Controls
          _buildControls(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildVideoArea(double ar) {
    if (_isInitializing) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
              color: widget.primaryColor, strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: widget.theme.secondaryText, size: 52),
              const SizedBox(height: 12),
              Text(
                'Erreur de lecture',
                style:
                    TextStyle(color: widget.theme.secondaryText, fontSize: 14),
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
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: ar.clamp(0.4, 2.2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(ctrl),
                // Tap overlay: play icon
                AnimatedOpacity(
                  opacity: isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
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
    );
  }

  Widget _buildControls() {
    final ctrl = _controller;

    if (ctrl == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause + Seek row
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.theme.elevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.theme.primaryText,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: widget.primaryColor,
                        inactiveTrackColor: widget.theme.elevated,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(pos),
                              style: TextStyle(
                                  color: widget.theme.secondaryText,
                                  fontSize: 11)),
                          Text(_fmt(total),
                              style: TextStyle(
                                  color: widget.theme.secondaryText,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Sélectionner cette vidéo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
