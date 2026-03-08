import 'package:uuid/uuid.dart';

class HabitEntry {
  final String id;
  final String habitId;
  final DateTime date;
  final double value;
  final bool completed;
  final String? note;
  final int? mood;
  final DateTime timestamp;

  HabitEntry({
    String? id,
    required this.habitId,
    required this.date,
    this.value = 1.0,
    this.completed = false,
    this.note,
    this.mood,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  HabitEntry copyWith({
    String? habitId,
    DateTime? date,
    double? value,
    bool? completed,
    String? note,
    int? mood,
    DateTime? timestamp,
  }) {
    return HabitEntry(
      id: id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      value: value ?? this.value,
      completed: completed ?? this.completed,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'value': value,
        'completed': completed,
        'note': note,
        'mood': mood,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HabitEntry.fromJson(Map<String, dynamic> json) => HabitEntry(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        value: (json['value'] as num?)?.toDouble() ?? 1.0,
        completed: json['completed'] as bool? ?? false,
        note: json['note'] as String?,
        mood: json['mood'] as int?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
