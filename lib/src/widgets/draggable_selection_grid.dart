import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../gallery_suite.dart';

// A wrapper that adds iOS-style "drag to select" (swipe-to-select)
// functionality over a scrollable grid.
//
// It listens for sustained long-press-and-drag gestures, performs hit-testing
// to figure out exactly which [AssetEntity] is under the finger, and invokes
// [onAssetHover] so the parent state can toggle its selection.
//
// It also handles automatic scrolling when dragging near the top or bottom
// edge of the viewport.
class DraggableSelectionGrid extends StatefulWidget {
  // The scrollable child, usually a `MasonryGridView` or `GridView`.
  final Widget child;

  // The scroll controller attached to the [child]. Required for auto-scrambling.
  final ScrollController scrollController;

  // Called repeatedly during a drag sequence when a new [PickerAsset] is hovered.
  final void Function(PickerAsset asset) onAssetHover;

  // Called when the user initiates a drag. Useful to initialize a "batch selection mode".
  final VoidCallback? onDragStart;

  // Called when the drag ends or is canceled.
  final VoidCallback? onDragEnd;

  // Set to false to disable this feature purely logic-side.
  final bool enabled;

  const DraggableSelectionGrid({
    super.key,
    required this.child,
    required this.scrollController,
    required this.onAssetHover,
    this.onDragStart,
    this.onDragEnd,
    this.enabled = true,
  });

  @override
  State<DraggableSelectionGrid> createState() => _DraggableSelectionGridState();
}

class _DraggableSelectionGridState extends State<DraggableSelectionGrid> {
  Timer? _autoScrollTimer;
  double _scrollSpeed = 0.0;
  final Set<String> _processedIdsThisDrag = <String>{};

  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.enabled) return;
    _processedIdsThisDrag.clear();
    widget.onDragStart?.call();
    _processHit(details.globalPosition);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.enabled) return;
    _processHit(details.globalPosition);
    _checkAutoScroll(details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _stopDrag();
  }

  void _onLongPressCancel() {
    _stopDrag();
  }

  void _stopDrag() {
    _stopAutoScroll();
    _processedIdsThisDrag.clear();
    widget.onDragEnd?.call();
  }

  // Processes the [PointerEvent] coordinates through the semantic render tree
  // to find any [MetaData] widget containing an [AssetEntity].
  void _processHit(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final result = BoxHitTestResult();
    final localPosition = renderBox.globalToLocal(globalPosition);

    // Hit test the current layout
    renderBox.hitTest(result, position: localPosition);

    for (final entry in result.path) {
      if (entry.target is RenderMetaData) {
        final renderMetaData = entry.target as RenderMetaData;
        if (renderMetaData.metaData is PickerAsset) {
          final asset = renderMetaData.metaData as PickerAsset;
          if (!_processedIdsThisDrag.contains(asset.id)) {
            _processedIdsThisDrag.add(asset.id);
            widget.onAssetHover(asset);
          }
          break; // Stop climbing the tree if we found the asset
        }
      }
    }
  }

  // Evaluates whether the user's finger is close to the vertical edges
  // of the viewport to trigger programmatic auto-scrolling.
  void _checkAutoScroll(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final Size size = renderBox.size;

    const edgeMargin = 100.0;
    const maxScrollSpeed = 20.0; // pixels per frame

    if (localPosition.dy < edgeMargin) {
      // Near top edge - scroll up
      final intensity = 1.0 - (localPosition.dy / edgeMargin).clamp(0.0, 1.0);
      _scrollSpeed = -maxScrollSpeed * intensity;
      _startAutoScroll();
    } else if (localPosition.dy > size.height - edgeMargin) {
      // Near bottom edge - scroll down
      final intensity =
          1.0 - ((size.height - localPosition.dy) / edgeMargin).clamp(0.0, 1.0);
      _scrollSpeed = maxScrollSpeed * intensity;
      _startAutoScroll();
    } else {
      // Within safe area
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (_autoScrollTimer?.isActive ?? false) return;

    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final ctrl = widget.scrollController;
      if (!ctrl.hasClients) {
        _stopAutoScroll();
        return;
      }

      final newOffset = ctrl.offset + _scrollSpeed;

      if (newOffset <= ctrl.position.minScrollExtent) {
        ctrl.jumpTo(ctrl.position.minScrollExtent);
        _stopAutoScroll();
      } else if (newOffset >= ctrl.position.maxScrollExtent) {
        ctrl.jumpTo(ctrl.position.maxScrollExtent);
        _stopAutoScroll();
      } else {
        ctrl.jumpTo(newOffset);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _scrollSpeed = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: widget.child,
    );
  }
}
