import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../providers/contacts_provider.dart';
import '../screens/contact_detail_screen.dart';
import 'folder_badge.dart';

/// Responsive data grid displaying contacts in a table with hover effects,
/// rounded corners, custom icons, Zillow links, and batch selection.
class ContactGrid extends StatelessWidget {
  const ContactGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 48),
                const SizedBox(height: 12),
                Text(provider.errorMessage!,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (provider.contacts.isEmpty) {
          return const _EmptyState();
        }

        return _ContactTable(
          contacts: provider.contacts,
          selectedIds: provider.selectedIds,
          onToggleSelect: provider.toggleSelection,
          onMoveToFolder: (id, folder) =>
              provider.moveToFolder(id, folder),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.addressBook,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import a CSV file or add contacts manually.',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ContactTable extends StatelessWidget {
  final List<ContactModel> contacts;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelect;
  final void Function(String id, FolderTag folder) onMoveToFolder;

  const _ContactTable({
    required this.contacts,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onMoveToFolder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: true,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            headingRowHeight: 48,
            columnSpacing: 20,
            horizontalMargin: 16,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            headingTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            dataTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            columns: const [
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('PHONE')),
              DataColumn(label: Text('CITY')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('FOLDER')),
              DataColumn(label: Text('SOURCE')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: contacts.map((c) => _buildRow(context, c)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ContactModel c) {
    return DataRow(
      selected: selectedIds.contains(c.id),
      onSelectChanged: (_) => onToggleSelect(c.id),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.glassWhite.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
      cells: [
        // Name
        DataCell(
          InkWell(
            onTap: () => _openDetail(context, c),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    c.fullName.isNotEmpty
                        ? c.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  c.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (c.dncStatus) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Do Not Call',
                    child: Icon(Icons.block,
                        size: 14, color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Phone
        DataCell(Text(c.phone.isEmpty ? '—' : c.phone)),
        // City
        DataCell(Text(c.address.city.isEmpty ? '—' : c.address.city)),
        // DNC status indicator
        DataCell(
          c.dncStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'DNC',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
        ),
        // Folder badge
        DataCell(FolderBadge(tag: c.folderTag)),
        // Lead source
        DataCell(Text(
          c.leadSource.isEmpty ? '—' : c.leadSource,
          style: const TextStyle(color: AppColors.textSecondary),
        )),
        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.address.hasAddress)
                Tooltip(
                  message: 'View on Zillow',
                  child: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.houseChimney,
                        size: 14, color: AppColors.accent),
                    onPressed: () => _openZillow(context, c),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              _FolderMoveButton(
                contactId: c.id,
                current: c.folderTag,
                onMove: onMoveToFolder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, ContactModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(contact: c),
      ),
    );
  }

  Future<void> _openZillow(BuildContext context, ContactModel c) async {
    final query = c.address.zillowQueryString;
    final uri = Uri.parse(
        'https://www.zillow.com/homes/${query}_rb/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Zillow link.')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _FolderMoveButton extends StatelessWidget {
  final String contactId;
  final FolderTag current;
  final void Function(String id, FolderTag folder) onMove;

  const _FolderMoveButton({
    required this.contactId,
    required this.current,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FolderTag>(
      tooltip: 'Move to folder',
      icon: const Icon(Icons.folder_open_outlined,
          size: 16, color: AppColors.textSecondary),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => FolderTag.values
          .where((f) => f != current)
          .map(
            (f) => PopupMenuItem<FolderTag>(
              value: f,
              child: Text(
                f.displayName,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onSelected: (folder) => onMove(contactId, folder),
    );
  }
}
