import 'package:uuid/uuid.dart';

class UpgradeHabit {
  final String id;
  final String upgradeId;
  final String habitId;
  final DateTime joinedDate;
  final DateTime? leftDate;

  UpgradeHabit({
    String? id,
    required this.upgradeId,
    required this.habitId,
    DateTime? joinedDate,
    this.leftDate,
  })  : id = id ?? const Uuid().v4(),
        joinedDate = joinedDate ?? DateTime.now();

  UpgradeHabit copyWith({DateTime? leftDate}) {
    return UpgradeHabit(
      id: id,
      upgradeId: upgradeId,
      habitId: habitId,
      joinedDate: joinedDate,
      leftDate: leftDate ?? this.leftDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'upgradeId': upgradeId,
        'habitId': habitId,
        'joinedDate': joinedDate.toIso8601String(),
        'leftDate': leftDate?.toIso8601String(),
      };

  factory UpgradeHabit.fromJson(Map<String, dynamic> json) => UpgradeHabit(
        id: json['id'] as String,
        upgradeId: json['upgradeId'] as String,
        habitId: json['habitId'] as String,
        joinedDate: DateTime.parse(json['joinedDate'] as String),
        leftDate: json['leftDate'] != null
            ? DateTime.parse(json['leftDate'] as String)
            : null,
      );
}
