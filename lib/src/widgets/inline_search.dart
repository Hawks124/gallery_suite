import 'package:flutter/material.dart';

import '../../gallery_suite.dart';

class InlineSearchBar extends StatelessWidget {
  final PickerTheme theme;
  final String hintText;
  final String searchQuery;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  const InlineSearchBar({
    super.key,
    required this.theme,
    required this.hintText,
    required this.searchQuery,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onChanged,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: theme.background, // Contrast against surface
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: searchCtrl,
          focusNode: searchFocus,
          style: TextStyle(color: theme.primaryText, fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                TextStyle(color: theme.secondaryText.withValues(alpha: 0.5)),
            prefixIcon: Icon(searchQuery.isNotEmpty ? null : Icons.search,
                color: theme.secondaryText, size: 20),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel,
                        color: theme.secondaryText, size: 16),
                    onPressed: onCancel,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.elevated),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 9.5),
          ),
        ),
      ),
    );
  }
}
