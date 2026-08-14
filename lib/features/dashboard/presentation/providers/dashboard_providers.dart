import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';

/// Derives a friendly display name from the authenticated user's email,
/// since the domain user entity has no `displayName` field (Module 2 never
/// stores the Register screen's Full Name). Returns `null` when nothing
/// usable can be derived, so the welcome header can compose its greeting
/// conditionally instead of showing an awkward filler word.
final welcomeNameProvider = Provider<String?>((ref) {
  final email = ref.watch(authStateChangesProvider).valueOrNull?.email;
  return _deriveWelcomeName(email);
});

String? _deriveWelcomeName(String? email) {
  if (email == null || email.isEmpty) return null;
  final atIndex = email.indexOf('@');
  final localPart = atIndex > 0 ? email.substring(0, atIndex) : email;
  final tokens = localPart.split(RegExp(r'[._\-+]+')).where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return null;
  return tokens.map((t) => t[0].toUpperCase() + t.substring(1).toLowerCase()).join(' ');
}

/// A single placeholder statistic shown on the dashboard.
class DashboardStat {
  const DashboardStat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

/// Static placeholder stats — no repository exists yet, this is presentation
/// -layer DI wiring only, swappable for real data once a vault/reminder
/// module lands.
final dashboardStatsProvider = Provider<List<DashboardStat>>((ref) {
  return const [
    DashboardStat(label: 'Documents', value: '0', icon: Icons.description_outlined),
    DashboardStat(label: 'Reminders', value: '0', icon: Icons.notifications_none),
    DashboardStat(label: 'Categories', value: '0', icon: Icons.category_outlined),
    DashboardStat(label: 'Storage Used', value: '0 MB', icon: Icons.storage_outlined),
  ];
});
