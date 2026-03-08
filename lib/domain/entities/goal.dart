import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String name;
  final String description;
  final String? outcomeDescription;
  final DateTime? targetDate;
  final List<String> linkedHabitIds;
  final List<String> linkedUpgradeIds;
  final String status;
  final DateTime createdAt;

  Goal({
    String? id,
    required this.name,
    this.description = '',
    this.outcomeDescription,
    this.targetDate,
    List<String>? linkedHabitIds,
    List<String>? linkedUpgradeIds,
    this.status = 'active',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        linkedHabitIds = linkedHabitIds ?? [],
        linkedUpgradeIds = linkedUpgradeIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Goal copyWith({
    String? name,
    String? description,
    String? outcomeDescription,
    DateTime? targetDate,
    List<String>? linkedHabitIds,
    List<String>? linkedUpgradeIds,
    String? status,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      outcomeDescription: outcomeDescription ?? this.outcomeDescription,
      targetDate: targetDate ?? this.targetDate,
      linkedHabitIds: linkedHabitIds ?? this.linkedHabitIds,
      linkedUpgradeIds: linkedUpgradeIds ?? this.linkedUpgradeIds,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'outcomeDescription': outcomeDescription,
        'targetDate': targetDate?.toIso8601String(),
        'linkedHabitIds': linkedHabitIds,
        'linkedUpgradeIds': linkedUpgradeIds,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        outcomeDescription: json['outcomeDescription'] as String?,
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'] as String)
            : null,
        linkedHabitIds:
            (json['linkedHabitIds'] as List<dynamic>?)?.cast<String>() ?? [],
        linkedUpgradeIds:
            (json['linkedUpgradeIds'] as List<dynamic>?)?.cast<String>() ?? [],
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
