import '../entities/timeline_event.dart';

abstract class TimelineRepository {
  Future<List<TimelineEvent>> getAllEvents();
  Future<List<TimelineEvent>> getRecentEvents(int limit);
  Future<void> addEvent(TimelineEvent event);
  Future<List<TimelineEvent>> getEventsByType(String type);
}
