import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_type.dart';
import '../../domain/notification_exception.dart';
import 'notification_service.dart';

/// `flutter_local_notifications` + `timezone`-backed implementation of
/// [NotificationService].
class LocalNotificationService implements NotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription =
      'Notifications for Smart Vault document reminders.';

  bool _timeZoneInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      if (!_timeZoneInitialized) {
        // Embeds the full IANA database directly (no async file/asset
        // loading needed, unlike package:timezone/standalone.dart, which
        // isn't reliable inside a Flutter app bundle).
        tz_data.initializeTimeZones();
        // flutter_timezone reads the device's real IANA zone name (e.g.
        // "Asia/Kolkata") from the native layer -- neither
        // flutter_local_notifications nor timezone can determine this on
        // their own. Without this, recurring reminders would drift by an
        // hour across DST transitions.
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        _timeZoneInitialized = true;
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      // request*Permission are false here on purpose: permission is
      // requested explicitly via requestPermission(), never silently on
      // first launch as a side effect of initialize().
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );
    } catch (error) {
      throw NotificationException('Could not start the notification service. ${_causeOf(error)}');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final notificationsGranted = await android?.requestNotificationsPermission() ?? false;
        // Exact-alarm access is a separate grant on Android 12+. A denial
        // here doesn't block notifications entirely -- scheduling still
        // succeeds, just falls back to inexact timing -- so it's requested
        // but doesn't gate this method's return value.
        await android?.requestExactAlarmsPermission();
        return notificationsGranted;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final darwin =
            _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwin?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      // Other platforms (desktop/web) either don't gate on permission or
      // aren't targeted by this app's notification support.
      return true;
    } catch (error) {
      throw NotificationException(
        'Could not request notification permission. ${_causeOf(error)}',
      );
    }
  }

  @override
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isSchedulable(reminder)) return;

    try {
      final scheduledDate = tz.TZDateTime.from(reminder.scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        _notificationIdFor(reminder.id),
        reminder.title,
        reminder.description,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: _dateTimeComponentsFor(reminder.repeatType),
        payload: reminder.id,
      );
    } catch (error) {
      throw NotificationException(
        'Could not schedule the reminder notification. ${_causeOf(error)}',
      );
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    // cancel-then-schedule, not an in-place edit: flutter_local_notifications
    // has no "update" primitive, and this also correctly removes the
    // notification outright if the edit turned the reminder into one that
    // shouldn't be scheduled anymore (completed, disabled, moved to the past).
    await cancelReminder(reminder.id);
    await scheduleReminder(reminder);
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    try {
      await _plugin.cancel(_notificationIdFor(reminderId));
    } catch (error) {
      throw NotificationException(
        'Could not cancel the reminder notification. ${_causeOf(error)}',
      );
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (error) {
      throw NotificationException('Could not cancel reminder notifications. ${_causeOf(error)}');
    }
  }

  @override
  Future<void> restoreScheduledReminders(List<Reminder> reminders) async {
    // Clears every previously-scheduled alarm first, then rebuilds from
    // `reminders` -- the source of truth is what's passed in (Supabase's
    // current state), not whatever the device happened to still have
    // scheduled from before the app was last closed.
    try {
      await _plugin.cancelAll();
    } catch (error) {
      throw NotificationException('Could not reset reminder notifications. ${_causeOf(error)}');
    }
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }

  @override
  Future<List<int>> pendingNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((request) => request.id).toList();
    } catch (error) {
      throw NotificationException('Could not read pending notifications. ${_causeOf(error)}');
    }
  }

  bool _isSchedulable(Reminder reminder) {
    if (reminder.completed) return false;
    if (!reminder.notificationEnabled) return false;
    if (reminder.repeatType == RepeatType.once && reminder.scheduledAt.isBefore(DateTime.now())) {
      // A one-time reminder that's already passed has nothing left to
      // schedule. Recurring reminders are exempt from this check:
      // zonedSchedule's own doc comment confirms it finds the next
      // matching future occurrence even when the given date is in the
      // past, so a recurring reminder created (or restored) after its
      // original time has already passed still schedules correctly.
      return false;
    }
    return true;
  }

  /// Maps a repeat type to the plugin's own recurrence primitive.
  /// `DateTimeComponents.time` matches only the time -> daily.
  /// `.dayOfWeekAndTime` also matches the weekday -> weekly.
  /// `.dayOfMonthAndTime` also matches the day of month -> monthly.
  /// `.dateAndTime` matches month, day, and time -> yearly (the only
  /// granularity left once weekday and day-of-month are ruled out).
  /// `null` (no recurrence) for a one-time reminder.
  DateTimeComponents? _dateTimeComponentsFor(RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.once:
        return null;
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatType.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }

  /// FNV-1a 32-bit hash over the reminder's UUID, masked to 31 bits.
  /// Deterministic -- the same string always hashes to the same int, on
  /// any platform, any run -- unlike Dart's own `String.hashCode`, which
  /// the language spec explicitly does not guarantee is stable across runs
  /// or isolates. Always non-negative and within a 32-bit signed int's
  /// range, since that's what Android/iOS notification IDs are natively.
  /// This is what makes "the same reminder always maps to the same
  /// notification ID" true, and is why [updateReminder]/[cancelReminder]
  /// can find and replace/remove the right notification without this
  /// service having to persist an ID-mapping table anywhere itself.
  int _notificationIdFor(String reminderId) {
    const int fnvOffsetBasis = 0x811c9dc5;
    const int fnvPrime = 0x01000193;
    var hash = fnvOffsetBasis;
    for (final codeUnit in reminderId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  String _causeOf(Object error) => '$error';
}
