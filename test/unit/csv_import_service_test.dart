import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_crm/features/contacts/data/models/contact_model.dart';
import 'package:real_estate_crm/features/contacts/data/services/csv_import_service.dart';

void main() {
  late CsvImportService service;

  setUp(() {
    service = CsvImportService();
  });

  group('CsvImportService.parse', () {
    test('returns empty result for empty content', () {
      final result = service.parse('');
      expect(result.contacts, isEmpty);
      expect(result.errors, isNotEmpty);
      expect(result.totalRows, equals(0));
    });

    test('parses a well-formed CSV with all fields', () {
      const csv = '''fullname,phone,email,street,city,state,zip,dnc,leadsource,folder,lastcontact
John Doe,555-1234,john@example.com,123 Main St,Austin,TX,78701,false,CSV,active,2024-06-01
Jane Smith,555-5678,jane@example.com,456 Oak Ave,Dallas,TX,75001,true,Web,follow_up,2024-05-15
''';
      final result = service.parse(csv);
      expect(result.totalRows, equals(2));
      expect(result.contacts, hasLength(2));
      expect(result.errors, isEmpty);

      final john = result.contacts.first;
      expect(john.fullName, equals('John Doe'));
      expect(john.phone, equals('555-1234'));
      expect(john.email, equals('john@example.com'));
      expect(john.address.street, equals('123 Main St'));
      expect(john.address.city, equals('Austin'));
      expect(john.address.state, equals('TX'));
      expect(john.address.zip, equals('78701'));
      expect(john.dncStatus, isFalse);
      expect(john.leadSource, equals('CSV'));
      expect(john.folderTag, equals(FolderTag.active));
      expect(john.lastContactDate, equals(DateTime(2024, 6, 1)));

      final jane = result.contacts[1];
      expect(jane.fullName, equals('Jane Smith'));
      expect(jane.dncStatus, isTrue);
      expect(jane.folderTag, equals(FolderTag.followUp));
    });

    test('skips rows with missing name and records error', () {
      const csv = 'fullname,phone\n,555-0000\nBob Builder,555-9999\n';
      final result = service.parse(csv);
      expect(result.contacts, hasLength(1));
      expect(result.contacts.first.fullName, equals('Bob Builder'));
      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('Row 2'));
    });

    test('assigns default leadSource CSV when source column missing', () {
      const csv = 'fullname,phone\nAlice Wonder,555-1111\n';
      final result = service.parse(csv);
      expect(result.contacts.first.leadSource, equals('CSV'));
    });

    test('assigns default folder active when folder column missing', () {
      const csv = 'fullname,city\nBob Lee,Phoenix\n';
      final result = service.parse(csv);
      expect(result.contacts.first.folderTag, equals(FolderTag.active));
    });

    test('parses DNC true/false variants', () {
      const csv = 'fullname,dnc\nYes DNC,yes\nNo DNC,no\nTrue DNC,true\n1 DNC,1\n';
      final result = service.parse(csv);
      expect(result.contacts[0].dncStatus, isTrue);
      expect(result.contacts[1].dncStatus, isFalse);
      expect(result.contacts[2].dncStatus, isTrue);
      expect(result.contacts[3].dncStatus, isTrue);
    });

    test('parses US date format MM/DD/YYYY', () {
      const csv = 'fullname,lastcontact\nDave Jones,06/15/2024\n';
      final result = service.parse(csv);
      expect(result.contacts.first.lastContactDate,
          equals(DateTime(2024, 6, 15)));
    });

    test('assigns unique UUIDs to each contact', () {
      const csv = 'fullname\nAlice\nBob\nCarol\n';
      final result = service.parse(csv);
      final ids = result.contacts.map((c) => c.id).toSet();
      expect(ids.length, equals(result.contacts.length));
    });

    test('handles header with mixed case column names', () {
      const csv = 'FullName,Phone,Email\nTest User,555-0001,test@x.com\n';
      final result = service.parse(csv);
      expect(result.contacts, hasLength(1));
      expect(result.contacts.first.fullName, equals('Test User'));
    });

    test('returns error for totally malformed non-CSV content', () {
      // A string that is technically valid CSV but has no name column.
      const csv = 'foo,bar\n1,2\n';
      final result = service.parse(csv);
      // No "fullname" column → every row skipped.
      expect(result.contacts, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('successCount and errorCount match result', () {
      const csv = 'fullname,phone\nGood Row,555-0001\n,555-0002\n';
      final result = service.parse(csv);
      expect(result.successCount, equals(1));
      expect(result.errorCount, equals(1));
      expect(result.hasErrors, isTrue);
    });
  });
}
