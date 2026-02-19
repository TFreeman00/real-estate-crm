import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../../domain/contact_filter.dart';

/// Compact search-and-filter bar that allows filtering contacts by name,
/// city, phone, and DNC status, as well as selecting a folder bucket.
class FilterBar extends StatefulWidget {
  final ContactFilter currentFilter;
  final ValueChanged<ContactFilter> onFilterChanged;

  const FilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.currentFilter.nameQuery ?? '');
    _cityCtrl = TextEditingController(
        text: widget.currentFilter.cityQuery ?? '');
    _phoneCtrl = TextEditingController(
        text: widget.currentFilter.phoneQuery ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _notify({
    String? name,
    String? city,
    String? phone,
    bool? dnc,
    FolderTag? folder,
    bool clearFolder = false,
  }) {
    widget.onFilterChanged(
      widget.currentFilter.copyWith(
        nameQuery: name ?? _nameCtrl.text,
        cityQuery: city ?? _cityCtrl.text,
        phoneQuery: phone ?? _phoneCtrl.text,
        dncOnly: dnc,
        folder: folder,
        clearFolder: clearFolder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.currentFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Text search fields ----
        Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: _nameCtrl,
                label: 'Search name…',
                icon: Icons.person_outline,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SearchField(
                controller: _cityCtrl,
                label: 'Filter by city…',
                icon: Icons.location_city_outlined,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SearchField(
                controller: _phoneCtrl,
                label: 'Filter by phone…',
                icon: Icons.phone_outlined,
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 12),
            // ---- DNC Toggle ----
            _DncToggle(
              value: filter.dncOnly ?? false,
              onChanged: (v) => _notify(dnc: v),
            ),
            const SizedBox(width: 8),
            // ---- Clear filters ----
            if (!filter.isEmpty)
              IconButton(
                tooltip: 'Clear all filters',
                icon: const Icon(Icons.filter_alt_off_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {
                  _nameCtrl.clear();
                  _cityCtrl.clear();
                  _phoneCtrl.clear();
                  widget.onFilterChanged(const ContactFilter());
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        // ---- Folder filter chips ----
        _FolderChips(
          selectedFolder: filter.folder,
          onSelected: (tag) => _notify(
            folder: tag,
            clearFolder: tag == null,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon:
            Icon(icon, size: 16, color: AppColors.textSecondary),
        hintText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _DncToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DncToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? AppColors.danger.withOpacity(0.2)
              : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? AppColors.danger.withOpacity(0.6)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 14,
              color: value ? AppColors.danger : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'DNC',
              style: TextStyle(
                color: value ? AppColors.danger : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderChips extends StatelessWidget {
  final FolderTag? selectedFolder;
  final ValueChanged<FolderTag?> onSelected;

  const _FolderChips({
    required this.selectedFolder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final folders = FolderTag.values;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final tag in folders)
          ChoiceChip(
            label: Text(tag.displayName),
            selected: selectedFolder == tag,
            onSelected: (selected) {
              onSelected(selected ? tag : null);
            },
            selectedColor: _tagColor(tag).withOpacity(0.25),
            labelStyle: TextStyle(
              color: selectedFolder == tag
                  ? _tagColor(tag)
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            side: BorderSide(
              color: selectedFolder == tag
                  ? _tagColor(tag).withOpacity(0.6)
                  : AppColors.glassBorder,
            ),
          ),
      ],
    );
  }

  Color _tagColor(FolderTag tag) {
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
}
