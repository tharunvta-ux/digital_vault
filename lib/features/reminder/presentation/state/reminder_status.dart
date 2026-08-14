/// Lifecycle status of [ReminderState].
///
/// Explicit, hand-rolled status rather than wrapping Riverpod's built-in
/// `AsyncValue` the way Smart Vault's per-operation controllers do --
/// deliberately, per this feature's design: one controller owns one state
/// object covering the reminder list, the currently selected reminder, and
/// whichever operation is in flight, rather than a separate `AsyncNotifier`
/// per action. See `ReminderController`'s doc comment for the consequence
/// of that choice.
enum ReminderStatus { initial, loading, success, error }
