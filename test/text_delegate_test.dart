import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_suite/gallery_suite.dart';

void main() {
  group('EnglishPickerTextDelegate', () {
    const delegate = EnglishPickerTextDelegate();

    test('ships the english labels', () {
      expect(delegate.confirm, 'Select');
      expect(delegate.cancel, 'Cancel');
      expect(delegate.googlePhotos, 'Google Photos');
      expect(delegate.sortNewestFirst, 'Newest First');
    });

    test('allows a single word to be overridden', () {
      const overridden = EnglishPickerTextDelegate(confirm: 'Choose');

      expect(overridden.confirm, 'Choose');
      expect(overridden.cancel, 'Cancel');
    });
  });

  group('FrenchPickerTextDelegate', () {
    const delegate = FrenchPickerTextDelegate();

    test('ships the french labels', () {
      expect(delegate.confirm, 'Sélectionner');
      expect(delegate.cancel, 'Annuler');
      expect(delegate.googlePhotos, 'Google Photos');
    });

    test('allows a single word to be overridden', () {
      const overridden = FrenchPickerTextDelegate(confirm: 'Envoyer');

      expect(overridden.confirm, 'Envoyer');
      expect(overridden.cancel, 'Annuler');
    });
  });

  group('Custom delegate', () {
    test('can be implemented from scratch without the intl package', () {
      final delegate = _CustomDelegate();

      expect(delegate.confirm, 'OK');
      expect(delegate.sortLargestFirst, 'Biggest first');
    });
  });
}

/// A delegate implemented from scratch, proving the package does not force
/// any specific translation framework on the consumer.
class _CustomDelegate extends PickerTextDelegate {
  _CustomDelegate()
    : super(
        confirm: 'OK',
        cancel: 'Nope',
        recent: 'Recent',
        albums: 'Albums',
        audio: 'Audio',
        imagesLabel: 'Photos',
        videosLabel: 'Videos',
        camera: 'Camera',
        searchPlaceholder: 'Search',
        searchNoResults: 'Nothing',
        noMediaFound: 'Empty',
        videoPreviewTitle: 'Preview',
        videoErrorDescription: 'Error',
        videoSelectButton: 'Pick',
        videoUntitled: 'Untitled',
        googlePhotos: 'Cloud',
        googlePhotosConnectTitle: 'Connect',
        googlePhotosConnectTitleHighlight: 'Now',
        googlePhotosConnectSubtitle: 'Subtitle',
        googlePhotosConnectButton: 'Connect',
        googlePhotosDisconnect: 'Disconnect',
        googlePhotosDisconnectConfirmationTitle: 'Sure?',
        googlePhotosDisconnectConfirmationSubtitle: 'Subtitle',
        googlePhotosErrorSession: 'Error',
        googlePhotosEmptyStateTitle: 'Empty',
        googlePhotosEmptyStateSubtitle: 'Subtitle',
        googlePhotosImportButton: 'Import',
        googlePhotosDeleteButton: 'Delete',
        permissionDeniedTitle: 'Denied',
        permissionDeniedSubtitle: 'Subtitle',
        permissionDeniedButton: 'Settings',
        clipboard: 'Clipboard',
        clipboardSubtitle: 'Paste from the clipboard',
        clipboardEmpty: 'Nothing found',
        clipboardLoading: 'Reading the clipboard',
        sortMediaTitle: 'Sort',
        sortNewestFirst: 'Newest first',
        sortOldestFirst: 'Oldest first',
        sortLargestFirst: 'Biggest first',
        sortSmallestFirst: 'Smallest first',
        semanticImageUnselected: 'Photo',
        semanticImageSelectedFormat: 'Selected %d',
        semanticVideoFormat: 'Video %s',
        semanticPreviewAction: 'Open the preview',
        cameraActionEdit: 'Edit',
        cameraActionDelete: 'Delete',
        cameraVideoHint: 'Long press to record a video',
      );
}
