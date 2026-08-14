import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../smart_vault/presentation/providers/vault_providers.dart';
import '../../domain/entities/reminder.dart';
import '../controllers/reminder_controller.dart';
import '../providers/reminder_providers.dart';
import '../state/reminder_filter.dart';
import '../state/reminder_sort_option.dart';
import '../state/reminder_state.dart';
import '../utils/reminder_list_query.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_filter_chips.dart';
import '../widgets/reminder_search_bar.dart';
import '../widgets/reminder_section_header.dart';
import '../widgets/reminder_sort_button.dart';
import 'create_reminder_page.dart';
import 'reminder_details_page.dart';

/// Smart Reminder home: search, filter, sort, and the grouped
/// Upcoming/Overdue/Completed reminder list -- all driven by
/// [reminderControllerProvider]/`ReminderState`. Owns only ephemeral UI
/// selection state locally (search text, which filter/sort is picked, which
/// sections are collapsed); the underlying data and every
/// create/update/delete/complete/reopen action goes exclusively through the
/// existing Phase 3 controller.
class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  final _searchController = TextEditingController();
  ReminderFilter _filter = ReminderFilter.all;
  ReminderSortOption _sort = ReminderSortOption.nearestDate;
  final Set<String> _collapsedSections = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    // The explicit "start watching" entry point `ReminderController`
    // exposes for exactly this purpose (see its own doc comment) -- gives
    // an immediate loading state on first mount rather than waiting for the
    // first stream event to arrive.
    ref.read(reminderControllerProvider.notifier).watchReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(watchRemindersProvider);
    await ref.read(watchRemindersProvider.future);
  }

  void _toggleSection(String key) {
    setState(() {
      if (_collapsedSections.contains(key)) {
        _collapsedSections.remove(key);
      } else {
        _collapsedSections.add(key);
      }
    });
  }

  void _openCreate() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateReminderPage()));
  }

  void _openDetails(String reminderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReminderDetailsPage(reminderId: reminderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderControllerProvider);
    final documents = ref.watch(watchAllDocumentsProvider).valueOrNull ?? const [];
    final documentTitles = {for (final document in documents) document.documentId: document.title};

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reminders'),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: 'Create reminder',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(state, documentTitles),
    );
  }

  Widget _buildBody(ReminderState state, Map<String, String> documentTitles) {
    if (state.reminders.isEmpty) {
      if (state.isLoading) {
        return const LoadingIndicator(message: 'Loading your reminders...');
      }
      if (state.hasError) {
        return AppErrorWidget(
          message: state.errorMessage ?? AppStrings.genericErrorMessage,
          onRetry: () => ref.invalidate(watchRemindersProvider),
        );
      }
      return EmptyStateWidget(
        title: 'No reminders yet',
        message: 'Create your first reminder to get started.',
        icon: Icons.notifications_none,
        actionLabel: 'Create Reminder',
        onAction: _openCreate,
      );
    }

    final groups = buildReminderListGroups(
      state: state,
      filter: _filter,
      query: _query,
      sort: _sort,
      documentTitles: documentTitles,
    );

    final isSearching = _query.isNotEmpty;
    if (isSearching && groups.isEmpty) {
      return Column(
        children: [
          _buildToolbar(),
          const Expanded(
            child: EmptyStateWidget(
              title: 'No results found',
              message: 'Try a different search term.',
              icon: Icons.search_off,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          _buildToolbar(),
          _buildSection(
            sectionKey: 'upcoming',
            title: 'Upcoming',
            reminders: groups.upcoming,
            documentTitles: documentTitles,
            emptyMessage: 'No upcoming reminders.',
          ),
          _buildSection(
            sectionKey: 'overdue',
            title: 'Overdue',
            reminders: groups.overdue,
            documentTitles: documentTitles,
            emptyMessage: 'No overdue reminders.',
          ),
          _buildSection(
            sectionKey: 'completed',
            title: 'Completed',
            reminders: groups.completed,
            documentTitles: documentTitles,
            emptyMessage: 'No completed reminders.',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: ReminderSearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ReminderFilterChips(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
            ),
            ReminderSortButton(
              selected: _sort,
              onSelected: (sort) => setState(() => _sort = sort),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String sectionKey,
    required String title,
    required List<Reminder> reminders,
    required Map<String, String> documentTitles,
    required String emptyMessage,
  }) {
    final isExpanded = !_collapsedSections.contains(sectionKey);
    return Column(
      children: [
        ReminderSectionHeader(
          title: title,
          count: reminders.length,
          isExpanded: isExpanded,
          onTap: () => _toggleSection(sectionKey),
        ),
        if (isExpanded)
          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Builder(
                builder: (context) => Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ReminderCard(
                    reminder: reminder,
                    documentTitle: documentTitles[reminder.documentId],
                    onTap: () => _openDetails(reminder.id),
                  ),
                );
              },
            ),
      ],
    );
  }
}
