import 'dart:convert';

/// Represents the folder/bucket a contact belongs to.
enum FolderTag {
  active,
  followUp,
  hotLead,
  sold,
  archived;

  String get displayName {
    switch (this) {
      case FolderTag.active:
        return 'Active';
      case FolderTag.followUp:
        return 'Follow-Ups';
      case FolderTag.hotLead:
        return 'Hot Leads';
      case FolderTag.sold:
        return 'Sold';
      case FolderTag.archived:
        return 'Archived';
    }
  }

  static FolderTag fromString(String value) {
    switch (value.toLowerCase()) {
      case 'follow_up':
      case 'followup':
      case 'follow-ups':
        return FolderTag.followUp;
      case 'hot_lead':
      case 'hotlead':
      case 'hot leads':
        return FolderTag.hotLead;
      case 'sold':
        return FolderTag.sold;
      case 'archived':
        return FolderTag.archived;
      default:
        return FolderTag.active;
    }
  }
}

/// Sub-model representing a contact's address.
class ContactAddress {
  final String street;
  final String city;
  final String state;
  final String zip;

  const ContactAddress({
    this.street = '',
    this.city = '',
    this.state = '',
    this.zip = '',
  });

  /// Returns a URL-ready address string for Zillow deep-links.
  String get zillowQueryString {
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (zip.isNotEmpty) zip,
    ];
    return Uri.encodeComponent(parts.join(' '));
  }

  /// Returns true when at least a street address is present.
  bool get hasAddress => street.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }

  factory ContactAddress.fromMap(Map<String, dynamic> map) {
    return ContactAddress(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zip: map['zip'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ContactAddress.fromJson(String source) =>
      ContactAddress.fromMap(jsonDecode(source) as Map<String, dynamic>);

  ContactAddress copyWith({
    String? street,
    String? city,
    String? state,
    String? zip,
  }) {
    return ContactAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
    );
  }

  @override
  String toString() =>
      'ContactAddress(street: $street, city: $city, state: $state, zip: $zip)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactAddress &&
        other.street == street &&
        other.city == city &&
        other.state == state &&
        other.zip == zip;
  }

  @override
  int get hashCode =>
      street.hashCode ^ city.hashCode ^ state.hashCode ^ zip.hashCode;
}

/// The core domain model for a real-estate CRM contact / lead.
class ContactModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final bool dncStatus;
  final String leadSource;
  final ContactAddress address;
  final FolderTag folderTag;
  final DateTime? lastContactDate;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.fullName,
    this.phone = '',
    this.email = '',
    this.dncStatus = false,
    this.leadSource = '',
    this.address = const ContactAddress(),
    this.folderTag = FolderTag.active,
    this.lastContactDate,
    required this.createdAt,
  });

  /// Returns `true` when the contact qualifies as a "Hot Lead" based on
  /// business rules: folder is hotLead and they have been contacted recently
  /// (within the last 7 days) and are not on the DNC list.
  bool get isHotLead {
    if (dncStatus) return false;
    if (folderTag != FolderTag.hotLead) return false;
    if (lastContactDate == null) return false;
    final daysSince = DateTime.now().difference(lastContactDate!).inDays;
    return daysSince <= 7;
  }

  /// Returns `true` when follow-up is overdue (> 14 days since last contact).
  bool get isFollowUpOverdue {
    if (lastContactDate == null) return false;
    final daysSince = DateTime.now().difference(lastContactDate!).inDays;
    return daysSince > 14 && folderTag == FolderTag.followUp;
  }

  // --------------------------------------------------------------------------
  // Serialisation
  // --------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'dncStatus': dncStatus ? 1 : 0,
      'leadSource': leadSource,
      'address': address.toJson(),
      'folderTag': folderTag.name,
      'lastContactDate': lastContactDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      dncStatus: (map['dncStatus'] as int? ?? 0) == 1,
      leadSource: map['leadSource'] as String? ?? '',
      address: map['address'] != null
          ? ContactAddress.fromJson(map['address'] as String)
          : const ContactAddress(),
      folderTag: FolderTag.fromString(map['folderTag'] as String? ?? 'active'),
      lastContactDate: map['lastContactDate'] != null
          ? DateTime.tryParse(map['lastContactDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ContactModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    bool? dncStatus,
    String? leadSource,
    ContactAddress? address,
    FolderTag? folderTag,
    DateTime? lastContactDate,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dncStatus: dncStatus ?? this.dncStatus,
      leadSource: leadSource ?? this.leadSource,
      address: address ?? this.address,
      folderTag: folderTag ?? this.folderTag,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, fullName: $fullName, phone: $phone, '
        'dncStatus: $dncStatus, folderTag: $folderTag)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
