import '../../domain/entities/timeline_event.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../datasources/local/local_storage.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final LocalStorage _storage;
  static const _key = 'timeline_events';

  TimelineRepositoryImpl(this._storage);

  @override
  Future<List<TimelineEvent>> getAllEvents() async {
    final data = await _storage.readList(_key);
    return data.map((e) => TimelineEvent.fromJson(e)).toList();
  }

  @override
  Future<List<TimelineEvent>> getRecentEvents(int limit) async {
    final all = await getAllEvents();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  @override
  Future<void> addEvent(TimelineEvent event) async {
    final all = await getAllEvents();
    all.add(event);
    await _storage.writeList(_key, all.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<TimelineEvent>> getEventsByType(String type) async {
    final all = await getAllEvents();
    return all.where((e) => e.type == type).toList();
  }
}
