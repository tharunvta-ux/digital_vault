import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/reminder_remote_datasource.dart';
import '../../data/datasources/supabase_reminder_remote_datasource.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../data/services/local_notification_service.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/create_reminder_usecase.dart';
import '../../domain/usecases/delete_reminder_usecase.dart';
import '../../domain/usecases/fetch_reminders_usecase.dart';
import '../../domain/usecases/get_reminder_usecase.dart';
import '../../domain/usecases/set_reminder_completed_usecase.dart';
import '../../domain/usecases/update_reminder_usecase.dart';
import '../../domain/usecases/watch_reminders_usecase.dart';

/// Dependency-injection graph for the Smart Reminder feature, wired the
/// same way as Smart Vault: hand-written Riverpod providers, no codegen,
/// each depending only on the one above it.
final reminderRemoteDataSourceProvider = Provider<ReminderRemoteDataSource>((ref) {
  return SupabaseReminderRemoteDataSource(ref.watch(supabaseClientProvider));
});

/// Reuses [supabaseClientProvider] from the authentication feature rather
/// than declaring a second `Provider<SupabaseClient>` -- there's only ever
/// one live client, and this also resolves the current user's UID for
/// reminder ownership, same reasoning as `vaultRepositoryProvider`.
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(
    ref.watch(reminderRemoteDataSourceProvider),
    ref.watch(supabaseClientProvider),
  );
});

final createReminderUseCaseProvider = Provider<CreateReminderUseCase>((ref) {
  return CreateReminderUseCase(ref.watch(reminderRepositoryProvider));
});

final updateReminderUseCaseProvider = Provider<UpdateReminderUseCase>((ref) {
  return UpdateReminderUseCase(ref.watch(reminderRepositoryProvider));
});

final deleteReminderUseCaseProvider = Provider<DeleteReminderUseCase>((ref) {
  return DeleteReminderUseCase(ref.watch(reminderRepositoryProvider));
});

final getReminderUseCaseProvider = Provider<GetReminderUseCase>((ref) {
  return GetReminderUseCase(ref.watch(reminderRepositoryProvider));
});

final watchRemindersUseCaseProvider = Provider<WatchRemindersUseCase>((ref) {
  return WatchRemindersUseCase(ref.watch(reminderRepositoryProvider));
});

final fetchRemindersUseCaseProvider = Provider<FetchRemindersUseCase>((ref) {
  return FetchRemindersUseCase(ref.watch(reminderRepositoryProvider));
});

final setReminderCompletedUseCaseProvider = Provider<SetReminderCompletedUseCase>((ref) {
  return SetReminderCompletedUseCase(ref.watch(reminderRepositoryProvider));
});

/// The plugin instance is a singleton by its own design (its constructor
/// always returns the same object -- see `FlutterLocalNotificationsPlugin`'s
/// own factory), so this just gives it a Riverpod-managed home rather than
/// letting [LocalNotificationService] reach for a bare global.
final flutterLocalNotificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

/// Deliberately does not depend on [reminderRepositoryProvider] or
/// [supabaseClientProvider] -- see `NotificationService`'s doc comment for
/// why it stays independent of both Supabase and the reminder UI.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService(ref.watch(flutterLocalNotificationsPluginProvider));
});

/// Live view of every reminder owned by the current user.
///
/// Watches [authStateChangesProvider] purely so this provider *rebuilds*
/// whenever the signed-in user changes -- same reasoning as Smart Vault's
/// `watchAllDocumentsProvider`.
///
/// `autoDispose`: the underlying Realtime subscription closes once nothing
/// is watching this anymore, rather than staying open for the app's entire
/// lifetime.
final watchRemindersProvider = StreamProvider.autoDispose<List<Reminder>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(watchRemindersUseCaseProvider)();
});

/// A single reminder by ID. A one-shot read (unlike [watchRemindersProvider]),
/// so `FutureProvider` rather than `StreamProvider`. `.family` keyed by
/// reminder ID so Riverpod caches per-reminder and disposes each entry once
/// nothing's viewing that particular reminder anymore.
final reminderByIdProvider = FutureProvider.autoDispose.family<Reminder?, String>((
  ref,
  reminderId,
) {
  ref.watch(authStateChangesProvider);
  return ref.watch(getReminderUseCaseProvider)(reminderId);
});
