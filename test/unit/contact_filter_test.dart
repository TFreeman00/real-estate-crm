import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_crm/features/contacts/data/models/contact_model.dart';
import 'package:real_estate_crm/features/contacts/domain/contact_filter.dart';

void main() {
  ContactModel _make({
    required String id,
    required String name,
    String phone = '',
    String city = '',
    bool dnc = false,
    FolderTag folder = FolderTag.active,
  }) {
    return ContactModel(
      id: id,
      fullName: name,
      phone: phone,
      dncStatus: dnc,
      address: ContactAddress(city: city),
      folderTag: folder,
      createdAt: DateTime(2024),
    );
  }

  final contacts = [
    _make(id: '1', name: 'Alice Smith', phone: '555-1001', city: 'Austin'),
    _make(
        id: '2',
        name: 'Bob Jones',
        phone: '555-2002',
        city: 'Dallas',
        dnc: true),
    _make(
        id: '3',
        name: 'Carol White',
        phone: '555-3003',
        city: 'Houston',
        folder: FolderTag.hotLead),
    _make(id: '4', name: 'Dave Brown', phone: '555-4004', city: 'Austin',
        folder: FolderTag.followUp),
  ];

  group('ContactFilter', () {
    test('isEmpty returns true for default filter', () {
      expect(const ContactFilter().isEmpty, isTrue);
    });

    test('isEmpty returns false when nameQuery is set', () {
      expect(
        const ContactFilter(nameQuery: 'Alice').isEmpty,
        isFalse,
      );
    });

    test('apply with no criteria returns all contacts', () {
      final result = const ContactFilter().apply(contacts);
      expect(result.length, equals(contacts.length));
    });

    test('filter by name (case-insensitive)', () {
      final result =
          const ContactFilter(nameQuery: 'alice').apply(contacts);
      expect(result.length, equals(1));
      expect(result.first.fullName, equals('Alice Smith'));
    });

    test('filter by city', () {
      final result =
          const ContactFilter(cityQuery: 'Austin').apply(contacts);
      expect(result.map((c) => c.id).toList(), containsAll(['1', '4']));
    });

    test('filter by phone', () {
      final result =
          const ContactFilter(phoneQuery: '555-3003').apply(contacts);
      expect(result.length, equals(1));
      expect(result.first.id, equals('3'));
    });

    test('filter by DNC only', () {
      final result =
          const ContactFilter(dncOnly: true).apply(contacts);
      expect(result.length, equals(1));
      expect(result.first.id, equals('2'));
    });

    test('filter by folder', () {
      final result =
          ContactFilter(folder: FolderTag.hotLead).apply(contacts);
      expect(result.length, equals(1));
      expect(result.first.id, equals('3'));
    });

    test('multiple criteria are ANDed', () {
      // Austin + followUp → only Dave
      final result = ContactFilter(
        cityQuery: 'Austin',
        folder: FolderTag.followUp,
      ).apply(contacts);
      expect(result.length, equals(1));
      expect(result.first.id, equals('4'));
    });

    test('copyWith clears folder when clearFolder=true', () {
      final base = ContactFilter(folder: FolderTag.hotLead);
      final cleared = base.copyWith(clearFolder: true);
      expect(cleared.folder, isNull);
    });

    test('no match returns empty list', () {
      final result =
          const ContactFilter(nameQuery: 'Zzzz').apply(contacts);
      expect(result, isEmpty);
    });
  });
}
