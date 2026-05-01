import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

import '../../gallery_suite.dart';

/// Full-screen preview for the standalone multi-camera feature.
/// Allows the user to swipe through their captured photos, delete them,
/// or invoke the BYOE (Editor) hook before confirming the batch.
class CapturePreviewScreen extends StatefulWidget {
  final List<XFile> capturedFiles;
  final int initialIndex;
  final CameraPickerConfig config;

  const CapturePreviewScreen({
    super.key,
    required this.capturedFiles,
    required this.initialIndex,
    required this.config,
  });

  @override
  State<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends State<CapturePreviewScreen> {
  late PageController _pageController;
  late List<XFile> _currentFiles;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentFiles = List.from(widget.capturedFiles);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDelete() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentFiles.removeAt(_currentIndex);
      if (_currentFiles.isEmpty) {
        Navigator.of(context).pop(<XFile>[]); // Empty session, go back
      } else {
        // Adjust currentIndex if we deleted the last item
        if (_currentIndex >= _currentFiles.length) {
          _currentIndex = _currentFiles.length - 1;
        }
      }
    });
  }

  Future<void> _onEdit() async {
    final hook = widget.config.onEditMedia;
    if (hook == null) return;

    final originalFile = File(_currentFiles[_currentIndex].path);
    final editedFile = await hook(
        context, null, originalFile); // Null asset because it's purely local

    if (editedFile != null && mounted) {
      setState(() {
        _currentFiles[_currentIndex] = XFile(editedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFiles.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: _currentFiles.length,
            itemBuilder: (context, index) {
              final file = File(_currentFiles[index].path);
              final path = file.path.toLowerCase();
              final isVideo = path.endsWith('.mp4') || path.endsWith('.mov');

              if (isVideo) {
                return _VideoPreviewItem(
                  file: file,
                  primaryColor: widget.config.primaryColor,
                );
              }

              return Image.file(
                file,
                fit: BoxFit.contain,
              );
            },
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(_currentFiles),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1} / ${_currentFiles.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
                top: 24,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: Text(widget.config.textDelegate.cameraActionDelete,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  if (widget.config.onEditMedia != null)
                    TextButton.icon(
                      onPressed: _onEdit,
                      icon:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                      label: Text(widget.config.textDelegate.cameraActionEdit,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.config.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      // Validate and return the finalised session files
                      Navigator.of(context).pop(_currentFiles);
                    },
                    child: Text(widget.config.textDelegate.confirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewItem extends StatefulWidget {
  final File file;
  final Color primaryColor;

  const _VideoPreviewItem({
    required this.file,
    required this.primaryColor,
  });

  @override
  State<_VideoPreviewItem> createState() => _VideoPreviewItemState();
}

class _VideoPreviewItemState extends State<_VideoPreviewItem> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.file(widget.file);
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(() => setState(() {}));
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      controller.setLooping(true);
      controller.play();
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
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
      ctrl.play();
    }
    setState(() {});
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _buildControls(VideoPlayerController ctrl) {
    final value = ctrl.value;
    final total = value.duration;
    final pos = value.position;
    final progress = total.inMilliseconds > 0
        ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: widget.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6, elevation: 2),
                    activeTrackColor: widget.primaryColor,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(pos),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _fmt(total),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(
        child: CircularProgressIndicator(
            color: widget.primaryColor, strokeWidth: 3),
      );
    }

    final ctrl = _controller;
    if (ctrl == null) {
      return const Center(
          child:
              Icon(Icons.videocam_off_outlined, color: Colors.white, size: 48));
    }

    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          ),
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
          // Position the controls safely above the Ok/Delete bottom bar
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 90,
            left: 20,
            right: 20,
            child: _buildControls(ctrl),
          ),
        ],
      ),
    );
  }
}
