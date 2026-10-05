import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/app_header.dart';
import '../widgets/category_tag.dart';
import '../widgets/info_pill.dart';
import 'session_detail_page.dart';

// Temporary data for the UI. Replaced by the REST API later.
final _sampleSessions = <Session>[
  Session(
    id: '1',
    title: 'AI Agents: The Next Generation of Software',
    category: 'Keynote',
    speaker: 'Anna Müller',
    speakerRole: 'Principal AI Engineer, TechLabs',
    speakerBio:
        'Anna works on intelligent developer platforms and production AI '
        'systems, with a focus on agentic workflows and human-in-the-loop '
        'applications.',
    speakerLocation: 'Munich, Germany',
    startTime: DateTime(2026, 10, 14, 10, 30),
    endTime: DateTime(2026, 10, 14, 11, 15),
    hall: 'Hall A',
    room: 'Stage 2',
    venue: 'MunichTech EXPO Center · Ground Floor, East Wing',
    level: 'Level 0',
    description:
        'AI agents are moving from experimental prototypes into production '
        'systems. This session explores how modern agent architectures work, '
        'where they deliver real business value, and the engineering '
        'challenges teams face when deploying reliable autonomous workflows.',
    tags: ['AgenticAI', 'SystemDesign', 'AutonomousWorkflows', 'EnterpriseAI'],
  ),
  Session(
    id: '2',
    title: 'Next-Gen Quantum Computing & Cryptography',
    category: 'Deep Tech',
    speaker: 'Dr. Lukas Weber',
    speakerRole: 'Quantum Lead, Max Planck Institute',
    speakerBio:
        'Lukas leads applied quantum research and advises industry on '
        'post-quantum cryptography migration.',
    speakerLocation: 'Garching, Germany',
    startTime: DateTime(2026, 10, 14, 11, 30),
    endTime: DateTime(2026, 10, 14, 12, 15),
    hall: 'Hall B',
    room: 'Tech Arena',
    venue: 'MunichTech EXPO Center · First Floor, North Wing',
    level: 'Level 1',
    description:
        'Where quantum hardware really stands today, and what engineering '
        'teams should do now to prepare their systems for post-quantum '
        'cryptography.',
    tags: ['Quantum', 'Cryptography', 'Security'],
  ),
  Session(
    id: '3',
    title: 'Scaling Cross-Platform Mobile Architectures',
    category: 'Engineering',
    speaker: 'Elena Rostova',
    speakerRole: 'Principal Engineer, Bavarian Labs',
    speakerBio:
        'Elena builds mobile platforms used by millions and maintains '
        'several open-source Flutter packages.',
    speakerLocation: 'Berlin, Germany',
    startTime: DateTime(2026, 10, 14, 13, 0),
    endTime: DateTime(2026, 10, 14, 13, 45),
    hall: 'Hall A',
    room: 'Stage 2',
    venue: 'MunichTech EXPO Center · Ground Floor, East Wing',
    level: 'Level 0',
    description:
        'Modular architecture, state management and release pipelines for '
        'cross-platform apps that need to grow with large teams.',
    tags: ['Flutter', 'Architecture', 'Mobile'],
  ),
  Session(
    id: '4',
    title: 'Autonomous Robotics & Industrial Automation',
    category: 'Hardware',
    speaker: 'Marcus Lindemann',
    speakerRole: 'Robotics Fellow, TUM',
    speakerBio:
        'Marcus researches autonomous systems for manufacturing and '
        'logistics at the Technical University of Munich.',
    speakerLocation: 'Munich, Germany',
    startTime: DateTime(2026, 10, 14, 14, 0),
    endTime: DateTime(2026, 10, 14, 14, 45),
    hall: 'Hall C',
    room: 'Robotics Lab',
    venue: 'MunichTech EXPO Center · Ground Floor, West Wing',
    level: 'Level 0',
    description:
        'From research lab to factory floor: how autonomous robots are being '
        'deployed safely alongside human workers.',
    tags: ['Robotics', 'Automation', 'Industry40'],
  ),
  Session(
    id: '5',
    title: 'Building Resilient European Tech Ecosystems',
    category: 'Panel',
    speaker: 'Dr. Sophie von Berg',
    speakerRole: 'Founding Partner, Isar Ventures',
    speakerBio:
        'Sophie invests in early-stage deep tech companies across Europe.',
    speakerLocation: 'Munich, Germany',
    startTime: DateTime(2026, 10, 14, 15, 15),
    endTime: DateTime(2026, 10, 14, 16, 0),
    hall: 'Hall A',
    room: 'Main Stage',
    venue: 'MunichTech EXPO Center · Ground Floor, East Wing',
    level: 'Level 0',
    description:
        'Founders, investors and policy makers discuss what Europe needs to '
        'grow and keep its next generation of tech companies.',
    tags: ['Startups', 'VentureCapital', 'Europe'],
  ),
  Session(
    id: '6',
    title: 'Green Cloud Computing & Low-Power Datacenters',
    category: 'Sustainability',
    speaker: 'Florian Bauer',
    speakerRole: 'Infrastructure Architect',
    speakerBio:
        'Florian designs energy-efficient cloud infrastructure for '
        'European data centres.',
    speakerLocation: 'Stuttgart, Germany',
    startTime: DateTime(2026, 10, 14, 16, 30),
    endTime: DateTime(2026, 10, 14, 17, 15),
    hall: 'Hall B',
    room: 'Stage 1',
    venue: 'MunichTech EXPO Center · First Floor, North Wing',
    level: 'Level 1',
    description:
        'Practical techniques for cutting the energy use and carbon '
        'footprint of cloud workloads without hurting performance.',
    tags: ['GreenTech', 'Cloud', 'Infrastructure'],
  ),
];

const _filters = ['All', 'Today', 'Tomorrow', 'Hall A', 'Hall B', 'Hall C'];

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  String _selectedFilter = 'All';
  String _query = '';

  List<Session> get _visibleSessions {
    final query = _query.trim().toLowerCase();
    return _sampleSessions.where((s) {
      final matchesFilter =
          !_selectedFilter.startsWith('Hall') || s.hall == _selectedFilter;
      final matchesQuery =
          query.isEmpty ||
          s.title.toLowerCase().contains(query) ||
          s.speaker.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _visibleSessions;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader(subtitle: 'Sessions')),
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
                        'Showing ${sessions.length} sessions today',
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
              selected: _selectedFilter,
              onSelected: (f) => setState(() => _selectedFilter = f),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
            ),
          ),
        ],
      ),
    );
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
        hintText: 'Search session title or speaker...',
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
  const _FilterChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
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
                      '${session.speaker} · ${session.speakerRole}',
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
                    text: formatTimeRange(session.startTime, session.endTime),
                  ),
                  InfoPill(
                    icon: Icons.location_on_outlined,
                    text: '${session.hall} - ${session.room}',
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
