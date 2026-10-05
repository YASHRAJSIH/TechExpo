import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/sessions_cubit.dart';
import '../cubits/sessions_state.dart';
import '../models/session.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/app_header.dart';
import '../widgets/category_tag.dart';
import '../widgets/info_pill.dart';
import '../widgets/message_view.dart';
import 'session_detail_page.dart';

const _allFilter = 'All';
const _todayFilter = 'Today';
const _tomorrowFilter = 'Tomorrow';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  String _selectedFilter = _allFilter;
  String _query = '';

  /// "All", "Today", "Tomorrow", then one chip per hall in the data.
  List<String> _filtersFor(List<Session> sessions) {
    final halls =
        sessions
            .map((s) => s.hall)
            .where((h) => h != Session.fallback)
            .toSet()
            .toList()
          ..sort();
    return [_allFilter, _todayFilter, _tomorrowFilter, ...halls];
  }

  bool _matchesFilter(Session session, DateTime now) {
    switch (_selectedFilter) {
      case _allFilter:
        return true;
      case _todayFilter:
        return DateUtils.isSameDay(session.startTime, now);
      case _tomorrowFilter:
        return DateUtils.isSameDay(
          session.startTime,
          now.add(const Duration(days: 1)),
        );
      default:
        return session.hall == _selectedFilter;
    }
  }

  List<Session> _visible(List<Session> sessions) {
    final now = DateTime.now();
    final query = _query.trim().toLowerCase();
    return sessions.where((s) {
      final matchesQuery =
          query.isEmpty ||
          s.title.toLowerCase().contains(query) ||
          s.speaker.toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query);
      return matchesQuery && _matchesFilter(s, now);
    }).toList();
  }

  void _showRefreshError(BuildContext context, SessionsState state) {
    if (state is! SessionsLoaded) return;
    final error = state.refreshError;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => context.read<SessionsCubit>().load(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SessionsCubit>();

    return SafeArea(
      bottom: false,
      child: BlocConsumer<SessionsCubit, SessionsState>(
        listener: _showRefreshError,
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: AppHeader(subtitle: 'Sessions'),
                ),
                ...switch (state) {
                  SessionsLoading() => [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  SessionsError(:final message) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.cloud_off,
                        title: 'Couldn\'t load sessions',
                        message: message,
                        actionLabel: 'Retry',
                        onAction: cubit.load,
                      ),
                    ),
                  ],
                  SessionsEmpty() => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MessageView(
                        icon: Icons.event_busy,
                        title: 'No sessions yet',
                        message:
                            'The schedule hasn\'t been published. '
                            'Check back later.',
                        actionLabel: 'Refresh',
                        onAction: cubit.load,
                      ),
                    ),
                  ],
                  SessionsLoaded(:final sessions) => _loadedSlivers(sessions),
                },
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _loadedSlivers(List<Session> sessions) {
    final filters = _filtersFor(sessions);
    // The selected hall may disappear after a refresh.
    if (!filters.contains(_selectedFilter)) _selectedFilter = _allFilter;
    final visible = _visible(sessions);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EventDateChip(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Sessions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Showing ${visible.length} of ${sessions.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SearchField(onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _FilterChips(
          filters: filters,
          selected: _selectedFilter,
          onSelected: (f) => setState(() => _selectedFilter = f),
        ),
      ),
      if (visible.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: MessageView(
            icon: Icons.search_off,
            title: 'No matching sessions',
            message: 'Try a different search or filter.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _SessionCard(session: visible[i]),
          ),
        ),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search title, speaker or category...',
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = filters[i];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(filter),
            selectedColor: AppColors.secondary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? AppColors.secondary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          SessionDetailPage.routeName,
          arguments: session,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryTag(category: session.category),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.neutral,
                    child: Text(
                      initialsOf(session.speaker),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        session.speaker,
                        session.speakerRole,
                      ].where((t) => t.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  InfoPill(
                    icon: Icons.access_time,
                    text:
                        '${formatDay(session.startTime)} · '
                        '${formatTimeRange(session.startTime, session.endTime)}',
                  ),
                  InfoPill(
                    icon: Icons.location_on_outlined,
                    text: session.location,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
