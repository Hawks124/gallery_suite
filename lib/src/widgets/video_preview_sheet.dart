import 'dart:async';
import 'dart:io';
import 'dart:ui';
import '../utils/suite_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/picker_asset.dart';
import '../services/google_photos_service.dart';
import '../intl/picker_text_delegate.dart';
import '../models/picker_theme.dart';
import 'auth_image.dart';

class VideoPreviewSheet extends StatefulWidget {
  final PickerAsset asset;
  final PickerTheme theme;
  final Color primaryColor;
  final PickerTextDelegate textDelegate;
  final GooglePhotosService? googleService;
  final bool isMultiSelect;

  const VideoPreviewSheet({
    super.key,
    required this.asset,
    required this.theme,
    required this.primaryColor,
    required this.textDelegate,
    this.googleService,
    this.isMultiSelect = false,
  });

  static Future<bool> show(
    BuildContext context,
    PickerAsset asset,
    PickerTheme theme,
    Color primaryColor,
    PickerTextDelegate textDelegate,
    GooglePhotosService? googleService, {
    bool isMultiSelect = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          Colors.black.withValues(alpha: 0.85), // Deep cinematic background
      builder: (_) => VideoPreviewSheet(
        asset: asset,
        theme: theme,
        primaryColor: primaryColor,
        textDelegate: textDelegate,
        googleService: googleService,
        isMultiSelect: isMultiSelect,
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
  String? _blobUrl;

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
    final asset = widget.asset;
    VideoPlayerController? controller;

    try {
      if (asset is LocalPickerAsset) {
        final file = await asset.file;
        if (file == null || !file.existsSync()) {
          throw Exception('File not found');
        }
        controller = VideoPlayerController.file(file);
      } else if (asset is RemotePickerAsset) {
        String url = asset.fullUrl;
        if (widget.googleService != null) {
          if (kIsWeb) {
            // Web: download bytes and create a Blob URL for <video> tag
            final bytes = await widget.googleService!.getMediaBytes(url);
            if (bytes != null) {
              final blobUrl = WebUtils.createBlobUrl(bytes);
              if (blobUrl != null) {
                url = blobUrl;
                _blobUrl = blobUrl;
              }
            }
            controller = VideoPlayerController.networkUrl(
              Uri.parse(url),
              httpHeaders: asset.headers ?? {},
            );
          } else if (asset.baseUrl.contains('/ppa/')) {
            // Mobile/Desktop with ppa/ signed URLs: these URLs return image
            // data by default and CANNOT have =dv appended (breaks signature).
            // Download raw video bytes and write to a temp file.
            final bytes = await widget.googleService!.getMediaBytes(url);
            if (bytes != null && bytes.isNotEmpty) {
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/gp_video_${asset.id}.mp4');
              await tempFile.writeAsBytes(bytes);
              controller = VideoPlayerController.file(tempFile);
            } else {
              throw Exception(
                  'Failed to download video bytes from Google Photos');
            }
          } else {
            // Non-ppa remote URLs (standard Google Photos URLs with =dv suffix)
            controller = VideoPlayerController.networkUrl(
              Uri.parse(url),
              httpHeaders: asset.headers ?? {},
            );
          }
        } else {
          controller = VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: asset.headers ?? {},
          );
        }
      } else if (asset is FilePickerAsset) {
        if (kIsWeb) {
          // On Web, filePath is a Blob URI that networkUrl can handle
          controller = VideoPlayerController.networkUrl(
            Uri.parse(asset.filePath),
          );
        } else {
          final file = asset.file;
          if (!file.existsSync()) {
            throw Exception('File not found');
          }
          controller = VideoPlayerController.file(file);
        }
      }

      if (controller == null) throw Exception('Unsupported asset type');

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
    } catch (e) {
      debugPrint('VideoPreviewSheet init error: $e');
      controller?.dispose();

      // Fallback for Web: If the authenticated Blob fetch failed (likely CORS),
      // try the unauthenticated signed URL directly as a last resort.
      if (kIsWeb && _blobUrl == null && asset is RemotePickerAsset) {
        try {
          final fallbackController = VideoPlayerController.networkUrl(
            Uri.parse(asset.fullUrl),
          );
          await fallbackController.initialize();
          if (mounted) {
            fallbackController.addListener(() => setState(() {}));
            setState(() {
              _controller = fallbackController;
              _isInitializing = false;
              _hasError = false;
            });
            _fadeController.forward();
            fallbackController.play();
            return;
          }
        } catch (fallbackError) {
          debugPrint('VideoPreviewSheet fallback error: $fallbackError');
        }
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
        _fadeController.forward(); // Ensure "Select" button shows even on error
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller?.dispose();
    if (_blobUrl != null) {
      WebUtils.revokeBlobUrl(_blobUrl!);
    }
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
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _launchRemoteUrl(String url) {
    if (kIsWeb) {
      WebUtils.openUrlInNewTab(url);
    }
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
                            widget.textDelegate.videoPreviewTitle,
                            style: TextStyle(
                              color: widget.theme.secondaryText,
                              fontSize: 13,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.asset.title ??
                                widget.textDelegate.videoUntitled,
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
                          color:
                              widget.theme.primaryText.withValues(alpha: 0.05),
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
        child: Stack(
          children: [
            // Fallback/Error state for Web: Show a frame and option to open in new tab
            if (_hasError && kIsWeb && widget.asset is RemotePickerAsset)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AuthImage(
                            imageUrl:
                                (widget.asset as RemotePickerAsset).thumbUrl,
                            googleService: widget.googleService,
                            theme: widget.theme,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'CORS restricted on Web. You can still select this video or open it to view.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.theme.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _launchRemoteUrl(
                            (widget.asset as RemotePickerAsset).baseUrl),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open in Google Photos'),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasError && !kIsWeb)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_outlined,
                        size: 48, color: widget.theme.secondaryText),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to play this video.',
                      style: TextStyle(color: widget.theme.secondaryText),
                    ),
                  ],
                ),
              ),
          ],
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
    if (ctrl == null || _hasError) {
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
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          Text(
                            _fmt(total),
                            style: TextStyle(
                              color: widget.theme.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
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
        child: Text(
          widget.isMultiSelect
              ? widget.textDelegate.confirm
              : widget.textDelegate.videoSelectButton,
          style: const TextStyle(
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
