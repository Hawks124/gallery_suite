import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../gallery_suite.dart';

class PermissionDeniedWidget extends StatelessWidget {
  final PickerTheme theme;
  final String title;
  final String subtitle;
  final String buttonText;

  const PermissionDeniedWidget({
    super.key,
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.background,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/denied.png',
            width: 300,
            height: 300,
            package: 'gallery_suite',
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              color: theme.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: PhotoManager.openSetting,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(
                        color: theme.isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(buttonText)),
              ),
              const SizedBox(width: 16),
              Material(
                color: theme.isDark ? Colors.white : const Color(0xFF1E1E1E),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: PhotoManager.openSetting,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 62,
                    height: 62,
                    child: Icon(
                      Icons.settings_rounded,
                      color: theme.isDark ? Colors.black : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
