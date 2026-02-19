import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';

/// A small colored badge displaying the [FolderTag] of a contact.
class FolderBadge extends StatelessWidget {
  final FolderTag tag;

  const FolderBadge({super.key, required this.tag});

  Color get _color {
    switch (tag) {
      case FolderTag.active:
        return AppColors.folderActive;
      case FolderTag.followUp:
        return AppColors.folderFollowUp;
      case FolderTag.hotLead:
        return AppColors.folderHotLead;
      case FolderTag.sold:
        return AppColors.folderSold;
      case FolderTag.archived:
        return AppColors.folderArchived;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.18),
        border: Border.all(color: _color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
