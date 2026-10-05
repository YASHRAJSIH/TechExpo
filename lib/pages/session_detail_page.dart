import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/bookmarks_cubit.dart';
import '../models/session.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/category_tag.dart';
import '../widgets/info_pill.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.session});

  static const routeName = '/session';

  final Session session;

  @override
  Widget build(BuildContext context) {
    final isBookmarked = context.select<BookmarksCubit, bool>(
      (cubit) => cubit.state.isBookmarked(session.id),
    );
    void toggleBookmark() => context.read<BookmarksCubit>().toggle(session);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.secondary,
        centerTitle: true,
        title: const Text(
          'Session Details',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: toggleBookmark,
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _TitleSection(session: session),
          _SpeakerSection(session: session),
          _AboutSection(session: session),
          _VenueSection(session: session),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 50,
          child: isBookmarked
              ? OutlinedButton.icon(
                  onPressed: toggleBookmark,
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  label: const Text('Remove bookmark'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: toggleBookmark,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Bookmark session'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// White block used for each section of the page.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small green badge, e.g. "Keynote Speaker" or "Gate Open".
class _GreenBadge extends StatelessWidget {
  const _GreenBadge({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: AppColors.tertiary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTag(category: session.category, uppercase: true),
              const Spacer(),
              const Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Verified Track',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.title,
            style: const TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoPill(
                icon: Icons.access_time,
                text: formatTimeRange(session.startTime, session.endTime),
              ),
              InfoPill(
                icon: Icons.location_on_outlined,
                text: session.location,
              ),
              InfoPill(
                icon: Icons.calendar_today_outlined,
                text: formatDay(session.startTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeakerSection extends StatelessWidget {
  const _SpeakerSection({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            'Featured speaker',
            trailing: session.category == 'Keynote'
                ? const _GreenBadge(text: 'Keynote Speaker')
                : null,
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initialsOf(session.speaker),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.speaker,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (session.speakerRole.isNotEmpty)
                      Text(
                        session.speakerRole,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    if (session.speakerLocation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            session.speakerLocation,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _CircleIconButton(icon: Icons.share_outlined, onPressed: () {}),
              const SizedBox(width: 6),
              _CircleIconButton(icon: Icons.alternate_email, onPressed: () {}),
            ],
          ),
          if (session.speakerBio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              session.speakerBio,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: AppColors.secondary),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            session.description.isEmpty
                ? 'No description available yet.'
                : session.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          if (session.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Topic areas'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in session.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VenueSection extends StatelessWidget {
  const _VenueSection({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            'Venue & access',
            trailing: _GreenBadge(text: 'Gate Open', icon: Icons.circle),
          ),
          _FloorMap(session: session),
          const SizedBox(height: 12),
          Text(
            session.location,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          if (session.venue.isNotEmpty)
            Text(
              session.venue,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('View on interactive floor plan  →'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                backgroundColor: AppColors.neutral,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static floor-map placeholder: grid background, level badge and an
/// entrance card.
class _FloorMap extends StatelessWidget {
  const _FloorMap({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            const Center(
              child: Icon(
                Icons.location_on,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            if (session.level.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        session.level,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.door_front_door_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${session.room.isEmpty ? session.hall : session.room} Direct Entrance',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                          const Text(
                            'Turn right past Expo Hall Forum',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF3F8),
    );
    final line = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const step = 20.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
