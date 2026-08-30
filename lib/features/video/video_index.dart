import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'video_models.dart';

const String videoIndexBox = 'video_index';
const String videoStateBox = 'video_state'; // resume position, favorites, history per path

const _videoExts = {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv', '.wmv', '.m4v', '.3gp', '.ts'};

/// Scans common local folders once, caches results in Hive so the UI never
/// has to walk the filesystem again until the user asks to rescan.
class VideoIndexService {
  static Box get _box => Hive.box(videoIndexBox);
  static Box get stateBox => Hive.box(videoStateBox);

  static List<VideoEntry> cached() {
    final raw = _box.get('entries') as List?;
    if (raw == null) return [];
    return raw.map((e) => VideoEntry.fromJson(Map.from(e))).toList();
  }

  static Future<List<VideoEntry>> rescan({void Function(String path)? onProgress}) async {
    // dart:io filesystem access isn't available on the web preview target;
    // real scanning only runs on desktop/mobile builds.
    if (kIsWeb) return [];
    final roots = <Directory>[];
    try {
      if (Platform.isWindows) {
        for (var letter in 'CDEFGHIJ'.split('')) {
          final d = Directory('$letter:\\');
          if (await d.exists()) roots.add(d);
        }
      } else {
        final home = Directory(Platform.environment['HOME'] ?? '/');
        roots.add(home);
      }
    } catch (_) {
      return [];
    }

    final found = <VideoEntry>[];
    for (final root in roots) {
      await _walk(root, found, onProgress, depth: 0);
    }
    await _box.put('entries', found.map((e) => e.toJson()).toList());
    await _box.put('lastScan', DateTime.now().toIso8601String());
    return found;
  }

  static Future<void> _walk(Directory dir, List<VideoEntry> out, void Function(String)? onProgress, {required int depth}) async {
    if (depth > 8) return;
    // Skip noisy system/hidden dirs.
    final name = dir.path.split(Platform.pathSeparator).last;
    if (name.startsWith('.') || name == r'$RECYCLE.BIN' || name == 'System Volume Information' || name == 'node_modules' || name == 'Windows') {
      return;
    }
    List<FileSystemEntity> list;
    try {
      list = await dir.list().toList();
    } catch (_) {
      return;
    }
    for (final e in list) {
      if (e is Directory) {
        await _walk(e, out, onProgress, depth: depth + 1);
      } else if (e is File) {
        final ext = _extOf(e.path);
        if (_videoExts.contains(ext)) {
          try {
            final stat = await e.stat();
            out.add(VideoEntry(path: e.path, name: e.path.split(Platform.pathSeparator).last, sizeBytes: stat.size, modified: stat.modified));
            onProgress?.call(e.path);
          } catch (_) {}
        }
      }
    }
  }

  static String _extOf(String path) {
    final i = path.lastIndexOf('.');
    return i == -1 ? '' : path.substring(i).toLowerCase();
  }

  // --- per-video state: resume position, favorite, last played ---

  static Duration? resumePosition(String path) {
    final ms = stateBox.get('resume:$path');
    return ms == null ? null : Duration(milliseconds: ms);
  }

  static void saveResumePosition(String path, Duration pos) {
    stateBox.put('resume:$path', pos.inMilliseconds);
  }

  static bool isFavorite(String path) => stateBox.get('fav:$path', defaultValue: false);

  static void toggleFavorite(String path) {
    stateBox.put('fav:$path', !isFavorite(path));
  }

  static void recordPlayed(String path) {
    stateBox.put('lastPlayed:$path', DateTime.now().toIso8601String());
  }

  static DateTime? lastPlayed(String path) {
    final iso = stateBox.get('lastPlayed:$path');
    return iso == null ? null : DateTime.tryParse(iso);
  }
}
