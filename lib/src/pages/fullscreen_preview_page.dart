import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../gallery_suite.dart';

/// A full-screen, zoomable preview page for a single media asset.
///
/// When the user taps a selected thumbnail in the bottom preview strip,
/// this page is pushed as a full-screen dialog. It first shows the low-res
/// [thumbnail] (if available) while loading the full-resolution file from
/// disk, then swaps to the high-res version once ready.
///
/// Supports pinch-to-zoom via [InteractiveViewer].
///
/// If [onEdit] is provided, an edit button is displayed in the AppBar
/// allowing the user to invoke their custom editor (BYOE Architecture).
/// The edit runs in-place — the preview stays open and updates its
/// displayed image when the editor returns a new file.
class FullscreenPreviewPage extends StatefulWidget {
  /// The asset to display in full resolution.
  final PickerAsset asset;

  /// An optional low-res thumbnail to display while the full file loads.
  final Uint8List? thumbnail;

  /// An optional already-edited file to display instead of the original asset.
  final File? editedFile;

  /// Async edit callback. Returns the edited [File] or null if cancelled.
  /// The preview page stays open and updates its display with the result.
  final Future<File?> Function()? onEdit;

  /// Creates a [FullscreenPreviewPage] for the given [asset].
  const FullscreenPreviewPage({
    super.key,
    required this.asset,
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
        // No manual `leading` — fullscreenDialog: true adds the close button.
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
                child: Image.file(
                  displayFile,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              )
            : (widget.asset is RemotePickerAsset)
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: (widget.asset as RemotePickerAsset).fullUrl,
                      httpHeaders: (widget.asset as RemotePickerAsset).headers,
                      fit: BoxFit.contain,
                      progressIndicatorBuilder: (context, url, progress) {
                        if (widget.thumbnail != null) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.memory(
                                widget.thumbnail!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                gaplessPlayback: true,
                              ),
                              CircularProgressIndicator(
                                  value: progress.progress,
                                  color: Colors.white),
                            ],
                          );
                        }
                        return Center(
                          child: CircularProgressIndicator(
                              value: progress.progress, color: Colors.white),
                        );
                      },
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.white54, size: 48),
                      ),
                    ),
                  )
                : widget.thumbnail != null
                    ? InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.memory(widget.thumbnail!,
                            fit: BoxFit.contain),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
