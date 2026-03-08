import 'package:uuid/uuid.dart';

class UpgradeGroup {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final int color;
  final String difficulty;
  final DateTime startDate;
  final DateTime endDate;
  final double cutoffPercentage;
  final String? outcomeDescription;
  final String status;
  final double? completionScore;
  final int? xpAwarded;
  final DateTime createdAt;
  final bool archived;

  UpgradeGroup({
    String? id,
    required this.name,
    this.description = '',
    this.iconCodePoint = 0xe5d8,
    this.color = 0xFF6200EE,
    this.difficulty = 'medium',
    required this.startDate,
    required this.endDate,
    this.cutoffPercentage = 0.7,
    this.outcomeDescription,
    this.status = 'active',
    this.completionScore,
    this.xpAwarded,
    DateTime? createdAt,
    this.archived = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  UpgradeGroup copyWith({
    String? name,
    String? description,
    int? iconCodePoint,
    int? color,
    String? difficulty,
    DateTime? startDate,
    DateTime? endDate,
    double? cutoffPercentage,
    String? outcomeDescription,
    String? status,
    double? completionScore,
    int? xpAwarded,
    bool? archived,
  }) {
    return UpgradeGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      color: color ?? this.color,
      difficulty: difficulty ?? this.difficulty,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cutoffPercentage: cutoffPercentage ?? this.cutoffPercentage,
      outcomeDescription: outcomeDescription ?? this.outcomeDescription,
      status: status ?? this.status,
      completionScore: completionScore ?? this.completionScore,
      xpAwarded: xpAwarded ?? this.xpAwarded,
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
        'difficulty': difficulty,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'cutoffPercentage': cutoffPercentage,
        'outcomeDescription': outcomeDescription,
        'status': status,
        'completionScore': completionScore,
        'xpAwarded': xpAwarded,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory UpgradeGroup.fromJson(Map<String, dynamic> json) => UpgradeGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe5d8,
        color: json['color'] as int? ?? 0xFF6200EE,
        difficulty: json['difficulty'] as String? ?? 'medium',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        cutoffPercentage: (json['cutoffPercentage'] as num?)?.toDouble() ?? 0.7,
        outcomeDescription: json['outcomeDescription'] as String?,
        status: json['status'] as String? ?? 'active',
        completionScore: (json['completionScore'] as num?)?.toDouble(),
        xpAwarded: json['xpAwarded'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        archived: json['archived'] as bool? ?? false,
      );
}
