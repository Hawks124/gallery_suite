import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:gallery_suite/gallery_suite.dart';

class PickedMedia {
  final File? file;
  final Uint8List? bytes;
  final String title;
  PickedMedia({this.file, this.bytes, this.title = ''});
}

// ----------------------------------------------------------------------------
// Gallery Suite - Example App
//
// This example demonstrates EVERY feature of the package in a single,
// production-quality screen. It covers:
//
//    Image Picker   - Masonry grid, multi-select, live camera tile,
//                         iOS-style swipe-to-select
//    Video Picker   - Inline video preview, single-select, camera recording
//    Audio Picker   - Inline just_audio playback, mini-player, multi-select
//    PickerConfig   - Every configurable parameter is showcased below
//
// Each picker call is heavily commented so you can copy-paste directly into
// your own project.
// ----------------------------------------------------------------------------

// Entry point for the Gallery Suite example application.
void main() {
  // Ensure Flutter is initialized before calling services.
  WidgetsFlutterBinding.ensureInitialized();

  // -- GOOGLE PHOTOS INITIALIZATION ------------------------------------------
  // To enable Google Photos, you must initialize the service with your
  // Google Cloud credentials.
  //
  // 1. WEB: Create a 'Web Application' client ID in GCP.
  //    IMPORTANT: Add your origin (e.g. http://localhost:<port>) to
  //    'Authorized JavaScript origins' in GCP to avoid FedCM/CORS errors.
  //
  // 2. ANDROID/iOS: Create a 'Native' client ID in GCP.
  //    The redirectScheme MUST match the format 'com.googleusercontent.apps.<id>'.
  // --------------------------------------------------------------------------
  GooglePhotosService.instance.init(
    clientId: kIsWeb
        ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
        : 'YOUR_NATIVE_CLIENT_ID.apps.googleusercontent.com',
    apiKey: 'YOUR_API_KEY_HERE',
    redirectScheme: 'com.googleusercontent.apps.YOUR_NATIVE_CLIENT_ID',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ExampleApp());
}

// The root widget of the example application.
class ExampleApp extends StatelessWidget {
  // Creates an [ExampleApp].
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

// Main demonstration page showcasing the picker's diverse configurations.
class PickerDemoPage extends StatefulWidget {
  // Creates a [PickerDemoPage].
  const PickerDemoPage({super.key});

  @override
  State<PickerDemoPage> createState() => _PickerDemoPageState();
}

class _PickerDemoPageState extends State<PickerDemoPage> {
  // 📸 We store the processed files/bytes for the UI
  final List<PickedMedia> _pickedImages = [];
  PickedMedia? _pickedVideo;
  PickedMedia? _pickedAudio;

  // 🔄 We store the raw MediaItems to demonstrate the `initialSelection` state-restoration feature
  List<MediaItem> _selectedImageItems = [];
  List<MediaItem> _selectedVideoItems = [];
  List<MediaItem> _selectedAudioItems = [];

