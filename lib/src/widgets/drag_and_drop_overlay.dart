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
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: widget.theme.surface.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.primaryColor.withValues(alpha: 0.6),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color:
                                    widget.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 72,
                                color: widget.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: widget.theme.primaryText,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Release files to instantly add them to your selection',
                              style: TextStyle(
                                color: widget.theme.secondaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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
