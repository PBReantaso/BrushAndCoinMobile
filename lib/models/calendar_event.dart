class CalendarEventSchedule {
  final String name;
  final String time;
  final String description;

  const CalendarEventSchedule({
    required this.name,
    required this.time,
    required this.description,
  });

  factory CalendarEventSchedule.fromJson(Map<String, dynamic> json) {
    return CalendarEventSchedule(
      name: (json['name'] as String?) ?? '',
      time: (json['time'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}

class CalendarEvent {
  final int id;
  final String title;
  final DateTime eventDate;
  final String eventTime;
  final String category;
  final String venue;
  final String locationText;
  final String description;
  final String additionalInfo;
  final double? latitude;
  final double? longitude;
  final List<CalendarEventSchedule> schedules;
  final String? imageUrl;
  final int? createdBy;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.eventTime,
    required this.category,
    required this.venue,
    required this.locationText,
    required this.description,
    required this.additionalInfo,
    required this.latitude,
    required this.longitude,
    required this.schedules,
    required this.imageUrl,
    required this.createdBy,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final dateRaw = (json['eventDate'] as String?) ?? '';
    final parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    final rawSchedules = json['schedules'];
    final schedules = rawSchedules is List
        ? rawSchedules
            .whereType<Map>()
            .map((entry) => CalendarEventSchedule.fromJson(
                  entry.map((k, v) => MapEntry('$k', v)),
                ))
            .toList()
        : const <CalendarEventSchedule>[];

    return CalendarEvent(
      id: _readInt(json['id']) ?? 0,
      title: (json['title'] as String?) ?? '',
      eventDate: parsedDate,
      eventTime: (json['eventTime'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      venue: (json['venue'] as String?) ?? '',
      locationText: (json['locationText'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      additionalInfo: (json['additionalInfo'] as String?) ?? '',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      schedules: schedules,
      imageUrl: json['imageUrl'] as String?,
      createdBy: _readInt(json['createdBy']),
    );
  }

  CalendarEvent copyWith({
    String? title,
    DateTime? eventDate,
    String? eventTime,
    String? category,
    String? venue,
    String? locationText,
    String? description,
    String? additionalInfo,
    double? latitude,
    double? longitude,
    List<CalendarEventSchedule>? schedules,
    String? imageUrl,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      category: category ?? this.category,
      venue: venue ?? this.venue,
      locationText: locationText ?? this.locationText,
      description: description ?? this.description,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      schedules: schedules ?? this.schedules,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy,
    );
  }
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