  // -- IMAGE PICKER --------------------------------------------------------
  // This is the most feature-rich mode. It showcases:
  //     showCameraTile           live camera preview at grid position 0
  //     enableSwipeToSelect      long-press + drag to batch-select
  //     maxSelection             cap the number of selectable items
  //     primaryColor             brand accent for badges, buttons, seek bars
  //     brightness               pin the picker to dark or light mode
  //     textDelegate             localize the UI labels (e.g. French, Spanish)
  Future<void> _pickImages() async {
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.image,

        // Maximum number of assets the user can pick.
        maxSelection: 10,

        //  [NEW] Dynamic Grid Layouts:
        // Instantly switch how your media is presented!
        // Options: masonry (default), aligned, quilted, staggered, byog.
        gridLayout: PickerGridLayout.quilted,

        // Bring Your Own Grid (BYOG):
        // If gridLayout is byog, inject your own ListView/PageView right here!
        // customGridBuilder: (ctx, scroll, count, builder) {
        //   return ListView.builder(
        //     controller: scroll, itemCount: count, itemBuilder: builder
        //   );
        // },

        //  Live camera tile: a real-time camera preview appears as the
        // first tile in the grid. Tapping it opens a premium full-screen
        // camera with flash, flip, and glassmorphism UI.
        // Set to `false` if you handle camera externally.
        showCameraTile: true,

        //  Swipe-to-select: long press on any tile, then drag your finger
        // across the grid to rapidly select multiple images without lifting.
        // The grid auto-scrolls when your finger nears the top/bottom edge.
        enableSwipeToSelect: true,

        //  Smart Clipboard integration: adds a tile to paste URLs, files, and bytes
        enableSmartClipboard: true,

        //  Restore previously selected items when the picker opens!
        initialSelection: _selectedImageItems,

        //  Bring Your Own Editor (BYOE): Add a custom image editor
        // without adding bloatware to the internal package!
        // Docs: https://<your-domain>/docs/architectures/byoe
        // Playground: https://<your-domain>/playground
        // Top alternatives: `image_cropper` or `pro_image_editor`
        // Tapping the Edit pencil in the Fullscreen Preview triggers this callback.
        // onEditMedia: (ctx, asset, file) async {
        //   if (asset.type != AssetType.image) return null;
        //   final completer = Completer<File?>();
        //   await Navigator.push(ctx, MaterialPageRoute(
        //     builder: (editorCtx) => ProImageEditor.file(
        //       file,
        //       callbacks: ProImageEditorCallbacks(
        //         onImageEditingComplete: (bytes) async {
        //           final newFile = File('${Directory.systemTemp.path}/edited.jpg');
        //           await newFile.writeAsBytes(bytes);
        //           if (!completer.isCompleted) completer.complete(newFile);
        //           if (editorCtx.mounted) Navigator.pop(editorCtx);
        //         },
        //         onCloseEditor: (_) {
        //           if (!completer.isCompleted) completer.complete(null);
        //           if (editorCtx.mounted) Navigator.pop(editorCtx);
        //         },
        //       ),
        //     ),
        //   ));
        //   return completer.isCompleted ? completer.future : null;
        // },

        //  Bring Your Own Drop (BYOD): Wrap the picker with your favorite
        // Desktop Drag-and-Drop package to accept dropped files magically!
        // Docs: https://<your-domain>/docs/architectures/byod
        // Playground: https://<your-domain>/playground
        // Top alternatives: `desktop_drop` or `super_drag_and_drop`
        // dropRegionBuilder: (context, child, onFilesDropped) {
        //   return DropTarget( // from desktop_drop package
        //     onDragDone: (details) {
        //         onFilesDropped(details.files);
        //     },
        //     child: child,
        //   );
        // },

        // Set to `false` if you prefer classic tap-only selection.
        // enableSwipeToSelect: false,

        //  Premium Cloud Integration: Google Photos (Picker API - 2026 Compliant)
        // Enable the built-in Google Photos tab. By default it works out-of-the-box
        // if your app uses Firebase. You can also explicitly pass Client IDs.
        // NOTE: Ensure "Google Photos Picker API" is enabled in your GCP Console.
        googlePhotosConfig: const GooglePhotosConfig(
          enabled: true,
          // NOTE: For Web, you MUST use a 'Web Application' Client ID from GCP.
          // clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
        ),

        //  Brand accent used for selection badges, checkmarks, seek bars,
        // and the confirm button gradient.
        primaryColor: const Color(0xFF4F46E5),

        // Force a specific brightness, or omit to follow the system theme.
        brightness: Theme.of(context).brightness,

        //  Internationalization: Zero-dependency translation!
        // Use EnglishPickerTextDelegate, FrenchPickerTextDelegate, or create your own.
        // You can even override specific words:
        textDelegate: const EnglishPickerTextDelegate(
          confirm: 'Choose',
        ),

        //  Architecture & Performance:
        // Tuned for 10,000+ photo libraries on ProMotion displays.
        thumbnailCacheSize: 200, // LRU cache limit
        maxConcurrentDecodes: 3, // Prevents frame drops during scroll
        prefetchEnabled: true, // Preloads off-screen items to prevent pop-in

        //  Original File vs System Cache:
        // Set to true to fetch the pristine bytes ignoring OS-level HEIC->JPG compression.
        // Defaults to false for speed and OS-level compatibility.
        useOriginalFile: false,

        //  [NEW] Hybrid Smart Compression:
        // Option 1: Enable the native built-in compressor (images only).
        // Will use flutter_image_compress native bridges to reduce file size before returning.
        // GREAT for images. Disabled by default.
        autoCompressImages: false,
        imageCompressionQuality:
            85, // 0-100, only effective if autoCompressImages is true.

        // Option 2: Use a BYOC (Bring Your Own Compressor) Hook.
        // This takes STRICT PRIORITY over autoCompressImages.
        // Docs: https://<your-domain>/docs/architectures/byoc
        // Playground: https://<your-domain>/playground
        // Top alternatives: `video_compress` or `light_compressor`
        // If your function returns null, the picker falls back to autoCompressImages.
        // onCompressMedia: (context, asset, originalFile) async {
        //   if (asset.type == AssetType.video) {
        //     // Example: compress video with the `video_compress` package
        //     final MediaInfo? info = await VideoCompress.compressVideo(
        //       originalFile.path,
        //       quality: VideoQuality.Res640x480Quality,
        //     );
        //     return info?.file;
        //   }
        //   return null; // Return null to keep original or use autoCompressImages
        // },

        //  Exit Confirmation: Prevent users from losing their selections
        // if they accidentally press the back button or swipe to pop.
        exitConfirmation: const StandardExitConfirmation(
          title: 'Discard selections?',
          content:
              'You have selected media. If you go back now, your current selections will be lost.',
          confirmText: 'Discard',
          cancelText: 'Cancel',
        ),

        // Localized button labels.
        confirmText: 'Select',
        cancelText: 'Cancel',
      ),
    );

