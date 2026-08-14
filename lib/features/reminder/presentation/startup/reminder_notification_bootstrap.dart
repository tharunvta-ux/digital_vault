import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/reminder_providers.dart';

/// Runs once, before the app's first frame (see `main.dart`): starts the
/// notification engine, requests permission, and re-schedules every
/// enabled, not-yet-completed reminder from Supabase.
///
/// This exists because scheduled notifications are not guaranteed to
/// survive every OS/plugin lifecycle event (a device reboot clears
/// Android's AlarmManager entries entirely, for one -- see the file-level
/// note in the final report for what that means in practice), and
/// definitely don't reflect a change made from a different device while
/// this app was closed. Reconciling against Supabase's current state on
/// every launch is what keeps the two in sync.
///
/// Never throws: a failure here (no notification permission, no network,
/// no signed-in session yet) must not block the app from launching, so
/// every failure is caught and logged instead of propagating.
Future<void> restoreReminderNotificationsOnStartup(ProviderContainer container) async {
  final notificationService = container.read(notificationServiceProvider);

  try {
    await notificationService.initialize();
  } catch (error, stackTrace) {
    debugPrint('[NOTIFICATIONS] initialize() failed: $error');
    debugPrint('$stackTrace');
    return; // Nothing past this point can work without a running plugin.
  }

  try {
    await notificationService.requestPermission();
  } catch (error) {
    debugPrint('[NOTIFICATIONS] requestPermission() failed: $error');
    // Not fatal to startup -- scheduling calls below still succeed, they
    // just won't visibly notify without permission.
  }

  try {
    // Waits for Supabase's initial session check to resolve (the same
    // Stream authStateChangesProvider itself wraps) rather than assuming
    // a session already exists this early in startup.
    final user = await container.read(authStateChangesProvider.future);
    if (user == null) return; // Nothing to restore for a signed-out user.

    final reminders = await container.read(fetchRemindersUseCaseProvider)();
    await notificationService.restoreScheduledReminders(reminders);
  } catch (error, stackTrace) {
    debugPrint('[NOTIFICATIONS] restoreScheduledReminders() failed: $error');
    debugPrint('$stackTrace');
  }
}
