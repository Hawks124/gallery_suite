/// Abstract delegate class to localize all UI strings in the media picker.
///
/// Simply extend or implement this class and pass it to `PickerConfig.textDelegate`
/// to completely translate the package without the need for `intl` or ARB files.
abstract class PickerTextDelegate {
  final String confirm;
  final String cancel;

  final String recent;
  final String albums;
  final String audio;
  final String camera;

  final String searchPlaceholder;
  final String searchNoResults;

  final String noMediaFound;

  // ── Google Photos Cloud ─────────────────────────────────────────────────
  final String googlePhotos;
  final String googlePhotosConnectTitle;
  final String googlePhotosConnectTitleHighlight;
  final String googlePhotosConnectSubtitle;
  final String googlePhotosConnectButton;
  final String googlePhotosDisconnect;

  // ── Picker API Empty State ───────────────────────────────────────────────
  final String googlePhotosEmptyStateTitle;
  final String googlePhotosEmptyStateSubtitle;
  final String googlePhotosImportButton;

  const PickerTextDelegate({
    required this.confirm,
    required this.cancel,
    required this.recent,
    required this.albums,
    required this.audio,
    required this.camera,
    required this.searchPlaceholder,
    required this.searchNoResults,
    required this.noMediaFound,
    required this.googlePhotos,
    required this.googlePhotosConnectTitle,
    required this.googlePhotosConnectTitleHighlight,
    required this.googlePhotosConnectSubtitle,
    required this.googlePhotosConnectButton,
    required this.googlePhotosDisconnect,
    required this.googlePhotosEmptyStateTitle,
    required this.googlePhotosEmptyStateSubtitle,
    required this.googlePhotosImportButton,
  });
}
