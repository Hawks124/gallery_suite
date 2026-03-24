import 'dart:ui';
import 'package:flutter/material.dart';
import '../intl/picker_text_delegate.dart';
import '../models/picker_theme.dart';

/// A beautiful, glassmorphic placeholder widget displayed when the user
/// taps "☁️ Google Photos" but hasn't authenticated yet.
///
/// Features a frosted glass backdrop, an animated cloud icon, and a
/// prominent "Connect Google" button with a security context subtitle.
class GooglePhotosConnectPlaceholder extends StatefulWidget {
  final PickerTheme theme;
  final Color primaryColor;
  final PickerTextDelegate textDelegate;
  final VoidCallback onConnect;

  const GooglePhotosConnectPlaceholder({
    super.key,
    required this.theme,
    required this.primaryColor,
    required this.textDelegate,
    required this.onConnect,
  });

  @override
  State<GooglePhotosConnectPlaceholder> createState() =>
      _GooglePhotosConnectPlaceholderState();
}

class _GooglePhotosConnectPlaceholderState
    extends State<GooglePhotosConnectPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
              decoration: BoxDecoration(
                color: widget.theme.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: widget.theme.separator.withValues(alpha: 0.4),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 40,
                    spreadRadius: -10,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated Cloud Icon ───────────────────────────────
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.primaryColor.withValues(alpha: 0.2),
                            widget.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        size: 44,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    widget.textDelegate.googlePhotosConnectTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.theme.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Subtitle / Privacy Context ────────────────────────
                  Text(
                    widget.textDelegate.googlePhotosConnectSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.theme.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Premium Connect Button ────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            widget.textDelegate.googlePhotosConnectButton,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Lock Icon + "Read-only" Badge ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: widget.theme.secondaryText.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Read-only · OAuth 2.0',
                        style: TextStyle(
                          color:
                              widget.theme.secondaryText.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
