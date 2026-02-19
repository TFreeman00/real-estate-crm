import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../../domain/contact_filter.dart';

/// Central state manager for contacts, filtering, folder management,
/// and action-plan automation.
class ContactsProvider extends ChangeNotifier {
  final ContactRepository _repository;
  final FlutterLocalNotificationsPlugin _notifications;

  List<ContactModel> _allContacts = [];
  List<ContactModel> _filteredContacts = [];
  ContactFilter _filter = const ContactFilter();
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  ContactsProvider({
    required ContactRepository repository,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _repository = repository,
        _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------

  List<ContactModel> get contacts => _filteredContacts;
  List<ContactModel> get allContacts => _allContacts;
  ContactFilter get filter => _filter;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelection => _selectedIds.isNotEmpty;

  // --------------------------------------------------------------------------
  // Initialisation
  // --------------------------------------------------------------------------

  Future<void> init() async {
    await _initNotifications();
    await loadContacts();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _notifications.initialize(initSettings);
  }

  // --------------------------------------------------------------------------
  // Loading
  // --------------------------------------------------------------------------

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allContacts = await _repository.getAll();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Failed to load contacts: $e';
      developer.log(_errorMessage!, name: 'ContactsProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // CRUD
  // --------------------------------------------------------------------------

  Future<void> addContact(ContactModel contact) async {
    await _repository.insert(contact);
    await loadContacts();
  }

  Future<void> updateContact(ContactModel contact) async {
    await _repository.update(contact);
    await loadContacts();
  }

  Future<void> deleteContact(String id) async {
    await _repository.delete(id);
    _selectedIds.remove(id);
    await loadContacts();
  }

  Future<void> deleteSelectedContacts() async {
    if (_selectedIds.isEmpty) return;
    await _repository.deleteAll(_selectedIds.toList());
    _selectedIds.clear();
    await loadContacts();
  }

  Future<void> importContacts(List<ContactModel> contacts) async {
    await _repository.insertAll(contacts);
    await loadContacts();
  }

  // --------------------------------------------------------------------------
  // Selection
  // --------------------------------------------------------------------------

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_filteredContacts.map((c) => c.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Folder management (Buckets)
  // --------------------------------------------------------------------------

  Future<void> moveToFolder(String contactId, FolderTag folder) async {
    final contact = _allContacts.firstWhere(
      (c) => c.id == contactId,
      orElse: () => throw StateError('Contact $contactId not found'),
    );
    final updated = contact.copyWith(folderTag: folder);
    await _repository.update(updated);

    // Action Plan: schedule a follow-up notification when moving to Follow-Ups.
    if (folder == FolderTag.followUp) {
      await _scheduleFollowUpNotification(updated);
    }

    await loadContacts();
  }

  Future<void> moveBatchToFolder(
    Iterable<String> contactIds,
    FolderTag folder,
  ) async {
    for (final id in contactIds) {
      final contact = _allContacts.firstWhere(
        (c) => c.id == id,
        orElse: () => throw StateError('Contact $id not found'),
      );
      final updated = contact.copyWith(folderTag: folder);
      await _repository.update(updated);
      if (folder == FolderTag.followUp) {
        await _scheduleFollowUpNotification(updated);
      }
    }
    await loadContacts();
  }

  // --------------------------------------------------------------------------
  // Filtering
  // --------------------------------------------------------------------------

  void updateFilter(ContactFilter filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  void clearFilter() {
    _filter = const ContactFilter();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredContacts = _filter.isEmpty
        ? List.from(_allContacts)
        : _filter.apply(_allContacts);
  }

  // --------------------------------------------------------------------------
  // Action Plans – Local Notifications
  // --------------------------------------------------------------------------

  Future<void> _scheduleFollowUpNotification(ContactModel contact) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'follow_up_channel',
        'Follow-Up Reminders',
        channelDescription: 'Reminders to follow up with leads.',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Generate a stable integer notification ID from the UUID.
      final notificationId = contact.id.hashCode.abs() % 2147483647;

      await _notifications.show(
        notificationId,
        'Follow-Up Reminder',
        'Don\'t forget to follow up with ${contact.fullName}.',
        details,
      );
    } catch (e) {
      developer.log(
        'Failed to schedule notification for ${contact.id}: $e',
        name: 'ContactsProvider',
      );
    }
  }
}
