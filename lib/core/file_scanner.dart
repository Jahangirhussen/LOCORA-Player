import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the storage/media permissions Android needs before touching
/// the filesystem. No-op on other platforms (they don't gate access this
/// way), and on web (which can't access the filesystem at all).
Future<void> ensureStoragePermission() async {
  if (kIsWeb || !Platform.isAndroid) return;
  await [
    Permission.videos,
    Permission.photos,
    Permission.audio,
    Permission.storage,
  ].request();
}

/// Generic offline filesystem scanner shared by Video/Music/Images/PDF
/// indexers — one walk implementation, each feature just passes its own
/// extension set and folder-skip rules.
class RawFileHit {
  final String path;
  final int sizeBytes;
  final DateTime modified;
  RawFileHit(this.path, this.sizeBytes, this.modified);
}

const _skipNames = {r'$RECYCLE.BIN', 'System Volume Information', 'node_modules', 'Windows', '.git'};

Future<List<RawFileHit>> scanForExtensions(Set<String> extensions) async {
  if (kIsWeb) return [];
  await ensureStoragePermission();
  final roots = <Directory>[];
  try {
    if (Platform.isWindows) {
      for (var letter in 'CDEFGHIJ'.split('')) {
        final d = Directory('$letter:\\');
        if (await d.exists()) roots.add(d);
      }
    } else {
      roots.add(Directory(Platform.environment['HOME'] ?? '/'));
    }
  } catch (_) {
    return [];
  }

  final out = <RawFileHit>[];
  for (final root in roots) {
    await _walk(root, extensions, out, 0);
  }
  return out;
}

Future<void> _walk(Directory dir, Set<String> extensions, List<RawFileHit> out, int depth) async {
  if (depth > 8) return;
  final name = dir.path.split(Platform.pathSeparator).last;
  if (name.startsWith('.') || _skipNames.contains(name)) return;
  List<FileSystemEntity> list;
  try {
    list = await dir.list().toList();
  } catch (_) {
    return;
  }
  for (final e in list) {
    if (e is Directory) {
      await _walk(e, extensions, out, depth + 1);
    } else if (e is File) {
      final i = e.path.lastIndexOf('.');
      final ext = i == -1 ? '' : e.path.substring(i).toLowerCase();
      if (extensions.contains(ext)) {
        try {
          final stat = await e.stat();
          out.add(RawFileHit(e.path, stat.size, stat.modified));
        } catch (_) {}
      }
    }
  }
}

String pathFileName(String path) => path.split(Platform.pathSeparator).last;
String pathFolder(String path, String name) => path.substring(0, path.length - name.length - 1);

String humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String humanDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '$m:${s.toString().padLeft(2, '0')}';
}
