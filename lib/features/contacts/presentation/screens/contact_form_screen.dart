import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/contact_model.dart';
import '../providers/contacts_provider.dart';

/// Form for creating or editing a [ContactModel].
class ContactFormScreen extends StatefulWidget {
  final ContactModel? existingContact;

  const ContactFormScreen({super.key, this.existingContact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _sourceCtrl;
  late bool _dnc;
  late FolderTag _folder;

  bool get _isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingContact;
    _nameCtrl = TextEditingController(text: c?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _streetCtrl = TextEditingController(text: c?.address.street ?? '');
    _cityCtrl = TextEditingController(text: c?.address.city ?? '');
    _stateCtrl = TextEditingController(text: c?.address.state ?? '');
    _zipCtrl = TextEditingController(text: c?.address.zip ?? '');
    _sourceCtrl = TextEditingController(text: c?.leadSource ?? 'Manual');
    _dnc = c?.dncStatus ?? false;
    _folder = c?.folderTag ?? FolderTag.active;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _streetCtrl,
      _cityCtrl,
      _stateCtrl,
      _zipCtrl,
      _sourceCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final contact = ContactModel(
      id: widget.existingContact?.id ?? const Uuid().v4(),
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dncStatus: _dnc,
      leadSource: _sourceCtrl.text.trim(),
      address: ContactAddress(
        street: _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        zip: _zipCtrl.text.trim(),
      ),
      folderTag: _folder,
      lastContactDate: _isEditing
          ? widget.existingContact!.lastContactDate
          : null,
      createdAt: widget.existingContact?.createdAt ?? now,
    );

    final provider = context.read<ContactsProvider>();
    if (_isEditing) {
      await provider.updateContact(contact);
    } else {
      await provider.addContact(contact);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle('Personal Information'),
            _Field(
              controller: _nameCtrl,
              label: 'Full Name *',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _phoneCtrl,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _SectionTitle('Address'),
            _Field(
                controller: _streetCtrl,
                label: 'Street',
                icon: Icons.home_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _Field(
                      controller: _cityCtrl,
                      label: 'City',
                      icon: Icons.location_city_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                      controller: _stateCtrl,
                      label: 'State',
                      icon: Icons.map_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                      controller: _zipCtrl,
                      label: 'ZIP',
                      icon: Icons.local_post_office_outlined,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle('Lead Details'),
            _Field(
              controller: _sourceCtrl,
              label: 'Lead Source',
              icon: Icons.source_outlined,
            ),
            const SizedBox(height: 12),
            // DNC Toggle
            Card(
              child: SwitchListTile(
                value: _dnc,
                onChanged: (v) => setState(() => _dnc = v),
                title: const Text('Do Not Call (DNC)',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text(
                  'Contact has opted out of calls.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                activeColor: AppColors.danger,
                secondary: Icon(
                  Icons.block,
                  color: _dnc ? AppColors.danger : AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Folder selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Folder / Bucket',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: FolderTag.values.map((tag) {
                        final selected = _folder == tag;
                        return ChoiceChip(
                          label: Text(tag.displayName),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _folder = tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
