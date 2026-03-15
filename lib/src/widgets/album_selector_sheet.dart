import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/picker_theme.dart';
import '../services/media_service.dart';

class AlbumSelectorSheet extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? currentAlbum;
  final Color primaryColor;
  final PickerTheme theme;
  final ScrollController scrollController;
  final MediaService service;
  final void Function(AssetPathEntity) onSelect;

  const AlbumSelectorSheet({
    super.key,
    required this.albums,
    required this.currentAlbum,
    required this.primaryColor,
    required this.theme,
    required this.scrollController,
    required this.service,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: theme.separator,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Albums',
                  style: TextStyle(
                    color: theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, color: theme.divider),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: albums.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 0.5, color: theme.divider, indent: 82),
              itemBuilder: (_, i) {
                final album = albums[i];
                final isCurrent = album.id == currentAlbum?.id;
                return AlbumTile(
                  album: album,
                  isCurrent: isCurrent,
                  primaryColor: primaryColor,
                  theme: theme,
                  service: service,
                  onTap: () => onSelect(album),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

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
