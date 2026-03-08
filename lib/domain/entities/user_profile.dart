import 'dart:math';
import 'package:uuid/uuid.dart';

class UserProfile {
  final String id;
  final String username;
  final Map<String, int> avatarData;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final String rank;
  final DateTime createdAt;

  static const Map<String, int> _avatarPartRanges = {
    'face': 15,
    'nose': 13,
    'mouth': 19,
    'eyes': 13,
    'eyebrows': 15,
    'glasses': 14,
    'hair': 58,
    'accessories': 14,
    'details': 13,
    'beard': 16,
  };

  static Map<String, int> get avatarPartRanges => _avatarPartRanges;

  static Map<String, int> randomAvatarData() {
    final rng = Random();
    return {
      for (final e in _avatarPartRanges.entries) e.key: rng.nextInt(e.value),
    };
  }

  static const Map<String, int> defaultAvatarData = {
    'face': 0,
    'nose': 0,
    'mouth': 0,
    'eyes': 0,
    'eyebrows': 0,
    'glasses': 0,
    'hair': 0,
    'accessories': 0,
    'details': 0,
    'beard': 0,
  };

  UserProfile({
    String? id,
    required this.username,
    Map<String, int>? avatarData,
    this.level = 1,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.rank = 'Novice',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        avatarData = avatarData ?? defaultAvatarData,
        createdAt = createdAt ?? DateTime.now();

  UserProfile copyWith({
    String? username,
    Map<String, int>? avatarData,
    int? level,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    String? rank,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarData: avatarData ?? this.avatarData,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      rank: rank ?? this.rank,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatarData': avatarData,
        'level': level,
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'rank': rank,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<String, int>? avatar;
    if (json['avatarData'] is Map) {
      avatar = (json['avatarData'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarData: avatar,
      level: json['level'] as int? ?? 1,
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      rank: json['rank'] as String? ?? 'Novice',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
