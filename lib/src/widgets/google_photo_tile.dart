import 'package:flutter/material.dart';

import '../../gallery_suite.dart';

class GooglePhotosTile extends StatelessWidget {
  final PickerTheme theme;
  final Color primaryColor;
  final String label;
  final VoidCallback onTap;

  const GooglePhotosTile({
    super.key,
    required this.theme,
    required this.primaryColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withValues(alpha: 0.1),
        highlightColor: primaryColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Premium Widget-like Cloud Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.2),
                      primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.cloud_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cloud Storage',
                      style: TextStyle(
                        color: theme.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.elevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.secondaryText,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
