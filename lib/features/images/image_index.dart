import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/file_scanner.dart';
import 'image_models.dart';

const String imageIndexBox = 'image_index';
const String imageStateBox = 'image_state';
const _imageExts = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.tiff'};

class ImageIndexService {
  static Box get _box => Hive.box(imageIndexBox);
  static Box get stateBox => Hive.box(imageStateBox);

  static List<ImageEntry> cached() {
    final raw = _box.get('entries') as List?;
    if (raw == null) return [];
    return raw.map((e) => ImageEntry.fromJson(Map.from(e))).toList();
  }

  static Future<List<ImageEntry>> rescan() async {
    final hits = await scanForExtensions(_imageExts);
    final images = hits
        .map((h) => ImageEntry(path: h.path, name: pathFileName(h.path), sizeBytes: h.sizeBytes, modified: h.modified))
        .toList();
    await _box.put('entries', images.map((e) => e.toJson()).toList());
    return images;
  }

  static bool isFavorite(String path) => stateBox.get('fav:$path', defaultValue: false);
  static void toggleFavorite(String path) => stateBox.put('fav:$path', !isFavorite(path));

  static void recordViewed(String path) => stateBox.put('lastViewed:$path', DateTime.now().toIso8601String());
  static DateTime? lastViewed(String path) {
    final iso = stateBox.get('lastViewed:$path');
    return iso == null ? null : DateTime.tryParse(iso);
  }
}
