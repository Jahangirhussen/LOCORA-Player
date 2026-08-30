class VideoEntry {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modified;

  VideoEntry({required this.path, required this.name, required this.sizeBytes, required this.modified});

  String get folder => path.substring(0, path.length - name.length - 1);

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'sizeBytes': sizeBytes,
        'modified': modified.toIso8601String(),
      };

  factory VideoEntry.fromJson(Map j) => VideoEntry(
        path: j['path'],
        name: j['name'],
        sizeBytes: j['sizeBytes'],
        modified: DateTime.parse(j['modified']),
      );
}

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
