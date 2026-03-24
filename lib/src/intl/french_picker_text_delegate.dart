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
    super.googlePhotosConnectTitle = 'Accédez à vos souvenirs cloud',
    super.googlePhotosConnectSubtitle = 'Connectez votre compte Google pour parcourir vos photos cloud. Accès en lecture seule — aucune modification ni suppression.',
    super.googlePhotosConnectButton = 'Connecter Google',
    super.googlePhotosDisconnect = 'Déconnecter',
  });
}
