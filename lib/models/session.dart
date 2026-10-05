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

  static const fallback = 'TBA';

  final String id;
  final String title;
  final String category;
  final String speaker;
  final String speakerRole;
  final String speakerBio;
  final String speakerLocation;
  final DateTime startTime;

  /// `null` when the API doesn't give a valid end time.
  final DateTime? endTime;
  final String hall;
  final String room;
  final String venue;
  final String level;
  final String description;
  final List<String> tags;

  /// Parses one session from the API.
  ///
  /// `id`, `title` and `startTime` are required; a [FormatException] is
  /// thrown if any is missing or invalid. Every other field falls back to a
  /// safe default.
  factory Session.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    final title = _string(json['title']);
    final startTime = _dateTime(json['startTime']);
    if (id == null || title == null || startTime == null) {
      throw FormatException('Session is missing id, title or startTime', json);
    }

    final endTime = _dateTime(json['endTime']);
    final rawTags = json['tags'];

    return Session(
      id: id,
      title: title,
      category: _string(json['category']) ?? 'General',
      speaker: _string(json['speaker']) ?? fallback,
      speakerRole: _string(json['speakerRole']) ?? '',
      speakerBio: _string(json['speakerBio']) ?? '',
      speakerLocation: _string(json['speakerLocation']) ?? '',
      startTime: startTime,
      // An end time before the start is treated as missing.
      endTime: endTime != null && endTime.isAfter(startTime) ? endTime : null,
      hall: _string(json['hall']) ?? fallback,
      room: _string(json['room']) ?? '',
      venue: _string(json['venue']) ?? '',
      level: _string(json['level']) ?? '',
      description: _string(json['description']) ?? '',
      tags: rawTags is List
          ? List.unmodifiable(rawTags.map(_string).whereType<String>())
          : const [],
    );
  }

  /// Same shape as the API, so [Session.fromJson] can read it back.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'speaker': speaker,
    'speakerRole': speakerRole,
    'speakerBio': speakerBio,
    'speakerLocation': speakerLocation,
    'startTime': startTime.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    'hall': hall,
    'room': room,
    'venue': venue,
    'level': level,
    'description': description,
    'tags': tags,
  };

  /// "Hall A - Stage 2", or just "Hall A" when there's no room.
  String get location => room.isEmpty ? hall : '$hall - $room';

  SessionStatus statusAt(DateTime now) {
    if (now.isBefore(startTime)) return SessionStatus.upcoming;
    if (endTime != null && now.isBefore(endTime!)) return SessionStatus.live;
    return SessionStatus.completed;
  }

  /// Accepts strings and numbers (`"id": 1` and `"id": "1"`).
  /// Returns `null` for anything else or for blank strings.
  static String? _string(Object? value) {
    if (value is! String && value is! num) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
