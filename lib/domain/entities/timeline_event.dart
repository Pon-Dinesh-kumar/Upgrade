import 'package:uuid/uuid.dart';

class TimelineEvent {
  final String id;
  final String type;
  final String title;
  final String description;
  final String? linkedEntityId;
  final DateTime timestamp;

  TimelineEvent({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    this.linkedEntityId,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  TimelineEvent copyWith({
    String? type,
    String? title,
    String? description,
    String? linkedEntityId,
    DateTime? timestamp,
  }) {
    return TimelineEvent(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'linkedEntityId': linkedEntityId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        linkedEntityId: json['linkedEntityId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
