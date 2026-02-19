import '../data/models/contact_model.dart';

/// Pure domain filter that can be applied in-memory to a list of contacts.
///
/// All criteria are ANDed together; null/empty values are treated as "no filter".
class ContactFilter {
  final String? nameQuery;
  final String? cityQuery;
  final String? phoneQuery;
  final bool? dncOnly;
  final FolderTag? folder;

  const ContactFilter({
    this.nameQuery,
    this.cityQuery,
    this.phoneQuery,
    this.dncOnly,
    this.folder,
  });

  bool get isEmpty =>
      (nameQuery == null || nameQuery!.isEmpty) &&
      (cityQuery == null || cityQuery!.isEmpty) &&
      (phoneQuery == null || phoneQuery!.isEmpty) &&
      (dncOnly == null || dncOnly == false) &&
      folder == null;

  List<ContactModel> apply(List<ContactModel> contacts) {
    return contacts.where(_matches).toList();
  }

  bool _matches(ContactModel c) {
    if (nameQuery != null && nameQuery!.isNotEmpty) {
      if (!c.fullName.toLowerCase().contains(nameQuery!.toLowerCase())) {
        return false;
      }
    }
    if (cityQuery != null && cityQuery!.isNotEmpty) {
      if (!c.address.city.toLowerCase().contains(cityQuery!.toLowerCase())) {
        return false;
      }
    }
    if (phoneQuery != null && phoneQuery!.isNotEmpty) {
      if (!c.phone.contains(phoneQuery!)) {
        return false;
      }
    }
    if (dncOnly == true && !c.dncStatus) {
      return false;
    }
    if (folder != null && c.folderTag != folder) {
      return false;
    }
    return true;
  }

  ContactFilter copyWith({
    String? nameQuery,
    String? cityQuery,
    String? phoneQuery,
    bool? dncOnly,
    FolderTag? folder,
    bool clearFolder = false,
  }) {
    return ContactFilter(
      nameQuery: nameQuery ?? this.nameQuery,
      cityQuery: cityQuery ?? this.cityQuery,
      phoneQuery: phoneQuery ?? this.phoneQuery,
      dncOnly: dncOnly ?? this.dncOnly,
      folder: clearFolder ? null : (folder ?? this.folder),
    );
  }
}
