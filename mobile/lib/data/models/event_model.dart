/// Event model — match backend EventResponse.

class EventItem {
  final int id;
  final int userId;
  final String title;
  final String eventType;
  final DateTime eventDate;
  final String? location;
  final String? dressCode;

  EventItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.eventType,
    required this.eventDate,
    this.location,
    this.dressCode,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      eventType: json['event_type'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      location: json['location'] as String?,
      dressCode: json['dress_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'event_type': eventType,
      'event_date': eventDate.toIso8601String(),
      if (location != null) 'location': location,
      if (dressCode != null) 'dress_code': dressCode,
    };
  }
}

class EventType {
  static const List<String> all = [
    'wedding', 'interview', 'date', 'business_meeting',
    'party', 'casual_outing', 'vacation', 'gym',
    'formal_dinner', 'brunch', 'concert', 'travel',
  ];

  static const List<String> dressCodes = [
    'casual', 'smart_casual', 'business', 'formal', 'black_tie',
  ];
}
