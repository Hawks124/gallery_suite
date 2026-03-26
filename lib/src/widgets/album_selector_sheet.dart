import 'package:flutter/material.dart';
import '../../gallery_suite.dart';

class AlbumSelectorSheet extends StatelessWidget {
  final List<AlbumDescriptor> albums;
  final AlbumDescriptor? currentAlbum;
  final Color primaryColor;
  final PickerTheme theme;
  final PickerTextDelegate textDelegate;
  final ScrollController scrollController;
  final MediaSource source;
  final void Function(AlbumDescriptor) onSelect;
  final VoidCallback? onGooglePhotosTap;
  final bool isGooglePhotosConnected;
  final VoidCallback? onGooglePhotosSignOut;

  const AlbumSelectorSheet({
    super.key,
    required this.albums,
    required this.currentAlbum,
    required this.primaryColor,
    required this.theme,
    required this.textDelegate,
    required this.scrollController,
    required this.source,
    required this.onSelect,
    this.onGooglePhotosTap,
    this.isGooglePhotosConnected = false,
    this.onGooglePhotosSignOut,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Text(
                  textDelegate.albums,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),

                // Sign Out
                if (isGooglePhotosConnected &&
                    onGooglePhotosSignOut != null) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onGooglePhotosSignOut,
                    icon: Icon(Icons.logout_rounded,
                        size: 16, color: Colors.white),
                    label: Text(
                      textDelegate.googlePhotosDisconnect,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 0.5, color: theme.divider),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: albums.length + (onGooglePhotosTap != null ? 1 : 0),
              separatorBuilder: (_, __) =>
                  Divider(height: 0.5, color: theme.divider, indent: 82),
              itemBuilder: (_, i) {
                final hasGoogle = onGooglePhotosTap != null;

                // -- Google Photos Cloud Tile (Top item) ------------
                if (hasGoogle && i == 0) {
                  return GooglePhotosTile(
                    theme: theme,
                    primaryColor: primaryColor,
                    label: textDelegate.googlePhotos,
                    onTap: onGooglePhotosTap!,
                  );
                }

                // Shift local albums down by 1 if Google Photos is present
                final albumIndex = hasGoogle ? i - 1 : i;
                final album = albums[albumIndex];
                final isCurrent = album.id == currentAlbum?.id;

                return AlbumTile(
                  album: album,
                  isCurrent: isCurrent,
                  primaryColor: primaryColor,
                  theme: theme,
                  source: source,
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
