import 'picker_text_delegate.dart';

/// English translations mapped directly from the original Custom Media Picker UI.
class EnglishPickerTextDelegate extends PickerTextDelegate {
  const EnglishPickerTextDelegate({
    super.confirm = 'Select',
    super.cancel = 'Cancel',
    super.recent = 'Recent',
    super.albums = 'Albums',
    super.audio = 'Audio',
    super.camera = 'Camera',
    super.searchPlaceholder = 'Search media...',
    super.searchNoResults = 'No results for',
    super.noMediaFound = 'No assets found.',
    super.googlePhotos = 'Google Photos',
    super.googlePhotosConnectTitle = 'Access your cloud memories',
    super.googlePhotosConnectSubtitle =
        'Connect your Google account to browse your cloud photos. Read-only access — we never modify or delete anything.',
    super.googlePhotosConnectButton = 'Connect Google',
    super.googlePhotosDisconnect = 'Disconnect',
  });
}
