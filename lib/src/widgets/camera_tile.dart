import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/camera_screen.dart';

/// A premium, live-preview camera tile displayed at position 0 of the
/// media grid when [PickerConfig.showCameraTile] is `true`.
///
/// On supported platforms (Android, iOS, Web), the tile shows a real-time
/// camera preview with a frosted-glass overlay and an animated camera icon.
/// On platforms without camera support, the tile shows a static camera icon
/// with a subtle gradient background.
///
/// Tapping the tile opens the built-in [CameraScreen].
class CameraTileWidget extends StatefulWidget {
  /// The primary accent color used for the icon and overlay tint.
  final Color primaryColor;

  /// Whether the picker is in dark mode.
  final bool isDark;

  /// Whether to capture a photo or a video.
  final CameraCaptureMode captureMode;

  /// Called with the captured [File] after the user takes a photo or video.
  final ValueChanged<File> onCaptured;

  const CameraTileWidget({
    super.key,
    required this.primaryColor,
    required this.isDark,
    required this.captureMode,
    required this.onCaptured,
  });

  @override
  State<CameraTileWidget> createState() => _CameraTileWidgetState();
}

class _CameraTileWidgetState extends State<CameraTileWidget>
    with SingleTickerProviderStateMixin {
  CameraController? _previewController;
  bool _previewReady = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _initPreview();
  }

  @override
  void dispose() {
    _previewController?.dispose().catchError((e) => debugPrint('Tile preview dispose error: $e'));
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPreview() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;

      // Prefer front camera for the tile preview (selfie-style feel)
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.low, // Low-res for the tile, saves battery
        enableAudio: false,
      );

      await controller.initialize();
      if (mounted) {
        setState(() {
          _previewController = controller;
          _previewReady = true;
        });
      }
    } catch (e) {
      // Camera not available on this platform — show static tile
      debugPrint('Camera tile preview unavailable: $e');
    }
  }

  Future<void> _openCamera() async {
    HapticFeedback.lightImpact();

    // 💡 CRITICAL FIX: Dispose of the tile's preview controller BEFORE opening the 
    // full-screen camera to prevent hardware collision and CameraX crashes on Android.
    final oldController = _previewController;
    if (mounted) {
      setState(() {
        _previewReady = false;
        _previewController = null;
      });
    }
    
    if (oldController != null) {
      try {
        await oldController.dispose();
      } catch (e) {
        debugPrint('Error disposing preview controller: $e');
      }
    }

    final File? result = await Navigator.of(context).push<File?>(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => CameraScreen(
          captureMode: widget.captureMode,
          primaryColor: widget.primaryColor,
        ),
        transitionsBuilder: (ctx, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );

    if (result != null && mounted) {
      widget.onCaptured(result);
    }

    // 💡 Resume the preview after returning from the full-screen camera
    if (mounted) {
      _initPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openCamera,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: live preview or gradient fallback
            if (_previewReady && _previewController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _previewController!.value.previewSize?.height ?? 100,
                  height: _previewController!.value.previewSize?.width ?? 100,
                  child: CameraPreview(_previewController!),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.isDark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFE8EAF0),
                      widget.isDark
                          ? const Color(0xFF16213E)
                          : const Color(0xFFCDD5E0),
                    ],
                  ),
                ),
              ),

            // Frosted overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: _previewReady ? 0.25 : 0.0),
              ),
            ),

            // Animated camera icon
            Center(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseCtrl.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.primaryColor.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.captureMode == CameraCaptureMode.video
                        ? Icons.videocam_rounded
                        : Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            // Label
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text(
                widget.captureMode == CameraCaptureMode.video
                    ? 'Vidéo'
                    : 'Photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _previewReady ? Colors.white : (widget.isDark
                      ? Colors.white70
                      : Colors.black54),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  shadows: _previewReady
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
