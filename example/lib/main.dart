import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:gallery_suite/gallery_suite.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gallery Suite — Example App
//
// This example demonstrates EVERY feature of the package in a single,
// production-quality screen. It covers:
//
//   📸  Image Picker   — Masonry grid, multi-select, live camera tile,
//                         iOS-style swipe-to-select
//   🎬  Video Picker   — Inline video preview, single-select, camera recording
//   🎵  Audio Picker   — Inline just_audio playback, mini-player, multi-select
//   ⚙️  PickerConfig   — Every configurable parameter is showcased below
//
// Each picker call is heavily commented so you can copy-paste directly into
// your own project.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery Suite Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PickerDemoPage(),
    );
  }
}

class PickerDemoPage extends StatefulWidget {
  const PickerDemoPage({super.key});

  @override
  State<PickerDemoPage> createState() => _PickerDemoPageState();
}

class _PickerDemoPageState extends State<PickerDemoPage> {
  final List<File> _pickedImages = [];
  File? _pickedVideo;
  File? _pickedAudio;
  String? _audioTitle;

  // ── IMAGE PICKER ────────────────────────────────────────────────────────
  // This is the most feature-rich mode. It showcases:
  //   • showCameraTile         → live camera preview at grid position 0
  //   • enableSwipeToSelect    → long-press + drag to batch-select
  //   • maxSelection           → cap the number of selectable items
  //   • primaryColor           → brand accent for badges, buttons, seek bars
  //   • brightness             → pin the picker to dark or light mode
  //   • confirmText/cancelText → localize the UI labels
  Future<void> _pickImages() async {
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.image,

        // Maximum number of assets the user can pick.
        maxSelection: 10,

        // 📸 Live camera tile: a real-time camera preview appears as the
        // first tile in the grid. Tapping it opens a premium full-screen
        // camera with flash, flip, and glassmorphism UI.
        // Set to `false` if you handle camera externally.
        showCameraTile: true,

        // 👆 Swipe-to-select: long press on any tile, then drag your finger
        // across the grid to rapidly select multiple images without lifting.
        // The grid auto-scrolls when your finger nears the top/bottom edge.
        // Set to `false` if you prefer classic tap-only selection.
        enableSwipeToSelect: true,

        // 🎨 Brand accent used for selection badges, checkmarks, seek bars,
        // and the confirm button gradient.
        primaryColor: const Color(0xFF4F46E5),

        // Force a specific brightness, or omit to follow the system theme.
        brightness: Theme.of(context).brightness,

        // 🚀 Architecture & Performance: 
        // Tuned for 10,000+ photo libraries on ProMotion displays.
        thumbnailCacheSize: 200,     // LRU cache limit
        maxConcurrentDecodes: 3,     // Prevents frame drops during scroll
        prefetchEnabled: true,       // Preloads off-screen items to prevent pop-in

        // 🖼️ Original File vs System Cache:
        // Set to true to fetch the pristine bytes ignoring OS-level HEIC->JPG compression.
        // Defaults to false for speed and OS-level compatibility.
        useOriginalFile: false,

        // Localized button labels.
        confirmText: 'Select',
        cancelText: 'Cancel',
      ),
    );

    if (assets == null || !mounted) return;

    // The picker returns `List<MediaItem>`, a convenient wrapper around
    // `AssetEntity`. Extract standard Dart `File` objects asynchronously
    // before uploading to your backend.
    final files = (await Future.wait(assets.map((e) => e.file)))
        .whereType<File>()
        .toList();

    setState(() => _pickedImages
      ..clear()
      ..addAll(files));
  }

  // ── VIDEO PICKER ────────────────────────────────────────────────────────
  // The video picker displays the same masonry grid but with duration badges.
  // Tapping a tile opens an inline bottom-sheet video player so the user can
  // preview before confirming. The camera tile records video in this mode.
  Future<void> _pickVideo() async {
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.video,

        // Videos are typically single-select in messaging apps.
        maxSelection: 1,

        // 📸 The camera tile switches to video recording mode automatically
        // when requestType is set to video.
        showCameraTile: true,

        primaryColor: const Color(0xFFE11D48),
        brightness: Theme.of(context).brightness,
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    final file = await assets.first.file;
    if (file != null && mounted) {
      setState(() => _pickedVideo = file);
    }
  }

  // ── AUDIO PICKER ────────────────────────────────────────────────────────
  // Unlike most pickers, Gallery Suite provides a full audio list view
  // with album art, durations, and inline just_audio playback. The user
  // can tap to play/pause and review tracks before selecting.
  Future<void> _pickAudio() async {
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.audio,

        // Audio supports multi-select — perfect for playlist-style selection.
        maxSelection: 5,

        primaryColor: const Color(0xFF0D9488),
        brightness: Theme.of(context).brightness,
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    final file = await assets.first.file;
    if (file != null && mounted) {
      setState(() {
        _pickedAudio = file;
        _audioTitle = assets.first.title;
      });
    }
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 24,
                left: 24,
                right: 24,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF312E81)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gallery Suite v1.0.0',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF4338CA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Beautiful\nMedia Experiences.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Short feature highlights
                  Text(
                    'Camera • Swipe-to-Select • Masonry Grid • Inline Playback',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Action Cards ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  title: 'Photos & Camera',
                  subtitle:
                      'Live Camera • Masonry Grid • Swipe-to-Select • Multi-select',
                  icon: Icons.camera_enhance_rounded,
                  color: const Color(0xFF4F46E5),
                  gradientColors: [
                    const Color(0xFF4F46E5),
                    const Color(0xFF6366F1),
                  ],
                  onTap: _pickImages,
                  isDark: isDark,
                  child:
                      _pickedImages.isNotEmpty ? _buildImagesPreview() : null,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'High-Res Video',
                  subtitle: 'Inline Playback • Camera Recording • Seek',
                  icon: Icons.play_circle_fill_rounded,
                  color: const Color(0xFFE11D48),
                  gradientColors: [
                    const Color(0xFFE11D48),
                    const Color(0xFFF43F5E),
                  ],
                  onTap: _pickVideo,
                  isDark: isDark,
                  child: _pickedVideo != null
                      ? _buildFilePreview(
                          _pickedVideo!.path,
                          Icons.videocam_rounded,
                          const Color(0xFFE11D48),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Audio & Voice',
                  subtitle: 'Mini-player • Album Art • Multi-select',
                  icon: Icons.graphic_eq_rounded,
                  color: const Color(0xFF0D9488),
                  gradientColors: [
                    const Color(0xFF0D9488),
                    const Color(0xFF14B8A6),
                  ],
                  onTap: _pickAudio,
                  isDark: isDark,
                  child: _pickedAudio != null
                      ? _buildFilePreview(
                          _audioTitle ?? _pickedAudio!.path,
                          Icons.audiotrack_rounded,
                          const Color(0xFF0D9488),
                        )
                      : null,
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Card ─────────────────────────────────────────────────────
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: color.withValues(alpha: 0.05),
          splashColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      size: 16,
                    ),
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: 20),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image preview strip ──────────────────────────────────────────────
  Widget _buildImagesPreview() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _pickedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: FileImage(_pickedImages[i]),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ── File info row ─────────────────────────────────────────────────────
  Widget _buildFilePreview(String path, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}
