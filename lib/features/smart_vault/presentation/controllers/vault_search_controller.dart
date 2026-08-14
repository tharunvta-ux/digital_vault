import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vault_document.dart';
import '../providers/vault_providers.dart';

/// Holds the results of the most recent search. State is nullable and
/// distinct from an empty list: `null` means "no search has been run yet"
/// (e.g. show nothing / the full list); `[]` means "a search ran and
/// matched nothing" (show an empty-results message).
///
/// Deliberately has **no** blocking re-entrancy guard, unlike the mutation
/// controllers above: those guard against a double-tap firing the same
/// action twice, but search is expected to fire again on every keystroke --
/// blocking a new call while a previous one is still in flight would make
/// the search box feel unresponsive while typing. Every keystroke's call
/// runs immediately; [_generation] only decides whose *result* wins.
///
/// Without that generation check, two overlapping calls (a fast one for a
/// later keystroke resolving before a slow one for an earlier keystroke)
/// could apply their results out of order -- the box would show query B's
/// text but query A's stale results. It also happens to be what was
/// crashing with "Bad state: Future already completed": Riverpod's
/// AsyncNotifier finishes its internal completer on the *first* `state =`
/// assignment after a `AsyncLoading()`; a second overlapping call finishing
/// later and assigning `state =` again tripped over that already-finished
/// completer. Discarding a superseded call's result before it ever touches
/// `state` avoids both problems from the same fix.
class VaultSearchController extends AutoDisposeAsyncNotifier<List<VaultDocument>?> {
  int _generation = 0;
  bool _disposed = false;

  @override
  FutureOr<List<VaultDocument>?> build() {
    ref.onDispose(() => _disposed = true);
    return null;
  }

  Future<void> search(String query) async {
    final generation = ++_generation;
    // TEMPORARY DEV LOGGING -- diagnosing search/filter/realtime bugs.
    // Remove once resolved.
    debugPrint('[SEARCH] search() called -- query: "$query", generation: $generation');
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(vaultRepositoryProvider).searchDocuments(query));
    if (_disposed || generation != _generation) {
      debugPrint(
        '[SEARCH] query "$query" (generation $generation) resolved but is stale '
        '(current generation: $_generation, disposed: $_disposed) -- discarding',
      );
      return;
    }
    debugPrint('[SEARCH] query "$query" (generation $generation) applied -- hasError: ${result.hasError}');
    state = result;
  }

  void clear() {
    _generation++;
    state = const AsyncData(null);
  }
}

final vaultSearchControllerProvider =
    AsyncNotifierProvider.autoDispose<VaultSearchController, List<VaultDocument>?>(
  VaultSearchController.new,
);
