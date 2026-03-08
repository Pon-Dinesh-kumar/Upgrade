import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static int daysBetween(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return bDate.difference(aDate).inDays.abs();
  }

  static List<DateTime> getLast30Days() {
    final today_ = today();
    return List.generate(30, (i) => today_.subtract(Duration(days: 29 - i)));
  }

  static List<DateTime> getDaysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    return List.generate(last.day, (i) => first.add(Duration(days: i)));
  }

  static bool shouldCompleteToday(String frequency, String? frequencyConfig) {
    final now = DateTime.now();
    switch (frequency) {
      case 'daily':
        return true;
      case 'weekly':
        return now.weekday == DateTime.monday;
      case 'custom':
        if (frequencyConfig == null) return true;
        final days = frequencyConfig
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toList();
        return days.contains(now.weekday);
      default:
        return true;
    }
  }
}
