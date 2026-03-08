import 'package:uuid/uuid.dart';

class Achievement {
  final String id;
  final String key;
  final String name;
  final String description;
  final int iconCodePoint;
  final DateTime? unlockedAt;

  Achievement({
    String? id,
    required this.key,
    required this.name,
    required this.description,
    this.iconCodePoint = 0xe571,
    this.unlockedAt,
  }) : id = id ?? const Uuid().v4();

  static final List<Achievement> definitions = [
    Achievement(
        key: 'first_habit',
        name: 'First Step',
        description: 'Create your first habit',
        iconCodePoint: 0xe571),
    Achievement(
        key: 'first_completion',
        name: 'Getting Started',
        description: 'Complete a habit for the first time',
        iconCodePoint: 0xe876),
    Achievement(
        key: '7_day_streak',
        name: 'One Week Strong',
        description: 'Maintain a 7-day streak',
        iconCodePoint: 0xe80e),
    Achievement(
        key: '30_day_streak',
        name: 'Monthly Master',
        description: 'Maintain a 30-day streak',
        iconCodePoint: 0xf06bb),
    Achievement(
        key: '100_day_streak',
        name: 'Centurion',
        description: 'Maintain a 100-day streak',
        iconCodePoint: 0xe32a),
    Achievement(
        key: 'first_upgrade',
        name: 'Upgrading',
        description: 'Create your first upgrade group',
        iconCodePoint: 0xe5d8),
    Achievement(
        key: 'first_level_up',
        name: 'Level Up!',
        description: 'Reach level 2',
        iconCodePoint: 0xe5dc),
    Achievement(
        key: 'reach_level_10',
        name: 'Double Digits',
        description: 'Reach level 10',
        iconCodePoint: 0xe838),
    Achievement(
        key: '10_habits',
        name: 'Habit Builder',
        description: 'Create 10 habits',
        iconCodePoint: 0xf06c9),
    Achievement(
        key: 'first_goal',
        name: 'Goal Setter',
        description: 'Create your first goal',
        iconCodePoint: 0xe153),
    Achievement(
        key: 'goal_complete',
        name: 'Goal Crusher',
        description: 'Complete a goal',
        iconCodePoint: 0xe876),
    Achievement(
        key: '365_day_streak',
        name: 'Yearly Legend',
        description: 'Maintain a 365-day streak',
        iconCodePoint: 0xe559),
  ];

  Achievement copyWith({
    String? key,
    String? name,
    String? description,
    int? iconCodePoint,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'name': name,
        'description': description,
        'iconCodePoint': iconCodePoint,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe571,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
      );
}
