import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final int color;
  final String upgradeId;
  final String frequency;
  final String? frequencyConfig;
  final String difficulty;
  final double? targetValue;
  final String? unit;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final bool archived;

  Habit({
    String? id,
    required this.name,
    this.description = '',
    this.iconCodePoint = 0xe571,
    this.color = 0xFF6200EE,
    required this.upgradeId,
    this.frequency = 'daily',
    this.frequencyConfig,
    this.difficulty = 'medium',
    this.targetValue,
    this.unit,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? createdAt,
    this.archived = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Habit copyWith({
    String? name,
    String? description,
    int? iconCodePoint,
    int? color,
    String? upgradeId,
    String? frequency,
    String? frequencyConfig,
    String? difficulty,
    double? targetValue,
    String? unit,
    int? currentStreak,
    int? longestStreak,
    bool? archived,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      color: color ?? this.color,
      upgradeId: upgradeId ?? this.upgradeId,
      frequency: frequency ?? this.frequency,
      frequencyConfig: frequencyConfig ?? this.frequencyConfig,
      difficulty: difficulty ?? this.difficulty,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconCodePoint': iconCodePoint,
        'color': color,
        'upgradeId': upgradeId,
        'frequency': frequency,
        'frequencyConfig': frequencyConfig,
        'difficulty': difficulty,
        'targetValue': targetValue,
        'unit': unit,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe571,
        color: json['color'] as int? ?? 0xFF6200EE,
        upgradeId: json['upgradeId'] as String? ?? '',
        frequency: json['frequency'] as String? ?? 'daily',
        frequencyConfig: json['frequencyConfig'] as String?,
        difficulty: json['difficulty'] as String? ?? 'medium',
        targetValue: (json['targetValue'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
      );
}
