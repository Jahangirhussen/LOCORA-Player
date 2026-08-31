export '../../core/file_scanner.dart' show humanSize, humanDuration;

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