    if (assets == null || !mounted) return;

    // The picker returns `List<MediaItem>`, a convenient wrapper around
    // Extract standard Dart `File` objects synchronously, or native Memory Bytes on Web.
    final items = <PickedMedia>[];
    for (final asset in assets) {
      if (kIsWeb && (asset.isFile || asset.isRemote)) {
        final b = await asset.bytes;
        if (b == null || b.isEmpty) continue;
        items.add(PickedMedia(
          bytes: b,
          title: asset.title ?? (asset.isRemote ? 'Cloud Image' : 'Web Image'),
        ));
      } else {
        final f = await asset.file;
        if (f != null) {
          items.add(PickedMedia(
            file: f,
            title: asset.title ?? f.path.split(RegExp(r'[\\/]')).last,
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _selectedImageItems = List.from(assets);
        _pickedImages
          ..clear()
          ..addAll(items);
      });
    }
  }

  // -- STANDALONE CAMERA ----------------------------------------------------
  // Bypass the gallery completely and open a dedicated multi-capture camera session!
  // Includes its own custom config: `CameraPickerConfig`.
  Future<void> _pickStandaloneCamera() async {
    final assets = await CustomMediaPicker.camera(
      context: context,
      config: CameraPickerConfig(
        maxSelection: 10,
        enableVideo: true,
        primaryColor: const Color(0xFF10B981), // Emerald
        brightness: Theme.of(context).brightness,

        // You can inject an editor exactly like in the Image Picker
        // onEditMedia: (ctx, asset, file) async { ... }

        exitConfirmation: const StandardExitConfirmation(
          title: 'Discard photo session?',
          content:
              'If you go back now, all the captures you just took will be lost.',
          confirmText: 'Discard',
          cancelText: 'Keep capturing',
        ),
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    final items = <PickedMedia>[];
    for (final asset in assets) {
      final f = await asset.file;
      if (f != null) {
        items.add(PickedMedia(
          file: f,
          title: asset.title ?? f.path.split(RegExp(r'[\\/]')).last,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _pickedImages
          ..clear()
          ..addAll(items);
      });
    }
  }

  // -- VIDEO PICKER --------------------------------------------------------
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

        //  The camera tile switches to video recording mode automatically
        // when requestType is set to video.
        showCameraTile: true,

        //  [NEW] Hybrid Smart Compression:
        // Use the BYOC hook to inject video compression (e.g. video_compress).
        // Since built-in compression only handles images, this is the way for videos.
        // onCompressMedia: (context, asset, file) async {
        //   if (asset.type == AssetType.video) {
        //      final MediaInfo? info = await VideoCompress.compressVideo(
        //        file.path,
        //        quality: VideoQuality.Res640x480Quality,
        //      );
        //      return info?.file;
        //   }
        //   return null;
        // },

        primaryColor: const Color(0xFFE11D48),
        brightness: Theme.of(context).brightness,
        enableSmartClipboard: true,
        initialSelection: _selectedVideoItems,
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    final asset = assets.first;
    _selectedVideoItems = List.from(assets);
    if (kIsWeb && (asset.isFile || asset.isRemote)) {
      final b = await asset.bytes;
      setState(() => _pickedVideo = PickedMedia(
            bytes: b,
            title:
                asset.title ?? (asset.isRemote ? 'Cloud Video' : 'Web Video'),
          ));
    } else {
      final f = await asset.file;
      if (f != null && mounted) {
        setState(() => _pickedVideo = PickedMedia(
              file: f,
              title: asset.title ?? f.path.split(RegExp(r'[\\/]')).last,
            ));
      }
    }
  }

  // -- AUDIO PICKER --------------------------------------------------------
  // Unlike most pickers, Gallery Suite provides a full audio list view
  // with album art, durations, and inline just_audio playback. The user
  // can tap to play/pause and review tracks before selecting.
  Future<void> _pickAudio() async {
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.audio,

        // Audio supports multi-select - perfect for playlist-style selection.
        maxSelection: 5,

        primaryColor: const Color(0xFF0D9488),
        brightness: Theme.of(context).brightness,
        enableSmartClipboard: true,
        initialSelection: _selectedAudioItems,
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    final asset = assets.first;
    _selectedAudioItems = List.from(assets);
    if (kIsWeb && (asset.isFile || asset.isRemote)) {
      final b = await asset.bytes;
      setState(() => _pickedAudio = PickedMedia(
            bytes: b,
            title:
                asset.title ?? (asset.isRemote ? 'Cloud Audio' : 'Web Audio'),
          ));
    } else {
      final f = await asset.file;
      if (f != null && mounted) {
        setState(() => _pickedAudio = PickedMedia(
              file: f,
              title: asset.title ?? f.path.split(RegExp(r'[\\/]')).last,
            ));
      }
    }
  }

  // -- BUILD --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // -- Header --------------------------------------------------
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
                    'Standalone Camera   Masonry Grid   Swipe-to-Select   Inline Playback',
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

          // -- Action Cards --------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  title: 'Masonry Gallery',
                  subtitle:
                      'All Media   Live Camera Tile   Swipe-to-Select   Cloud Provider',
                  icon: Icons.photo_library_rounded,
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
                  title: 'Standalone Camera',
                  subtitle: 'Multi-Capture   Session Strip   Video Toggle',
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF10B981),
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF34D399),
                  ],
                  onTap: _pickStandaloneCamera,
                  isDark: isDark,
                  child: null, // Captures update the image strip above
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'High-Res Video',
                  subtitle: 'Inline Playback   Camera Recording   Seek',
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
                          _pickedVideo!.title,
                          Icons.videocam_rounded,
                          const Color(0xFFE11D48),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Audio & Voice',
                  subtitle: 'Mini-player   Album Art   Multi-select',
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
                          _pickedAudio!.title,
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

  // -- Reusable Card ----------------------------------------------------
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

  // -- Image preview strip ----------------------------------------------
  Widget _buildImagesPreview() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _pickedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final media = _pickedImages[i];
          final hasImage = media.bytes != null || media.file != null;
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: hasImage ? null : const Color(0xFF334155),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              image: hasImage
                  ? DecorationImage(
                      image: media.bytes != null
                          ? MemoryImage(media.bytes!) as ImageProvider
                          : FileImage(media.file!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : const Icon(Icons.image_outlined,
                    color: Colors.white54, size: 32),
          );
        },
      ),
    );
  }

  // -- File info row ----------------------------------------------------
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
              path.split(RegExp(r'[\\/]')).last,
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
