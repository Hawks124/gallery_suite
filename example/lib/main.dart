import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:gallery_suite/gallery_suite.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'custom_media_picker demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
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
    // 1. Open the picker in "Image" mode
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.image,
        maxSelection: 10,
        primaryColor: Theme.of(context).colorScheme.primary,
        brightness: Theme.of(context).brightness,
        confirmText: 'Send',
        cancelText: 'Cancel',
      ),
    );

    // If the user cancels, the list will be null
    if (assets == null || !mounted) return;

    // 2. Extract the real files from the `AssetEntity`
    final files = (await Future.wait(assets.map((e) => e.file)))
        .whereType<File>()
        .toList();

    // 3. Update the UI with the selected files

    setState(() => _pickedImages
      ..clear()
      ..addAll(files));
  }

  Future<void> _pickVideo() async {
    // 1. Open the picker in "Video" mode (default maxSelection is 1)
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.video,
        maxSelection: 1,
        primaryColor: Theme.of(context).colorScheme.primary,
        brightness: Theme.of(context).brightness,
        confirmText: 'Send',
        cancelText: 'Cancel',
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    // 2. Extraire le premier fichier vidéo
    final file = await assets.first.file;
    if (file != null && mounted) {
      setState(() => _pickedVideo = file);
    }
  }

  Future<void> _pickAudio() async {
    // 1. Open the picker in "Audio" mode
    // With the backend, we can configure multi-select if needed by changing maxSelection
    final assets = await CustomMediaPicker.show(
      context: context,
      config: PickerConfig(
        requestType: RequestType.audio,
        maxSelection: 1,
        primaryColor: Theme.of(context).colorScheme.primary,
        brightness: Theme.of(context).brightness,
        confirmText: 'Send',
        cancelText: 'Cancel',
      ),
    );

    if (assets == null || assets.isEmpty || !mounted) return;

    // 2. Extract the first audio file and its title
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('custom_media_picker'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            icon: Icons.photo_library_rounded,
            title: 'Image Picker',
            subtitle: 'Multi-select · masonry grid · album switcher',
            color: const Color(0xFF6C63FF),
            onTap: _pickImages,
          ),
          if (_pickedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _pickedImages[i],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.videocam_rounded,
            title: 'Video Picker',
            subtitle: 'Single-select · inline preview · seek bar',
            color: const Color(0xFFE91E63),
            onTap: _pickVideo,
          ),
          if (_pickedVideo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFFE91E63)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickedVideo!.path.split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.headphones_rounded,
            title: 'Audio Picker',
            subtitle: 'Inline playback · mini player · just_audio',
            color: const Color(0xFF00BCD4),
            onTap: _pickAudio,
          ),
          if (_pickedAudio != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Color(0xFF00BCD4)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _audioTitle ??
                          _pickedAudio!.path.split(Platform.pathSeparator).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Text(
              'custom_media_picker v1.0.0',
              style: TextStyle(
                  color: scheme.onSurface.withAlpha(90), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: scheme.onSurface.withAlpha(140),
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: scheme.onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}
