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
    super.googlePhotosConnectTitle = 'View, Pick, Cloud.',
    super.googlePhotosConnectTitleHighlight = 'Connect For Seamless Access!',
    super.googlePhotosConnectSubtitle =
        'Log in with your Google account to freely browse and select your photos stored in the cloud directly from this application.',
    super.googlePhotosConnectButton = 'Connect to Google',
    super.googlePhotosDisconnect = 'Sign out',
    super.googlePhotosEmptyStateTitle = 'Your library is empty or restricted',
    super.googlePhotosEmptyStateSubtitle =
        'Due to new Google privacy rules (2025), you must manually select which photos you wish to import.',
    super.googlePhotosImportButton = 'Import from Google Photos',
  });
}
