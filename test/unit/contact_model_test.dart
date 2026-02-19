import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_crm/features/contacts/data/models/contact_model.dart';

void main() {
  group('ContactAddress', () {
    test('zillowQueryString encodes all address parts', () {
      const addr = ContactAddress(
        street: '123 Main St',
        city: 'Austin',
        state: 'TX',
        zip: '78701',
      );
      final encoded = addr.zillowQueryString;
      // Should be URL-encoded and contain address parts
      expect(encoded, isNotEmpty);
      expect(encoded, isNot(contains(' ')));
    });

    test('hasAddress returns true when street is present', () {
      const addr = ContactAddress(street: '123 Main St');
      expect(addr.hasAddress, isTrue);
    });

    test('hasAddress returns false when street is empty', () {
      const addr = ContactAddress(city: 'Austin');
      expect(addr.hasAddress, isFalse);
    });

    test('toMap / fromMap round-trip', () {
      const addr = ContactAddress(
          street: '456 Oak Ave', city: 'Dallas', state: 'TX', zip: '75001');
      final map = addr.toMap();
      final restored = ContactAddress.fromMap(map);
      expect(restored, equals(addr));
    });

    test('toJson / fromJson round-trip', () {
      const addr = ContactAddress(
          street: '789 Pine Rd', city: 'Houston', state: 'TX', zip: '77001');
      final json = addr.toJson();
      final restored = ContactAddress.fromJson(json);
      expect(restored, equals(addr));
    });
  });

  group('FolderTag', () {
    test('fromString maps known values correctly', () {
      expect(FolderTag.fromString('follow_up'), FolderTag.followUp);
      expect(FolderTag.fromString('hot_lead'), FolderTag.hotLead);
      expect(FolderTag.fromString('sold'), FolderTag.sold);
      expect(FolderTag.fromString('archived'), FolderTag.archived);
      expect(FolderTag.fromString('active'), FolderTag.active);
      expect(FolderTag.fromString('unknown'), FolderTag.active);
    });

    test('displayName returns human-readable strings', () {
      expect(FolderTag.followUp.displayName, 'Follow-Ups');
      expect(FolderTag.hotLead.displayName, 'Hot Leads');
      expect(FolderTag.sold.displayName, 'Sold');
    });
  });

  group('ContactModel', () {
    ContactModel _makeContact({
      String id = 'test-id',
      FolderTag folder = FolderTag.active,
      bool dnc = false,
      DateTime? lastContact,
    }) {
      return ContactModel(
        id: id,
        fullName: 'John Doe',
        phone: '555-1234',
        email: 'john@example.com',
        dncStatus: dnc,
        leadSource: 'CSV',
        address: const ContactAddress(
            street: '1 Test St', city: 'Austin', state: 'TX', zip: '78701'),
        folderTag: folder,
        lastContactDate: lastContact,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    test('isHotLead returns true for recent hot-lead without DNC', () {
      final c = _makeContact(
        folder: FolderTag.hotLead,
        dnc: false,
        lastContact: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(c.isHotLead, isTrue);
    });

    test('isHotLead returns false when DNC is set', () {
      final c = _makeContact(
        folder: FolderTag.hotLead,
        dnc: true,
        lastContact: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(c.isHotLead, isFalse);
    });

    test('isHotLead returns false when contact is older than 7 days', () {
      final c = _makeContact(
        folder: FolderTag.hotLead,
        lastContact: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(c.isHotLead, isFalse);
    });

    test('isFollowUpOverdue returns true when overdue', () {
      final c = _makeContact(
        folder: FolderTag.followUp,
        lastContact: DateTime.now().subtract(const Duration(days: 20)),
      );
      expect(c.isFollowUpOverdue, isTrue);
    });

    test('isFollowUpOverdue returns false when within 14 days', () {
      final c = _makeContact(
        folder: FolderTag.followUp,
        lastContact: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(c.isFollowUpOverdue, isFalse);
    });

    test('toMap / fromMap round-trip preserves all fields', () {
      final c = _makeContact(
        id: 'abc-123',
        folder: FolderTag.hotLead,
        dnc: true,
        lastContact: DateTime(2024, 6, 15),
      );
      final map = c.toMap();
      final restored = ContactModel.fromMap(map);

      expect(restored.id, equals(c.id));
      expect(restored.fullName, equals(c.fullName));
      expect(restored.phone, equals(c.phone));
      expect(restored.email, equals(c.email));
      expect(restored.dncStatus, equals(c.dncStatus));
      expect(restored.leadSource, equals(c.leadSource));
      expect(restored.address, equals(c.address));
      expect(restored.folderTag, equals(c.folderTag));
      expect(restored.lastContactDate, equals(c.lastContactDate));
      expect(restored.createdAt, equals(c.createdAt));
    });

    test('copyWith only changes specified fields', () {
      final original = _makeContact(id: 'orig');
      final updated = original.copyWith(fullName: 'Jane Doe', dncStatus: true);
      expect(updated.id, equals('orig'));
      expect(updated.fullName, equals('Jane Doe'));
      expect(updated.dncStatus, isTrue);
      expect(updated.phone, equals(original.phone));
    });

    test('equality is based on id', () {
      final a = _makeContact(id: 'same');
      final b = _makeContact(id: 'same');
      final c = _makeContact(id: 'different');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
