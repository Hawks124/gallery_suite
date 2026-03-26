import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/picker_theme.dart';

/// An overlay widget that wraps the entire picker screen and listens for
/// files dragged from the native OS (Windows, macOS, Linux, Web).
///
/// Displays a blurred, frosted glass overlay with an "Upload" icon when
/// the user drags files over the application window.
class DragAndDropOverlay extends StatefulWidget {
  final Widget child;
  final PickerTheme theme;
  final Color primaryColor;
  final String label;
  final Function(List<XFile>) onDropped;

  const DragAndDropOverlay({
    super.key,
    required this.child,
    required this.theme,
    required this.primaryColor,
    required this.label,
    required this.onDropped,
  });

  @override
  State<DragAndDropOverlay> createState() => _DragAndDropOverlayState();
}

class _DragAndDropOverlayState extends State<DragAndDropOverlay> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        widget.onDropped(details.files);
      },
      child: Stack(
        children: [
          widget.child,

          // Drag Overlay
          if (_isDragging)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: widget.theme.surface.withValues(alpha: 0.6),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 30),
                        decoration: BoxDecoration(
                          color: widget.theme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.primaryColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              size: 64,
                              color: widget.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: widget.theme.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
