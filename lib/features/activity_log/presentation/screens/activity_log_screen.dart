import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../contacts/data/models/contact_model.dart';
import '../../data/models/activity_entry.dart';
import '../../data/repositories/activity_repository.dart';

/// Displays the activity log (notes, calls, property interests) for a contact
/// and allows adding new entries.
class ActivityLogScreen extends StatefulWidget {
  final ContactModel contact;

  const ActivityLogScreen({super.key, required this.contact});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<ActivityEntry> _entries = [];
  bool _loading = true;
  late final ActivityRepository _repo;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final db = await openAppDatabase();
    _repo = ActivityRepository(dbProvider: () => db);
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _repo.getByContact(widget.contact.id);
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<ActivityEntry>(
      context: context,
      builder: (_) => _AddEntryDialog(contactId: widget.contact.id),
    );
    if (entry != null) {
      await _repo.insert(entry);
      await _loadEntries();
    }
  }

  Future<void> _deleteEntry(String id) async {
    await _repo.delete(id);
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Log'),
            Text(
              widget.contact.fullName,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Add entry',
            onPressed: _addEntry,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _entries.isEmpty
              ? const Center(
                  child: Text(
                    'No activity yet.\nTap + to add a note, call, or property interest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDisabled),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) =>
                      _EntryCard(
                        entry: _entries[i],
                        onDelete: () => _deleteEntry(_entries[i].id),
                      ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: AppColors.primary,
        tooltip: 'Add entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EntryCard extends StatelessWidget {
  final ActivityEntry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  IconData get _icon {
    switch (entry.type) {
      case ActivityType.call:
        return Icons.phone_outlined;
      case ActivityType.email:
        return Icons.email_outlined;
      case ActivityType.propertyInterest:
        return Icons.home_outlined;
      case ActivityType.other:
        return Icons.more_horiz;
      case ActivityType.note:
        return Icons.note_outlined;
    }
  }

  Color get _color {
    switch (entry.type) {
      case ActivityType.call:
        return AppColors.accent;
      case ActivityType.email:
        return AppColors.primary;
      case ActivityType.propertyInterest:
        return AppColors.warning;
      case ActivityType.other:
        return AppColors.textSecondary;
      case ActivityType.note:
        return AppColors.primaryVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _color.withOpacity(0.3)),
              ),
              child: Icon(_icon, size: 16, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.type.displayName,
                        style: TextStyle(
                          color: _color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(entry.createdAt),
                        style: const TextStyle(
                            color: AppColors.textDisabled, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  if (entry.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.body,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.textDisabled),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------

class _AddEntryDialog extends StatefulWidget {
  final String contactId;
  const _AddEntryDialog({required this.contactId});

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  ActivityType _type = ActivityType.note;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Activity',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type selector
            DropdownButtonFormField<ActivityType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category_outlined, size: 16),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              items: ActivityType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title, size: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 3,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              ActivityEntry(
                id: const Uuid().v4(),
                contactId: widget.contactId,
                type: _type,
                title: _titleCtrl.text.trim(),
                body: _bodyCtrl.text.trim(),
                createdAt: DateTime.now(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
