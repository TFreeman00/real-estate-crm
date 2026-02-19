import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/models/contact_model.dart';
import '../providers/contacts_provider.dart';
import '../widgets/folder_badge.dart';
import 'contact_form_screen.dart';
import '../../../activity_log/presentation/screens/activity_log_screen.dart';

/// Full-detail view for a single contact.
class ContactDetailScreen extends StatelessWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    // Refresh from provider in case the contact was updated.
    final provider = context.watch<ContactsProvider>();
    final fresh = provider.allContacts.where((c) => c.id == contact.id);
    final c = fresh.isNotEmpty ? fresh.first : contact;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _BackgroundGradient(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _AppBar(contact: c),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _IdentityCard(contact: c),
                      const SizedBox(height: 16),
                      _AddressCard(contact: c),
                      const SizedBox(height: 16),
                      _MetaCard(contact: c),
                      const SizedBox(height: 16),
                      _ActionRow(contact: c),
                      const SizedBox(height: 16),
                        ]),
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

// ---------------------------------------------------------------------------

class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.6, -0.5),
          radius: 1.0,
          colors: [Color(0xFF1A3A5E), Color(0xFF0A0E1A)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  final ContactModel contact;
  const _AppBar({required this.contact});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 14),
        title: Text(
          contact.fullName,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
          tooltip: 'Edit contact',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ContactFormScreen(existingContact: contact),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          tooltip: 'Delete contact',
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Contact',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete ${contact.fullName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ContactsProvider>().deleteContact(contact.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ---------------------------------------------------------------------------

class _IdentityCard extends StatelessWidget {
  final ContactModel contact;
  const _IdentityCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  contact.fullName.isNotEmpty
                      ? contact.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.fullName,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    FolderBadge(tag: contact.folderTag),
                    if (contact.dncStatus) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.block,
                              size: 12, color: AppColors.danger),
                          SizedBox(width: 4),
                          Text('Do Not Call',
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: contact.phone.isEmpty ? '—' : contact.phone),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: contact.email.isEmpty ? '—' : contact.email),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddressCard extends StatelessWidget {
  final ContactModel contact;
  const _AddressCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final addr = contact.address;
    final hasAddress = addr.hasAddress;

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.locationDot,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('Address',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const Spacer(),
              if (hasAddress)
                TextButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.houseChimney,
                      size: 12, color: AppColors.accent),
                  label: const Text('Zillow',
                      style: TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                  onPressed: () => _openZillow(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasAddress)
            Text(
              [addr.street, addr.city, addr.state, addr.zip]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
            )
          else
            const Text('No address on file.',
                style: TextStyle(
                    color: AppColors.textDisabled, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _openZillow(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.zillow.com/homes/${contact.address.zillowQueryString}_rb/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Zillow.')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _MetaCard extends StatelessWidget {
  final ContactModel contact;
  const _MetaCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
              icon: Icons.source_outlined,
              label: 'Lead Source',
              value: contact.leadSource.isEmpty ? '—' : contact.leadSource),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Last Contact',
              value: contact.lastContactDate != null
                  ? _formatDate(contact.lastContactDate!)
                  : '—'),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.add_circle_outline,
              label: 'Created',
              value: _formatDate(contact.createdAt)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  final ContactModel contact;
  const _ActionRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.folder_open_outlined,
            label: 'Move to Folder',
            onTap: () => _showFolderPicker(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.history_outlined,
            label: 'Activity Log',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ActivityLogScreen(contact: contact),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFolderPicker(BuildContext context) async {
    final folder = await showDialog<FolderTag>(
      context: context,
      builder: (_) => _FolderPickerDialog(current: contact.folderTag),
    );
    if (folder != null && context.mounted) {
      await context
          .read<ContactsProvider>()
          .moveToFolder(contact.id, folder);
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FolderPickerDialog extends StatelessWidget {
  final FolderTag current;
  const _FolderPickerDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Move to Folder',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: FolderTag.values
            .map(
              (tag) => ListTile(
                leading: Icon(
                  tag == current
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: tag == current
                      ? AppColors.primary
                      : AppColors.textDisabled,
                  size: 18,
                ),
                title: Text(
                  tag.displayName,
                  style: TextStyle(
                    color: tag == current
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: tag == current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.pop(context, tag),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
