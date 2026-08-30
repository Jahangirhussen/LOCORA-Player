import 'package:hive_ce_flutter/hive_flutter.dart';

const String filesStateBox = 'files_state';

/// Favorites + recent files/folders shared by the File Manager.
class FilesStateService {
  static Box get _box => Hive.box(filesStateBox);

  static bool isFavorite(String path) => _box.get('fav:$path', defaultValue: false);
  static void toggleFavorite(String path) => _box.put('fav:$path', !isFavorite(path));

  static List<String> favorites() {
    final keys = _box.keys.where((k) => k.toString().startsWith('fav:') && _box.get(k) == true);
    return keys.map((k) => k.toString().substring(4)).toList();
  }

  static void recordOpened(String path) => _box.put('recent:$path', DateTime.now().toIso8601String());

  static List<MapEntry<String, DateTime>> recent() {
    final keys = _box.keys.where((k) => k.toString().startsWith('recent:'));
    final list = keys.map((k) {
      final path = k.toString().substring(7);
      final time = DateTime.tryParse(_box.get(k) ?? '') ?? DateTime.now();
      return MapEntry(path, time);
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}
