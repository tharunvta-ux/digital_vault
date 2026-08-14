import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_type.dart';

/// Maps between a Supabase/PostgREST row (snake_case columns, `date`/`time`
/// stored as two separate columns) and the domain [Reminder] (one combined
/// [DateTime]). The only file in this feature that knows the `reminders`
/// table's column names.
class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.ownerUid,
    required super.documentId,
    required super.title,
    super.description,
    required super.scheduledAt,
    required super.repeatType,
    required super.notificationEnabled,
    required super.completed,
    required super.createdAt,
    required super.updatedAt,
  });

  /// [data] is a raw row as returned by PostgREST -- always a plain
  /// `Map<String, dynamic>`.
  factory ReminderModel.fromMap(Map<String, dynamic> data) {
    final date = DateTime.parse(data['reminder_date'] as String);
    final timeParts = (data['reminder_time'] as String).split(':');
    return ReminderModel(
      id: data['id'] as String,
      ownerUid: data['owner_uid'] as String,
      documentId: data['document_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      scheduledAt: DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      ),
      // Defensive fallback to `once`: if a repeat type is ever renamed or
      // removed, an older stored value doesn't crash the app on read --
      // same reasoning as VaultDocumentModel's category fallback.
      repeatType: RepeatType.values.firstWhere(
        (candidate) => candidate.name == data['repeat_type'],
        orElse: () => RepeatType.once,
      ),
      notificationEnabled: data['notification_enabled'] as bool,
      completed: data['completed'] as bool,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Builds the row for a new reminder. A static method taking loose values
  /// rather than an instance method on an already-built [ReminderModel]
  /// (contrast `VaultDocumentModel.toMap`) because there's no real entity
  /// to build yet: `id`/`created_at`/`updated_at` are all server-generated
  /// on insert (unlike `vault_documents`, whose `id` is minted client-side
  /// because the Storage path needs it before the row exists), so
  /// constructing one first would mean inventing placeholder values for
  /// fields that don't have real ones yet.
  static Map<String, dynamic> buildInsertMap({
    required String ownerUid,
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return {
      'owner_uid': ownerUid,
      'document_id': documentId,
      'title': title,
      'description': description,
      'reminder_date': _formatDate(scheduledAt),
      'reminder_time': _formatTime(scheduledAt),
      'repeat_type': repeatType.name,
      'notification_enabled': notificationEnabled,
      'completed': false,
    };
  }

  /// Builds the row for an editing update -- everything [buildInsertMap]
  /// covers except `document_id` and `completed`, neither of which this
  /// kind of update (the edit screen) is allowed to change.
  static Map<String, dynamic> buildUpdateMap({
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return {
      'title': title,
      'description': description,
      'reminder_date': _formatDate(scheduledAt),
      'reminder_time': _formatTime(scheduledAt),
      'repeat_type': repeatType.name,
      'notification_enabled': notificationEnabled,
    };
  }

  static String _formatDate(DateTime dateTime) {
    String pad(int n, int width) => n.toString().padLeft(width, '0');
    return '${pad(dateTime.year, 4)}-${pad(dateTime.month, 2)}-${pad(dateTime.day, 2)}';
  }

  static String _formatTime(DateTime dateTime) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dateTime.hour)}:${pad(dateTime.minute)}:00';
  }
}
