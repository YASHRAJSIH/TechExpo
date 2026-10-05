import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/bookmarks_cubit.dart';
import '../cubits/bookmarks_state.dart';
import '../models/session.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/app_header.dart';
import '../widgets/category_tag.dart';
import '../widgets/info_pill.dart';
import '../widgets/message_view.dart';
import 'session_detail_page.dart';

/// `null` means "All".
typedef _StatusFilter = SessionStatus?;

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  _StatusFilter _filter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<BookmarksCubit, BookmarksState>(
        builder: (context, state) {
          final now = DateTime.now();
          final all = state.sessions;
          final visible = _filter == null
              ? all
              : all.where((s) => s.statusAt(now) == _filter).toList();

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: AppHeader(subtitle: 'Bookmarks')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EventDateChip(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Bookmarks',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                          const Spacer(),
                          _SavedCountBadge(count: all.length),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (all.isNotEmpty)
                SliverToBoxAdapter(
                  child: _StatusFilterChips(
                    sessions: all,
                    now: now,
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                ),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: all.isEmpty
                      ? const MessageView(
                          icon: Icons.bookmark_border,
                          title: 'No bookmarks yet',
                          message:
                              'Tap the bookmark button on a session '
                              'to save it here.',
                        )
                      : MessageView(
                          icon: Icons.filter_list_off,
                          title: 'Nothing here',
                          message:
                              'No ${_filterLabel(_filter).toLowerCase()} '
                              'sessions in your bookmarks.',
                        ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _BookmarkCard(session: visible[i], now: now),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _filterLabel(_StatusFilter filter) {
  switch (filter) {
    case null:
      return 'All';
    case SessionStatus.upcoming:
      return 'Upcoming';
    case SessionStatus.live:
      return 'Live';
    case SessionStatus.completed:
      return 'Completed';
  }
}

class _SavedCountBadge extends StatelessWidget {
  const _SavedCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count saved',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.sessions,
    required this.now,
    required this.selected,
    required this.onSelected,
  });

  final List<Session> sessions;
  final DateTime now;
  final _StatusFilter selected;
  final ValueChanged<_StatusFilter> onSelected;

  static const _options = <_StatusFilter>[
    null,
    SessionStatus.upcoming,
    SessionStatus.live,
    SessionStatus.completed,
  ];

  int _countFor(_StatusFilter filter) => filter == null
      ? sessions.length
      : sessions.where((s) => s.statusAt(now) == filter).length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = _options[i];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text('${_filterLabel(option)} (${_countFor(option)})'),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(option),
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

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({required this.session, required this.now});

  final Session session;
  final DateTime now;

  void _remove(BuildContext context) {
    final cubit = context.read<BookmarksCubit>();
    cubit.remove(session.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Bookmark removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.toggle(session),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.statusAt(now) == SessionStatus.completed;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1,
      child: Material(
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
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(session: session, now: now),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => _remove(context),
                      tooltip: 'Remove bookmark',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.bookmark),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            text: formatTimeRange(
                              session.startTime,
                              session.endTime,
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Live now · Stage 2", "Upcoming in 25m", "Upcoming · 15:30" or
/// "Completed".
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.session, required this.now});

  final Session session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final (IconData? icon, String text, Color color) = switch (session.statusAt(
      now,
    )) {
      SessionStatus.live => (
        Icons.circle,
        'Live now · ${session.room.isEmpty ? session.hall : session.room}',
        AppColors.tertiary,
      ),
      SessionStatus.upcoming
          when session.startTime.difference(now).inMinutes < 60 =>
        (
          Icons.bolt,
          'Upcoming in ${session.startTime.difference(now).inMinutes + 1}m',
          AppColors.primary,
        ),
      SessionStatus.upcoming => (
        null,
        'Upcoming · ${formatTime(session.startTime)}',
        AppColors.textMuted,
      ),
      SessionStatus.completed => (
        Icons.check_circle_outline,
        'Completed',
        AppColors.textMuted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: icon == Icons.circle ? 7 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
