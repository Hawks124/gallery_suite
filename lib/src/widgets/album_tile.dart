import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/picker_theme.dart';
import '../services/media_service.dart';

class AlbumTile extends StatefulWidget {
  final AssetPathEntity album;
  final bool isCurrent;
  final Color primaryColor;
  final PickerTheme theme;
  final MediaService service;
  final VoidCallback onTap;

  const AlbumTile({
    super.key,
    required this.album,
    required this.isCurrent,
    required this.primaryColor,
    required this.theme,
    required this.service,
    required this.onTap,
  });

  @override
  State<AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile> {
  Uint8List? _cover;
  int? _count;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.service.getAlbumCoverThumbnail(widget.album),
      widget.album.assetCountAsync,
    ]);
    if (mounted) {
      setState(() {
        _cover = results[0] as Uint8List?;
        _count = results[1] as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _cover != null
                  ? Image.memory(_cover!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      gaplessPlayback: true)
                  : Container(
                      width: 54, height: 54, color: widget.theme.elevated),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name,
                    style: TextStyle(
                      color: widget.isCurrent
                          ? widget.primaryColor
                          : widget.theme.primaryText,
                      fontSize: 15,
                      fontWeight:
                          widget.isCurrent ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (_count != null) ...[
                    const SizedBox(height: 2),
                    Text('$_count',
                        style: TextStyle(
                            color: widget.theme.secondaryText, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (widget.isCurrent)
              Icon(Icons.check_rounded, color: widget.primaryColor, size: 22)
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}
