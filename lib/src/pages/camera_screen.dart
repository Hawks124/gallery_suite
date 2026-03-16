import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The capture mode for the built-in camera screen.
enum CameraCaptureMode {
  /// Capture a still photo.
  photo,

  /// Record a video.
  video,
}

/// A premium, full-screen camera screen built with the `camera` package.
///
/// This screen is launched internally by the picker when the user taps the
/// camera tile in the media grid. It handles photo capture or video recording
/// based on [captureMode].
///
/// Returns a [File] via [Navigator.pop] on success, or `null` on cancel.
class CameraScreen extends StatefulWidget {
  /// Whether to capture a photo or record a video.
  final CameraCaptureMode captureMode;

  /// The primary accent color for UI elements (capture button ring, etc.).
  final Color primaryColor;

  const CameraScreen({
    super.key,
    required this.captureMode,
    required this.primaryColor,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isRecording = false;
  bool _hasFlash = true;
  FlashMode _flashMode = FlashMode.auto;

  // Animation controllers
  late AnimationController _captureAnimCtrl;
  late AnimationController _flipAnimCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _flipAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose().catchError((e) => debugPrint('Screen dispose error: $e'));
    _captureAnimCtrl.dispose();
    _flipAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose().catchError((e) => debugPrint('Lifecycle dispose error: $e'));
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      await _setupController(_cameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    try {
      await _controller?.dispose();
    } catch (e) {
      debugPrint('Old controller dispose error: $e');
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: widget.captureMode == CameraCaptureMode.video,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();

      // Check flash support
      try {
        await controller.setFlashMode(_flashMode);
        _hasFlash = true;
      } catch (_) {
        _hasFlash = false;
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    HapticFeedback.lightImpact();
    _flipAnimCtrl.forward(from: 0);

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupController(_cameras[_currentCameraIndex]);
  }

  void _cycleFlashMode() {
    if (!_hasFlash) return;
    HapticFeedback.selectionClick();

    setState(() {
      switch (_flashMode) {
        case FlashMode.auto:
          _flashMode = FlashMode.always;
          break;
        case FlashMode.always:
          _flashMode = FlashMode.off;
          break;
        case FlashMode.off:
          _flashMode = FlashMode.auto;
          break;
        default:
          _flashMode = FlashMode.auto;
      }
    });
    _controller?.setFlashMode(_flashMode);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
      default:
        return Icons.flash_auto_rounded;
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();
    _captureAnimCtrl.forward().then((_) => _captureAnimCtrl.reverse());

    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        Navigator.of(context).pop(File(xFile.path));
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      // Stop recording
      try {
        final xFile = await _controller!.stopVideoRecording();
        HapticFeedback.heavyImpact();
        if (mounted) {
          Navigator.of(context).pop(File(xFile.path));
        }
      } catch (e) {
        debugPrint('Stop recording error: $e');
        setState(() => _isRecording = false);
      }
    } else {
      // Start recording
      setState(() => _isRecording = true);
      HapticFeedback.mediumImpact();

      try {
        await _controller!.startVideoRecording();
      } catch (e) {
        debugPrint('Start recording error: $e');
        setState(() => _isRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isInitialized
            ? _buildCameraView()
            : const Center(
                child: CircularProgressIndicator(color: Colors.white38),
              ),
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _controller!;
    final double aspectRatio = controller.value.aspectRatio;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview — fills the screen
        Center(
          child: AspectRatio(
            aspectRatio: 1 / aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Subtle vignette overlay for premium feel
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),

        // Top controls (back, flash)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                  if (_hasFlash)
                    _buildControlButton(
                      icon: _flashIcon,
                      onTap: _cycleFlashMode,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls (flip, capture/record, placeholder)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 28,
                top: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flip camera button
                  _cameras.length > 1
                      ? RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0)
                              .animate(CurvedAnimation(
                            parent: _flipAnimCtrl,
                            curve: Curves.easeInOutBack,
                          )),
                          child: _buildControlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            onTap: _switchCamera,
                            size: 28,
                          ),
                        )
                      : const SizedBox(width: 48),

                  // Capture button
                  _buildCaptureButton(),

                  // Spacer for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record,
                          color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    final isVideo = widget.captureMode == CameraCaptureMode.video;

    return GestureDetector(
      onTap: isVideo ? _toggleVideoRecording : _capturePhoto,
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.88).animate(CurvedAnimation(
          parent: _captureAnimCtrl,
          curve: Curves.easeInOut,
        )),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _isRecording ? BorderRadius.circular(8) : null,
              color: isVideo
                  ? (_isRecording ? Colors.red : Colors.red.shade400)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
