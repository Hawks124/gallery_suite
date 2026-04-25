// French translation delegate for the media picker.

import 'picker_text_delegate.dart';

// French translations out-of-the-box, perfect for the IRA app ecosystem.
class FrenchPickerTextDelegate extends PickerTextDelegate {
  const FrenchPickerTextDelegate({
    super.confirm = 'Sélectionner',
    super.cancel = 'Annuler',
    super.recent = 'Récents',
    super.albums = 'Albums',
    super.audio = 'Audio',
    super.imagesLabel = 'Photos',
    super.videosLabel = 'Vidéos',
    super.camera = 'Appareil photo',
    super.searchPlaceholder = 'Rechercher...',
    super.searchNoResults = 'Aucun résultat pour',
    super.noMediaFound = 'Aucun média trouvé.',
    super.videoPreviewTitle = 'Aperçu Vidéo',
    super.videoErrorDescription = 'Impossible de lire cette vidéo.',
    super.videoSelectButton = 'Sélectionner cette vidéo',
    super.videoUntitled = 'Sans titre',
    super.googlePhotos = 'Google Photos',
    super.googlePhotosConnectTitle = 'Consultez, Choisissez, Cloud.',
    super.googlePhotosConnectTitleHighlight = 'Connectez-vous pour y accéder !',
    super.googlePhotosConnectSubtitle =
        'Connectez-vous avec votre compte Google pour parcourir et sélectionner librement vos photos stockées dans le cloud directement depuis cette application.',
    super.googlePhotosConnectButton = 'Se connecter à Google',
    super.googlePhotosDisconnect = 'Se déconnecter',
    super.googlePhotosDisconnectConfirmationTitle =
        'Se déconnecter de Google Photos ?',
    super.googlePhotosDisconnectConfirmationSubtitle =
        'Vos photos cloud importées ne seront plus visibles jusqu\'à ce que vous vous reconnectiez.',
    super.googlePhotosErrorSession =
        'Impossible de créer la session Google Photos',
    super.googlePhotosEmptyStateTitle =
        'Votre bibliothèque est protégée ou vide',
    super.googlePhotosEmptyStateSubtitle =
        'En raison des nouvelles règles de Google (2025), vous devez sélectionner manuellement les photos à importer.',
    super.googlePhotosImportButton = 'Importer de Google Photos',
    super.googlePhotosDeleteButton = 'Supprimer',
    super.permissionDeniedTitle = 'Accès restreint',
    super.permissionDeniedSubtitle =
        'Autorisez l\'accès dans les réglages pour continuer à parcourir vos médias locaux.',
    super.permissionDeniedButton = 'Ouvrir les réglages',
    super.clipboard = 'Presse-papier',
    super.clipboardSubtitle = 'Coller depuis le presse-papier',
    super.clipboardEmpty = 'Aucun média trouvé dans le presse-papier.',
    super.clipboardLoading = 'Lecture du presse-papier…',
    super.semanticImageUnselected =
        'Photo de la galerie. Appuyez deux fois pour sélectionner.',
    super.semanticImageSelectedFormat = 'Photo sélectionnée, numéro %d.',
    super.semanticVideoFormat = 'Vidéo de la galerie, durée %s.',
    super.semanticPreviewAction = 'Ouvrir l\'aperçu',
  });
}
