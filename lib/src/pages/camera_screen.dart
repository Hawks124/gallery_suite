import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../gallery_suite.dart';

// A premium, full-screen camera screen built with the `camera` package.
//
// This screen is launched internally by the picker when the user taps the
// camera tile in the media grid. It handles photo capture or video recording
// based on [captureMode].
//
// Returns a [File] via [Navigator.pop] on success, or `null` on cancel.
class CameraScreen extends StatefulWidget {
  // Whether to capture a photo or record a video.
  final CameraCaptureMode captureMode;

  // The primary accent color for UI elements (capture button ring, etc.).
  final Color primaryColor;

  // The standalone configuration for multi-capture mode.
  final CameraPickerConfig? standaloneConfig;

  const CameraScreen({
    super.key,
    required this.captureMode,
    required this.primaryColor,
    this.standaloneConfig,
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
  bool _showVideoHint = false;

  // Recording timer state
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Standalone Multi-capture state
  final List<XFile> _capturedFiles = [];
  bool get _isStandalone => widget.standaloneConfig != null;

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

    // Show a brief "long press to record" hint when video is enabled
    if (_isStandalone && widget.standaloneConfig!.enableVideo) {
      _showVideoHint = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showVideoHint = false);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller
        ?.dispose()
        .catchError((e) => debugPrint('Screen dispose error: $e'));
    _captureAnimCtrl.dispose();
    _flipAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller
          ?.dispose()
          .catchError((e) => debugPrint('Lifecycle dispose error: $e'));
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

      // Check flash support (Web cameras do not have flash hardware)
      if (kIsWeb) {
        _hasFlash = false;
      } else {
        try {
          await controller.setFlashMode(_flashMode);
          _hasFlash = true;
        } catch (_) {
          _hasFlash = false;
        }
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
    if (_isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();
    _captureAnimCtrl.forward().then((_) => _captureAnimCtrl.reverse());

    try {
      final xFile = await _controller!.takePicture();
      HapticFeedback.lightImpact();
      if (mounted) {
        if (_isStandalone) {
          setState(() {
            _capturedFiles.add(xFile);
            _isCapturing = false;
          });
          // Dismiss the video hint on first interaction
          if (_showVideoHint) setState(() => _showVideoHint = false);
          // If maxSelection is 1, return immediately.
          if (widget.standaloneConfig!.maxSelection == 1) {
            _onConfirmStandalone();
          }
        } else {
          Navigator.of(context).pop(File(xFile.path));
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      // Stop recording – cancel timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      try {
        final xFile = await _controller!.stopVideoRecording();
        HapticFeedback.heavyImpact();
        if (mounted) {
          if (_isStandalone) {
            setState(() {
              _capturedFiles.clear();
              _capturedFiles.add(xFile);
              _isRecording = false;
              _recordingSeconds = 0;
            });
            _openCapturePreview(0);
          } else {
            Navigator.of(context).pop(File(xFile.path));
          }
        }
      } catch (e) {
        debugPrint('Stop recording error: $e');
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
        });
      }
    } else {
      // Start recording – start timer
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      HapticFeedback.mediumImpact();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });

      try {
        await _controller!.startVideoRecording();
      } catch (e) {
        debugPrint('Start recording error: $e');
        _recordingTimer?.cancel();
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
        });
      }
    }
  }

  Future<void> _onWillPop() async {
    if (!_isStandalone || _capturedFiles.isEmpty) {
      if (mounted) Navigator.of(context).pop<List<MediaItem>?>(null);
      return;
    }
    final confirmation = widget.standaloneConfig?.exitConfirmation ??
        const StandardExitConfirmation();

    final shouldPop = await confirmation.show(context, widget.primaryColor);
    
    if (shouldPop == true && mounted) {
      Navigator.of(context).pop<List<MediaItem>?>(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onWillPop();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _isInitialized
              ? _buildCameraView()
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white38),
                ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _controller!;
    // Using a 16:9 or 4:3 fit depending on the device to make it look premium
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview - scaled to fill screen with no borders
        Transform.scale(
          scale: scale,
          child: Center(
            child: CameraPreview(controller),
          ),
        ),

        // Deep vignette and gradient overlay for premium depth
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Top controls (back, flash) with Glassmorphism
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(
                    icon: Icons.close_rounded,
                    onTap: () => _onWillPop(),
                  ),
                  if (_hasFlash)
                    _buildGlassButton(
                      icon: _flashIcon,
                      onTap: _cycleFlashMode,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls (flip, capture/record)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 40,
              right: 40,
              bottom: MediaQuery.paddingOf(context).bottom + 32,
              top: 40,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // If standalone and we have captures, show the "Send" button instead of flip
                if (_isStandalone && _capturedFiles.isNotEmpty)
                  GestureDetector(
                    onTap: _onConfirmStandalone,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.black, size: 22),
                    ),
                  )
                else
                  const SizedBox(width: 52),

                // Grand Capture button
                _buildPremiumCaptureButton(),

                // Flip camera button
                _cameras.length > 1
                    ? RotationTransition(
                        turns:
                            Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                          parent: _flipAnimCtrl,
                          curve: Curves.easeInOutBack,
                        )),
                        child: _buildGlassButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onTap: _switchCamera,
                          size: 26,
                        ),
                      )
                    : const SizedBox(width: 52),
              ],
            ),
          ),
        ),

        // Recording indicator (Animated Pulse)
        if (_isRecording)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  // Ping-pong loop calculation
                  final opacity = (value - 0.5).abs() * 2;
                  return Opacity(
                    opacity: opacity.clamp(0.2, 1.0),
                    child: child,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            () {
                              final m = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
                              final s = (_recordingSeconds % 60).toString().padLeft(2, '0');
                              return '$m:$s';
                            }(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Standalone Capture Strip (Rafale Thumbs)
        if (_isStandalone &&
            _capturedFiles.isNotEmpty &&
            widget.standaloneConfig!.maxSelection > 1)
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 124,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _capturedFiles.length,
                itemBuilder: (context, index) {
                  final xFile = _capturedFiles[index];
                  return _buildCaptureStripItem(xFile, index);
                },
              ),
            ),
          ),

        // Long-press video hint (first entrance only)
        if (_showVideoHint)
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 132,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showVideoHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget
                                .standaloneConfig!.textDelegate.cameraVideoHint,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureStripItem(XFile xFile, int index) {
    final isVideo = xFile.path.toLowerCase().endsWith('.mp4') || xFile.path.toLowerCase().endsWith('.mov');
    return GestureDetector(
      onTap: () => _openCapturePreview(index),
      child: Container(
        width: 48,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          color: isVideo ? const Color(0xFF222222) : null,
          image: isVideo
              ? null
              : DecorationImage(
                  image: FileImage(File(xFile.path)),
                  fit: BoxFit.cover,
                ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: isVideo
            ? Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _openCapturePreview(int initialIndex) async {
    final result = await Navigator.of(context).push<List<XFile>>(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondary) => CapturePreviewScreen(
          capturedFiles: _capturedFiles,
          initialIndex: initialIndex,
          config: widget.standaloneConfig!,
        ),
        transitionsBuilder: (ctx, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _capturedFiles.clear();
        _capturedFiles.addAll(result);
      });
      // If user clicked "Done" with items, we should probably confirm the session natively.
      // But the Preview screen can also return the modified list just to continue shooting.
    }
  }

  Future<void> _onConfirmStandalone() async {
    if (_capturedFiles.isEmpty) return;

    // Map XFiles to MediaItems
    final mediaItems = _capturedFiles.map((xFile) {
      return MediaItem.fromXFile(xFile);
    }).toList();

    Navigator.of(context).pop(mediaItems);
  }

  Widget _buildPremiumCaptureButton() {
    final isVideoMode = widget.captureMode == CameraCaptureMode.video ||
        (_isStandalone && widget.standaloneConfig!.enableVideo);

    return GestureDetector(
      onTap: () {
        if (_showVideoHint) setState(() => _showVideoHint = false);
        
        final hasVideo = _capturedFiles.any((f) => f.path.toLowerCase().endsWith('.mp4') || f.path.toLowerCase().endsWith('.mov'));
        if (_isStandalone && hasVideo) {
          HapticFeedback.heavyImpact();
          return; // Cannot take photo if a video is already captured
        }
        
        if (_isStandalone &&
            _capturedFiles.length >= widget.standaloneConfig!.maxSelection) {
          HapticFeedback.heavyImpact();
          return;
        }
        _capturePhoto();
      },
      onLongPress: isVideoMode
          ? () {
              if (_showVideoHint) setState(() => _showVideoHint = false);
              
              final hasPhoto = _capturedFiles.isNotEmpty && !_capturedFiles.any((f) => f.path.toLowerCase().endsWith('.mp4') || f.path.toLowerCase().endsWith('.mov'));
              if (_isStandalone && hasPhoto) {
                HapticFeedback.heavyImpact();
                return; // Cannot record video if photos were already taken
              }

              if (_isStandalone &&
                  _capturedFiles.length >=
                      widget.standaloneConfig!.maxSelection) {
                return;
              }
              _toggleVideoRecording();
            }
          : null,
      onLongPressUp: isVideoMode
          ? () {
              if (_isRecording) _toggleVideoRecording();
            }
          : null,
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.85).animate(CurvedAnimation(
          parent: _captureAnimCtrl,
          curve: Curves.easeOutCirc,
        )),
        child: Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _isRecording ? BorderRadius.circular(12) : null,
              color: _isRecording
                  ? const Color(0xFFE11D48).withValues(alpha: 0.8)
                  : Colors.white,
            ),
            margin: EdgeInsets.all(_isRecording ? 18 : 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      ),
    );
  }
}
