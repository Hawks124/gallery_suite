/// A premium tile displayed in the [AlbumSelectorSheet] to represent
/// the Smart Clipboard source.
///
/// Visually mirrors the [GooglePhotosTile] design pattern: a leading icon,
/// a label + subtitle, and a trailing chevron. The icon uses a clipboard
/// symbol with the picker's [primaryColor] accent.
library;

import 'package:flutter/material.dart';

import '../../gallery_suite.dart';

/// Tile widget for the Smart Clipboard entry in the album selector sheet.
///
/// Placed after Google Photos and before the first local album ("Récents").
class ClipboardTile extends StatelessWidget {
  /// The current picker theme (dark / light tokens).
  final PickerTheme theme;

  /// The picker's accent color, used for the icon and label.
  final Color primaryColor;

  /// The localized label (e.g. "Clipboard" or "Presse-papier").
  final String label;

  /// The localized subtitle (e.g. "Paste from clipboard").
  final String subtitle;

  /// Called when the user taps this tile to enter clipboard mode.
  final VoidCallback onTap;

  const ClipboardTile({
    super.key,
    required this.theme,
    required this.primaryColor,
    required this.label,
    required this.subtitle,
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
              // ── Clipboard icon (matching Google Photos tile proportions) ──
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.content_paste_rounded,
                  color: primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // ── Title + subtitle ─────────────────────────────────────────
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
                      subtitle,
                      style: TextStyle(
                        color: theme.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Trailing chevron ─────────────────────────────────────────
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
