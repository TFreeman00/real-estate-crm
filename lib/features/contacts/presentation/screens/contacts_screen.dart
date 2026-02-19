import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/models/contact_model.dart';
import '../../data/services/csv_import_service.dart';
import '../providers/contacts_provider.dart';
import '../widgets/contact_grid.dart';
import '../widgets/filter_bar.dart';
import 'contact_form_screen.dart';

/// Main contacts management screen showing the toolbar, filter bar, and grid.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final CsvImportService _csvService = CsvImportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().init();
    });
  }

  // --------------------------------------------------------------------------
  // CSV Import
  // --------------------------------------------------------------------------

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final content = String.fromCharCodes(bytes);
    final importResult = _csvService.parse(content);

    if (!mounted) return;

    if (importResult.contacts.isEmpty) {
      _showSnackBar(
        'No valid contacts found in CSV. '
        '${importResult.errors.isNotEmpty ? importResult.errors.first : ''}',
        isError: true,
      );
      return;
    }

    await context.read<ContactsProvider>().importContacts(importResult.contacts);

    if (!mounted) return;

    final msg = 'Imported ${importResult.successCount} contacts'
        '${importResult.hasErrors ? ' (${importResult.errorCount} errors)' : ''}.';
    _showSnackBar(msg);
  }

  // --------------------------------------------------------------------------
  // Batch delete with Undo
  // --------------------------------------------------------------------------

  Future<void> _deleteSelected() async {
    final provider = context.read<ContactsProvider>();
    final ids = provider.selectedIds.toList();
    if (ids.isEmpty) return;

    // Keep a snapshot of contacts for undo.
    final removed = provider.allContacts
        .where((c) => ids.contains(c.id))
        .toList();

    await provider.deleteSelectedContacts();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${removed.length} contact(s).'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () => provider.importContacts(removed),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.danger.withOpacity(0.9) : null,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _BackgroundGradient(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    onImportCsv: _importCsv,
                    onDeleteSelected: _deleteSelected,
                    onAddContact: _openAddContact,
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(12),
                    child: Consumer<ContactsProvider>(
                      builder: (context, provider, _) => FilterBar(
                        currentFilter: provider.filter,
                        onFilterChanged: provider.updateFilter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      child: const ContactGrid(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactFormScreen()),
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
          center: Alignment(-0.6, -0.8),
          radius: 1.2,
          colors: [
            Color(0xFF1A2A5E),
            Color(0xFF0A0E1A),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onImportCsv;
  final VoidCallback onDeleteSelected;
  final VoidCallback onAddContact;

  const _Header({
    required this.onImportCsv,
    required this.onDeleteSelected,
    required this.onAddContact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FaIcon(FontAwesomeIcons.buildingColumns,
            size: 24, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Real Estate CRM',
                style: Theme.of(context).textTheme.headlineLarge),
            const Text('Contact Management',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Consumer<ContactsProvider>(
          builder: (context, provider, _) => Row(
            children: [
              if (provider.hasSelection)
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete (${provider.selectedIds.length})',
                  color: AppColors.danger,
                  onPressed: onDeleteSelected,
                ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.upload_file_outlined,
                label: 'Import CSV',
                color: AppColors.accent,
                onPressed: onImportCsv,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.person_add_outlined,
                label: 'Add Contact',
                color: AppColors.primary,
                onPressed: onAddContact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onPressed,
    );
  }
}
