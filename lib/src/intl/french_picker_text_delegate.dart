import 'picker_text_delegate.dart';

/// French translations out-of-the-box, perfect for the IRA app ecosystem.
class FrenchPickerTextDelegate extends PickerTextDelegate {
  const FrenchPickerTextDelegate({
    super.confirm = 'Sélectionner',
    super.cancel = 'Annuler',
    super.recent = 'Récents',
    super.albums = 'Albums',
    super.audio = 'Audio',
    super.camera = 'Appareil photo',
    super.searchPlaceholder = 'Rechercher...',
    super.searchNoResults = 'Aucun résultat pour',
    super.noMediaFound = 'Aucun média trouvé.',
    super.googlePhotos = 'Google Photos',
    super.googlePhotosConnectTitle = 'Consultez, Choisissez, Cloud.',
    super.googlePhotosConnectTitleHighlight = 'Connectez-vous pour y accéder !',
    super.googlePhotosConnectSubtitle =
        'Connectez-vous avec votre compte Google pour parcourir et sélectionner librement vos photos stockées dans le cloud directement depuis cette application.',
    super.googlePhotosConnectButton = 'Se connecter à Google',
    super.googlePhotosDisconnect = 'Se déconnecter',
    super.googlePhotosEmptyStateTitle =
        'Votre bibliothèque est protégée ou vide',
    super.googlePhotosEmptyStateSubtitle =
        'En raison des nouvelles règles de Google (2025), vous devez sélectionner manuellement les photos à importer.',
    super.googlePhotosImportButton = 'Importer de Google Photos',
  });
}
