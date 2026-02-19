/// Category of an activity log entry.
enum ActivityType {
  note,
  call,
  email,
  propertyInterest,
  other;

  String get displayName {
    switch (this) {
      case ActivityType.note:
        return 'Note';
      case ActivityType.call:
        return 'Call';
      case ActivityType.email:
        return 'Email';
      case ActivityType.propertyInterest:
        return 'Property Interest';
      case ActivityType.other:
        return 'Other';
    }
  }

  static ActivityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'call':
        return ActivityType.call;
      case 'email':
        return ActivityType.email;
      case 'property_interest':
      case 'propertyinterest':
        return ActivityType.propertyInterest;
      case 'other':
        return ActivityType.other;
      default:
        return ActivityType.note;
    }
  }
}

/// A single entry in a contact's activity log.
class ActivityEntry {
  final String id;
  final String contactId;
  final ActivityType type;
  final String title;
  final String body;
  final DateTime createdAt;

  const ActivityEntry({
    required this.id,
    required this.contactId,
    required this.type,
    required this.title,
    this.body = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as String,
      contactId: map['contactId'] as String,
      type: ActivityType.fromString(map['type'] as String? ?? 'note'),
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ActivityEntry copyWith({
    String? id,
    String? contactId,
    ActivityType? type,
    String? title,
    String? body,
    DateTime? createdAt,
  }) {
    return ActivityEntry(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ActivityEntry(id: $id, contactId: $contactId, type: $type, title: $title)';
}
