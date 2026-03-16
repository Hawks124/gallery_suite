import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:gallery_suite/gallery_suite.dart';

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
      title: 'Gallery Suite Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Assuming standard modern sans
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

  Future<void> _pickImages() async {
    // 💡 UNIQUE FEATURE: Gallery Suite handles the heavy lifting UI and camera natively.
    // By keeping `showCameraTile: true` (default), the user gets a live camera
    // exactly at index 0 of the grid, with no extra native setup from you.
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.image,
        maxSelection: 10,
        showCameraTile: true, // 📸 Built-in camera integration
        primaryColor: const Color(0xFF4F46E5),
        brightness: Theme.of(context).brightness,
        confirmText: 'Select',
        cancelText: 'Cancel',
      ),
    );

    if (assets == null || !mounted) return;

    // 💡 BEST PRACTICE: The picker returns `AssetEntity` (from photo_manager)
    // to keep scrolling at 60fps. You must extract the standard Dart `File`
    // asynchronously before uploading them to your backend.
    final files = (await Future.wait(assets.map((e) => e.file)))
        .whereType<File>()
        .toList();

    setState(() => _pickedImages
      ..clear()
      ..addAll(files));
  }

  Future<void> _pickVideo() async {
    // 💡 The built-in videoplayer preview allows users to play
    // and review the video inline BEFORE confirming.
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.video,
        maxSelection: 1, // Videos are usually single-select
        showCameraTile: true, // 📸 Allows recording video straight from the grid
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

  Future<void> _pickAudio() async {
    // 💡 Unlike most pickers, the Audio mode supports both inline
    // playback (using just_audio) and multi-selection natively.
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.audio,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding + 24, left: 24, right: 24, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gallery Suite 1.0',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Cards List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  title: 'Photos & Camera',
                  subtitle: 'Live Native Camera • Masonry Grid • Multi-select',
                  icon: Icons.camera_enhance_rounded,
                  color: const Color(0xFF4F46E5),
                  gradientColors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  onTap: _pickImages,
                  isDark: isDark,
                  child: _pickedImages.isNotEmpty ? _buildImagesPreview() : null,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'High-Res Video',
                  subtitle: 'Inline Playback • Trim • Seek',
                  icon: Icons.play_circle_fill_rounded,
                  color: const Color(0xFFE11D48),
                  gradientColors: [const Color(0xFFE11D48), const Color(0xFFF43F5E)],
                  onTap: _pickVideo,
                  isDark: isDark,
                  child: _pickedVideo != null ? _buildFilePreview(_pickedVideo!.path, Icons.videocam_rounded, const Color(0xFFE11D48)) : null,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Audio & Voice',
                  subtitle: 'Mini-player • Album Art • Multi-select',
                  icon: Icons.graphic_eq_rounded,
                  color: const Color(0xFF0D9488),
                  gradientColors: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                  onTap: _pickAudio,
                  isDark: isDark,
                  child: _pickedAudio != null ? _buildFilePreview(_audioTitle ?? _pickedAudio!.path, Icons.audiotrack_rounded, const Color(0xFF0D9488)) : null,
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

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
              color: color.withOpacity(0.08),
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
          highlightColor: color.withOpacity(0.05),
          splashColor: color.withOpacity(0.1),
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
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      size: 16,
                    ),
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: 20),
                  child,
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
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
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}
