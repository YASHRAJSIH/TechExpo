enum SessionStatus { upcoming, live, completed }

class Session {
  const Session({
    required this.id,
    required this.title,
    required this.category,
    required this.speaker,
    required this.speakerRole,
    required this.speakerBio,
    required this.speakerLocation,
    required this.startTime,
    required this.endTime,
    required this.hall,
    required this.room,
    required this.venue,
    required this.level,
    required this.description,
    required this.tags,
  });

  final String id;
  final String title;
  final String category;
  final String speaker;
  final String speakerRole;
  final String speakerBio;
  final String speakerLocation;
  final DateTime startTime;
  final DateTime endTime;
  final String hall;
  final String room;
  final String venue;
  final String level;
  final String description;
  final List<String> tags;

  SessionStatus statusAt(DateTime now) {
    if (now.isBefore(startTime)) return SessionStatus.upcoming;
    if (now.isBefore(endTime)) return SessionStatus.live;
    return SessionStatus.completed;
  }
}
