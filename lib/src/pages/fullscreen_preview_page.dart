import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// A full-screen, zoomable preview page for a single media asset.
///
/// When the user taps a selected thumbnail in the bottom preview strip,
/// this page is pushed as a full-screen dialog. It first shows the low-res
/// [thumbnail] (if available) while loading the full-resolution file from
/// disk, then swaps to the high-res version once ready.
///
/// Supports pinch-to-zoom via [InteractiveViewer].
class FullscreenPreviewPage extends StatefulWidget {
  /// The asset to display in full resolution.
  final AssetEntity asset;

  /// An optional low-res thumbnail to display while the full file loads.
  final Uint8List? thumbnail;

  /// Creates a [FullscreenPreviewPage] for the given [asset].
  const FullscreenPreviewPage({
    super.key,
    required this.asset,
    this.thumbnail,
  });

  @override
  State<FullscreenPreviewPage> createState() => _FullscreenPreviewPageState();
}

class _FullscreenPreviewPageState extends State<FullscreenPreviewPage> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    // We only need a fast standard file for on-screen preview, not the pristine origin.
    final file = await widget.asset.file;
    if (mounted) {
      setState(() => _file = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: _file != null
            ? InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.file(_file!, fit: BoxFit.contain),
              )
            : widget.thumbnail != null
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.memory(widget.thumbnail!, fit: BoxFit.contain),
                  )
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
