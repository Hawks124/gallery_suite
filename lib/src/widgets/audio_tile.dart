import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/picker_theme.dart';
import '../models/picker_asset.dart';
import '../sources/media_source_factory.dart';

class AudioTile extends StatefulWidget {
  final PickerAsset asset;
  final bool isPlaying;
  final bool isCurrentTrack;
  final bool isSelected;
  final Color primaryColor;
  final PickerTheme theme;
  final VoidCallback onPlay;
  final VoidCallback onSelect;

  const AudioTile({
    super.key,
    required this.asset,
    required this.isPlaying,
    required this.isCurrentTrack,
    required this.isSelected,
    required this.primaryColor,
    required this.theme,
    required this.onPlay,
    required this.onSelect,
  });

  @override
  State<AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<AudioTile>
    with SingleTickerProviderStateMixin {
  Uint8List? _thumb;
  late AnimationController _barsCtrl;

  @override
  void initState() {
    super.initState();
    _barsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadThumb();
  }

  @override
  void didUpdateWidget(AudioTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _barsCtrl.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _barsCtrl.stop();
    }
  }

  @override
  void dispose() {
    _barsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThumb() async {
    final data =
        await MediaSourceFactory.activeSource.getThumbnail(widget.asset);
    if (mounted) setState(() => _thumb = data);
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(
            RegExp(r'\.(mp3|wav|aac|flac|ogg|m4a|opus)$', caseSensitive: false),
            '')
        .trim();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final title = _cleanTitle(widget.asset.title ?? 'Audio');
    final duration = widget.asset.duration;

    return GestureDetector(
      onTap: widget.onPlay,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: widget.isCurrentTrack
            ? widget.primaryColor.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumbnail / album art
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _thumb != null
                      ? Image.memory(
                          _thumb!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.theme.elevated,
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: widget.theme.secondaryText,
                            size: 26,
                          ),
                        ),
                ),
                if (widget.isCurrentTrack)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isCurrentTrack
                          ? widget.primaryColor
                          : widget.theme.primaryText,
                      fontSize: 14,
                      fontWeight: widget.isCurrentTrack
                          ? FontWeight.w600
                          : FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmt(duration),
                    style: TextStyle(
                        color: widget.theme.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection circle
            GestureDetector(
              onTap: widget.onSelect,
              behavior: HitTestBehavior.opaque,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale:
                      CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  child: child,
                ),
                child: widget.isSelected
                    ? Container(
                        key: const ValueKey('sel'),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 15),
                      )
                    : Container(
                        key: const ValueKey('unsel'),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.theme.separator,
                            width: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
