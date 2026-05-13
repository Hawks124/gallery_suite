import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/suite_utils.dart';
import '../intl/picker_text_delegate.dart';
import '../models/picker_theme.dart';

// A placeholder widget displayed when the user taps "   Google Photos" but hasn't authenticated yet.

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
    extends State<GooglePhotosConnectPlaceholder> {
  bool _isSigningIn = false;

  void _handleConnect() {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    // Fire the callback — the parent is responsible for the async flow.
    // We reset loading after a generous timeout to cover edge cases
    // (user cancels browser, error, etc.)
    widget.onConnect();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) setState(() => _isSigningIn = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                // -- Top Illustration --------------------------------------
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Center(
                        child: Image.asset(
                          'assets/images/group-of-happy.png',
                          width: 300,
                          height: 300,
                          package: 'gallery_suite',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/group-of-happy.png',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // -- Bottom Card --------------------------------------------
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.textDelegate.googlePhotosConnectTitle,
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.textDelegate.googlePhotosConnectSubtitle,
                        style: TextStyle(
                          color: widget.theme.secondaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SafeArea(
                        top: false,
                        bottom: false,
                        child: kIsWeb
                            ? Container(
                                constraints:
                                    const BoxConstraints(minHeight: 56),
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: WebUtils.renderWebLoginButton(),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _isSigningIn ? null : _handleConnect,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18),
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.15)
                                              : Colors.grey
                                                  .withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        backgroundColor: Colors.transparent,
                                      ),
                                      child: _isSigningIn
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  widget.theme.secondaryText,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/images/google.png',
                                                  package: 'gallery_suite',
                                                  width: 22,
                                                  height: 22,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      'assets/images/google.png',
                                                      width: 22,
                                                      height: 22,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    widget.textDelegate
                                                        .googlePhotosConnectButton,
                                                    style: TextStyle(
                                                      color: widget
                                                          .theme.primaryText,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: -0.3,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Material(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E1E1E),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap:
                                          _isSigningIn ? null : _handleConnect,
                                      customBorder: const CircleBorder(),
                                      child: SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: _isSigningIn
                                            ? Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                      isDark
                                                          ? Colors.black
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                size: 22,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                      // -- Lock Icon + "Read-only" Badge --------------------
                      SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: widget.theme.secondaryText
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Read-only   OAuth 2.0',
                              style: TextStyle(
                                color: widget.theme.secondaryText
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
