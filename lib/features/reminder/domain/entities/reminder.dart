import 'repeat_type.dart';

/// Domain representation of a single reminder.
///
/// Mirrors the columns the `reminders` Postgres table stores, but is
/// deliberately free of any Supabase types -- only the data layer knows
/// that backend exists. One deliberate normalization: the table stores
/// `reminder_date` and `reminder_time` as two separate columns, but
/// [scheduledAt] combines them into a single [DateTime] here -- the rest of
/// the app (sorting, "is this overdue," notification scheduling) only ever
/// needs one point in time, and splitting it back into a date and a time
/// is the data layer's job (`ReminderModel`), the same way it already
/// converts `vault_documents`' stored timestamp strings into plain
/// [DateTime]s for `VaultDocument`.
class Reminder {
  const Reminder({
    required this.id,
    required this.ownerUid,
    required this.documentId,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.repeatType,
    required this.notificationEnabled,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this reminder (the `reminders` table's `id`
  /// UUID once persisted).
  final String id;

  /// UID of the user who owns this reminder.
  final String ownerUid;

  /// The vault document this reminder is about. Mandatory -- every
  /// reminder belongs to exactly one document (see the schema).
  final String documentId;

  final String title;

  final String? description;

  /// When this reminder is next due, as a local wall-clock date and time
  /// (e.g. "8:00 AM on the 10th") -- not a fixed UTC instant. That's the
  /// correct semantic for a recurring reminder: "daily at 8am" should stay
  /// anchored to 8am local time across a DST change, not drift by an hour.
  final DateTime scheduledAt;

  final RepeatType repeatType;

  /// Whether a local notification should fire for this reminder at all.
  final bool notificationEnabled;

  /// Whether the user has marked this reminder done. Independent of
  /// [repeatType]: a completed one-time reminder stays completed; a
  /// completed recurring reminder is still expected to be reset to
  /// incomplete and rescheduled by whatever creates the next occurrence
  /// (a later phase's concern, not this entity's).
  final bool completed;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  Reminder copyWith({
    String? id,
    String? ownerUid,
    String? documentId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    RepeatType? repeatType,
    bool? notificationEnabled,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeatType: repeatType ?? this.repeatType,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          other.id == id &&
          other.ownerUid == ownerUid &&
          other.documentId == documentId &&
          other.title == title &&
          other.description == description &&
          other.scheduledAt == scheduledAt &&
          other.repeatType == repeatType &&
          other.notificationEnabled == notificationEnabled &&
          other.completed == completed &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        ownerUid,
        documentId,
        title,
        description,
        scheduledAt,
        repeatType,
        notificationEnabled,
        completed,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Reminder(id: $id, title: $title, scheduledAt: $scheduledAt)';
}
