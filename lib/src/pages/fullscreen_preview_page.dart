import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../gallery_suite.dart';

// A full-screen, zoomable preview page for a single media asset (Images only).
// Videos are handled by VideoPreviewSheet.
class FullscreenPreviewPage extends StatefulWidget {
  // The asset to display in full resolution.
  final PickerAsset asset;

  // The visual theme and optional authenticated service.
  final PickerTheme theme;
  final GooglePhotosService? googleService;

  // An optional low-res thumbnail to display while the full file loads.
  final Uint8List? thumbnail;

  // An optional already-edited file to display instead of the original asset.
  final File? editedFile;

  // Async edit callback. Returns the edited [File] or null if cancelled.
  final Future<File?> Function()? onEdit;

  const FullscreenPreviewPage({
    super.key,
    required this.asset,
    required this.theme,
    this.googleService,
    this.thumbnail,
    this.editedFile,
    this.onEdit,
  });

  @override
  State<FullscreenPreviewPage> createState() => _FullscreenPreviewPageState();
}

class _FullscreenPreviewPageState extends State<FullscreenPreviewPage> {
  File? _file;
  File? _localEditedFile;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _localEditedFile = widget.editedFile;
    _loadFile();
  }

  Future<void> _loadFile() async {
    final asset = widget.asset;
    if (asset is LocalPickerAsset) {
      final file = await asset.file;
      if (mounted) {
        setState(() => _file = file);
      }
    } else if (asset is FilePickerAsset) {
      try {
        if (!kIsWeb) {
          final file = File(asset.filePath);
          if (file.existsSync() && mounted) {
            setState(() => _file = file);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _onEditTapped() async {
    if (_isEditing) return;
    setState(() => _isEditing = true);

    try {
      final result = await widget.onEdit!();
      if (mounted && result != null) {
        setState(() => _localEditedFile = result);
      }
    } catch (e) {
      debugPrint('FullscreenPreview edit error: $e');
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayFile = _localEditedFile ?? _file;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.onEdit != null)
            _isEditing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: _onEditTapped,
                  ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: displayFile != null
            ? InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: 'preview_${widget.asset.id}',
                  child: Image.file(
                    displayFile,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              )
            : (widget.asset is RemotePickerAsset)
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'preview_${widget.asset.id}',
                      child: AuthImage(
                        imageUrl: (widget.asset as RemotePickerAsset).fullUrl,
                        googleService: widget.googleService,
                        theme: widget.theme,
                        headers: (widget.asset as RemotePickerAsset).headers,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : widget.thumbnail != null
                    ? InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Hero(
                          tag: 'preview_${widget.asset.id}',
                          child: Image.memory(widget.thumbnail!,
                              fit: BoxFit.contain),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
