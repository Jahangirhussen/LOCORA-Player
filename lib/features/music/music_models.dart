class SongEntry {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modified;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int? year;
  final int? durationMs;

  SongEntry({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modified,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    this.year,
    this.durationMs,
  });

  String get folder => path.substring(0, path.length - name.length - 1);
  Duration get duration => Duration(milliseconds: durationMs ?? 0);

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'sizeBytes': sizeBytes,
        'modified': modified.toIso8601String(),
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'year': year,
        'durationMs': durationMs,
      };

  factory SongEntry.fromJson(Map j) => SongEntry(
        path: j['path'],
        name: j['name'],
        sizeBytes: j['sizeBytes'],
        modified: DateTime.parse(j['modified']),
        title: j['title'] ?? j['name'],
        artist: j['artist'] ?? 'Unknown Artist',
        album: j['album'] ?? 'Unknown Album',
        genre: j['genre'] ?? '',
        year: j['year'],
        durationMs: j['durationMs'],
      );
}
