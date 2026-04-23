import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/google_photos_service.dart';
import '../models/picker_theme.dart';

/// A widget that handles authenticated media loading on Web.
/// On Mobile/Desktop, it falls back to CachedNetworkImage.
class AuthImage extends StatelessWidget {
  final String imageUrl;
  final GooglePhotosService? googleService;
  final PickerTheme theme;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;

  const AuthImage({
    super.key,
    required this.imageUrl,
    this.googleService,
    required this.theme,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || googleService == null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: headers,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => Container(color: theme.elevated),
        errorWidget: (_, __, ___) => Container(
          color: theme.elevated,
          child: Icon(Icons.broken_image_rounded,
              color: theme.secondaryText, size: 28),
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: googleService!.getMediaBytes(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: theme.elevated, width: width, height: height);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
          );
        }

        return Container(
          color: theme.elevated,
          width: width,
          height: height,
          child: Icon(
            Icons.broken_image_rounded,
            color: theme.secondaryText,
            size: 28,
          ),
        );
      },
    );
  }
}
