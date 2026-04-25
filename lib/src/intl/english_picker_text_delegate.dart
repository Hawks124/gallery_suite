// English translation delegate for the media picker.

import 'picker_text_delegate.dart';

// English translations mapped directly from the original Custom Media Picker UI.
class EnglishPickerTextDelegate extends PickerTextDelegate {
  const EnglishPickerTextDelegate({
    super.confirm = 'Select',
    super.cancel = 'Cancel',
    super.recent = 'Recent',
    super.albums = 'Albums',
    super.audio = 'Audio',
    super.imagesLabel = 'Photos',
    super.videosLabel = 'Videos',
    super.camera = 'Camera',
    super.searchPlaceholder = 'Search media...',
    super.searchNoResults = 'No results for',
    super.noMediaFound = 'No assets found.',
    super.videoPreviewTitle = 'Video Preview',
    super.videoErrorDescription = 'Failed to play this video.',
    super.videoSelectButton = 'Select this video',
    super.videoUntitled = 'Untitled',
    super.googlePhotos = 'Google Photos',
    super.googlePhotosConnectTitle = 'View, Pick, Cloud.',
    super.googlePhotosConnectTitleHighlight = 'Connect For Seamless Access!',
    super.googlePhotosConnectSubtitle =
        'Log in with your Google account to freely browse and select your photos stored in the cloud directly from this application.',
    super.googlePhotosConnectButton = 'Connect to Google',
    super.googlePhotosDisconnect = 'Sign out',
    super.googlePhotosDisconnectConfirmationTitle =
        'Sign out of Google Photos?',
    super.googlePhotosDisconnectConfirmationSubtitle =
        'Your imported cloud photos will no longer be visible until you sign in again.',
    super.googlePhotosErrorSession = 'Failed to create Google Photos session',
    super.googlePhotosEmptyStateTitle = 'Your library is empty or restricted',
    super.googlePhotosEmptyStateSubtitle =
        'Due to new Google privacy rules (2025), you must manually select which photos you wish to import.',
    super.googlePhotosImportButton = 'Import from Google Photos',
    super.googlePhotosDeleteButton = 'Delete',
    super.permissionDeniedTitle = 'Access restricted',
    super.permissionDeniedSubtitle =
        'Please allow access in settings to continue browsing your local media.',
    super.permissionDeniedButton = 'Open Settings',
    super.clipboard = 'Clipboard',
    super.clipboardSubtitle = 'Paste from clipboard',
    super.clipboardEmpty = 'No media found in clipboard.',
    super.clipboardLoading = 'Reading clipboard…',
    super.semanticImageUnselected = 'Gallery photo. Double tap to select.',
    super.semanticImageSelectedFormat = 'Selected photo, number %d.',
    super.semanticVideoFormat = 'Gallery video, duration %s.',
    super.semanticPreviewAction = 'Preview fullscreen',
  });
}
