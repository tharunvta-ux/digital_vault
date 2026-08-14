/// Why a password-recovery link failed to establish a session.
///
/// [alreadyUsed] exists for completeness and for the UI copy it drives, but
/// is not currently reachable via automatic detection: Supabase's own error
/// taxonomy uses the single code `otp_expired` for both a genuinely expired
/// link and an already-consumed one ("The OTP has expired or has already
/// been used," per Supabase's own docs) -- there is no distinct signal to
/// tell them apart from the client side. `otp_expired` is mapped to
/// [expired] because that's the literal instruction this was built to; if
/// Supabase ever exposes a distinguishing code, [alreadyUsed] is ready to
/// receive it in `mapRecoveryFailureReason` without any other change.
enum RecoveryFailureReason { expired, alreadyUsed, unknown }
