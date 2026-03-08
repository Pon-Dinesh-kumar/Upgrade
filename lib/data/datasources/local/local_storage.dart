import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static LocalStorage? _instance;
  late String _basePath;

  LocalStorage._();

  static Future<LocalStorage> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = LocalStorage._();
    final dir = await getApplicationDocumentsDirectory();
    _instance!._basePath = '${dir.path}/upgrade_data';
    final dataDir = Directory(_instance!._basePath);
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return _instance!;
  }

  String _filePath(String name) => '$_basePath/$name.json';

  Future<List<Map<String, dynamic>>> readList(String name) async {
    try {
      final file = File(_filePath(name));
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final decoded = jsonDecode(content);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error reading $name: $e');
      return [];
    }
  }

  Future<void> writeList(String name, List<Map<String, dynamic>> data) async {
    try {
      final file = File(_filePath(name));
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error writing $name: $e');
    }
  }

  Future<Map<String, dynamic>?> readObject(String name) async {
    try {
      final file = File(_filePath(name));
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading $name: $e');
      return null;
    }
  }

  Future<void> writeObject(String name, Map<String, dynamic>? data) async {
    try {
      final file = File(_filePath(name));
      if (data == null) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error writing $name: $e');
    }
  }

  Future<void> deleteFile(String name) async {
    try {
      final file = File(_filePath(name));
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error deleting $name: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      final dir = Directory(_basePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting all: $e');
    }
  }

  static const int _backupVersion = 1;
  static const List<String> _listKeys = [
    'habits',
    'habit_entries',
    'upgrades',
    'upgrade_habits',
    'goals',
    'achievements',
    'timeline_events',
  ];
  static const String _profileKey = 'user_profile';

  /// Exports all stored data for backup. Returns a map that can be JSON-encoded.
  Future<Map<String, dynamic>> exportForBackup() async {
    final profile = await readObject(_profileKey);
    final map = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      _profileKey: profile,
    };
    for (final key in _listKeys) {
      map[key] = await readList(key);
    }
    return map;
  }

  /// Imports from a backup map (e.g. from JSON). Overwrites existing data.
  Future<void> importFromBackup(Map<String, dynamic> map) async {
    final profile = map[_profileKey];
    if (profile is Map<String, dynamic>) {
      await writeObject(_profileKey, profile);
    }
    for (final key in _listKeys) {
      final list = map[key];
      if (list is List) {
        final data = list
            .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
            .toList();
        await writeList(key, data);
      }
    }
  }
}
