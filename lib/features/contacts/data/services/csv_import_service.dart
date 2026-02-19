import 'dart:developer' as developer;

import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../models/contact_model.dart';

/// Result returned after a CSV import attempt.
class CsvImportResult {
  final List<ContactModel> contacts;
  final List<String> errors;
  final int totalRows;

  const CsvImportResult({
    required this.contacts,
    required this.errors,
    required this.totalRows,
  });

  int get successCount => contacts.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
}

/// Service responsible for parsing CSV files into [ContactModel] instances.
///
/// Expected CSV columns (case-insensitive, order flexible):
///   fullname / name, phone, email, street, city, state, zip,
///   dnc / dncstatus, leadsource / source, folder / foldertag
class CsvImportService {
  final Uuid _uuid;

  CsvImportService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Parses [csvContent] and returns an import result.
  CsvImportResult parse(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return const CsvImportResult(
        contacts: [],
        errors: ['CSV content is empty.'],
        totalRows: 0,
      );
    }

    final List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    } catch (e) {
      developer.log('CSV parse error: $e', name: 'CsvImportService');
      return CsvImportResult(
        contacts: const [],
        errors: ['Failed to parse CSV: $e'],
        totalRows: 0,
      );
    }

    if (rows.isEmpty) {
      return const CsvImportResult(
        contacts: [],
        errors: ['CSV has no rows.'],
        totalRows: 0,
      );
    }

    // Build a column-name → index map from the header row.
    final headerRow =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final columnIndex = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      columnIndex[headerRow[i]] = i;
    }

    final contacts = <ContactModel>[];
    final errors = <String>[];
    final dataRows = rows.skip(1).toList();

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNumber = i + 2; // 1-based, accounting for header

      try {
        final String? fullName = _getField(
          row,
          columnIndex,
          ['fullname', 'name', 'full name', 'full_name'],
        );

        if (fullName == null || fullName.trim().isEmpty) {
          errors.add('Row $rowNumber: Missing required field "name". Skipped.');
          continue;
        }

        final String phone =
            _getField(row, columnIndex, ['phone', 'phonenumber', 'phone_number']) ?? '';
        final String email =
            _getField(row, columnIndex, ['email', 'emailaddress', 'email_address']) ?? '';
        final String street =
            _getField(row, columnIndex, ['street', 'address', 'streetaddress']) ?? '';
        final String city =
            _getField(row, columnIndex, ['city']) ?? '';
        final String state =
            _getField(row, columnIndex, ['state', 'st']) ?? '';
        final String zip =
            _getField(row, columnIndex, ['zip', 'zipcode', 'zip_code', 'postal']) ?? '';
        final String leadSource =
            _getField(row, columnIndex, ['leadsource', 'lead_source', 'source']) ??
                'CSV';

        final String? dncRaw =
            _getField(row, columnIndex, ['dnc', 'dncstatus', 'dnc_status', 'do not call']);
        final bool dncStatus = _parseBool(dncRaw);

        final String? folderRaw =
            _getField(row, columnIndex, ['folder', 'foldertag', 'folder_tag', 'bucket']);
        final FolderTag folderTag =
            folderRaw != null ? FolderTag.fromString(folderRaw) : FolderTag.active;

        final String? lastContactRaw = _getField(
          row,
          columnIndex,
          ['lastcontact', 'last_contact', 'lastcontactdate', 'last_contact_date'],
        );
        final DateTime? lastContactDate =
            lastContactRaw != null ? _parseDate(lastContactRaw) : null;

        contacts.add(
          ContactModel(
            id: _uuid.v4(),
            fullName: fullName.trim(),
            phone: phone.trim(),
            email: email.trim(),
            dncStatus: dncStatus,
            leadSource: leadSource.trim(),
            address: ContactAddress(
              street: street.trim(),
              city: city.trim(),
              state: state.trim(),
              zip: zip.trim(),
            ),
            folderTag: folderTag,
            lastContactDate: lastContactDate,
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        developer.log('Row $rowNumber error: $e', name: 'CsvImportService');
        errors.add('Row $rowNumber: Unexpected error – $e');
      }
    }

    return CsvImportResult(
      contacts: contacts,
      errors: errors,
      totalRows: dataRows.length,
    );
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String? _getField(
    List<dynamic> row,
    Map<String, int> index,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      final i = index[alias];
      if (i != null && i < row.length) {
        final value = row[i].toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  bool _parseBool(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase().trim();
    return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'y';
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    // Try ISO 8601 first.
    final iso = DateTime.tryParse(value.trim());
    if (iso != null) return iso;
    // Try common US format MM/DD/YYYY.
    final parts = value.trim().split('/');
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}
