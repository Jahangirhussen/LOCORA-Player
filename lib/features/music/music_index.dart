import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/file_scanner.dart';
import 'music_models.dart';

const String musicIndexBox = 'music_index';
const String musicStateBox = 'music_state'; // favorites, most-played counters, playlists
const _musicExts = {'.mp3', '.flac', '.wav', '.aac', '.m4a', '.ogg', '.wma'};

class MusicIndexService {
  static Box get _box => Hive.box(musicIndexBox);
  static Box get stateBox => Hive.box(musicStateBox);

  static List<SongEntry> cached() {
    final raw = _box.get('entries') as List?;
    if (raw == null) return [];
    return raw.map((e) => SongEntry.fromJson(Map.from(e))).toList();
  }

  static Future<List<SongEntry>> rescan() async {
    final hits = await scanForExtensions(_musicExts);
    final songs = <SongEntry>[];
    for (final h in hits) {
      var title = pathFileName(h.path);
      var artist = 'Unknown Artist';
      var album = 'Unknown Album';
      var genre = '';
      int? year;
      int? durationMs;
      try {
        final tag = readMetadata(File(h.path), getImage: false);
        if (tag.title != null && tag.title!.isNotEmpty) title = tag.title!;
        if (tag.artist != null && tag.artist!.isNotEmpty) artist = tag.artist!;
        if (tag.album != null && tag.album!.isNotEmpty) album = tag.album!;
        if (tag.genres.isNotEmpty) genre = tag.genres.first;
        year = tag.year?.year;
        durationMs = tag.duration?.inMilliseconds;
      } catch (_) {}
      songs.add(SongEntry(
        path: h.path,
        name: pathFileName(h.path),
        sizeBytes: h.sizeBytes,
        modified: h.modified,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        year: year,
        durationMs: durationMs,
      ));
    }
    await _box.put('entries', songs.map((e) => e.toJson()).toList());
    return songs;
  }

  static bool isFavorite(String path) => stateBox.get('fav:$path', defaultValue: false);
  static void toggleFavorite(String path) => stateBox.put('fav:$path', !isFavorite(path));

  static void recordPlayed(String path) {
    stateBox.put('lastPlayed:$path', DateTime.now().toIso8601String());
    final count = stateBox.get('playCount:$path', defaultValue: 0) as int;
    stateBox.put('playCount:$path', count + 1);
  }

  static DateTime? lastPlayed(String path) {
    final iso = stateBox.get('lastPlayed:$path');
    return iso == null ? null : DateTime.tryParse(iso);
  }

  static int playCount(String path) => stateBox.get('playCount:$path', defaultValue: 0);

  // --- playlists: Map<String playlistName, List<String> paths> ---
  static Map<String, List<String>> playlists() {
    final raw = stateBox.get('playlists') as Map?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k as String, List<String>.from(v)));
  }

  static void savePlaylists(Map<String, List<String>> playlists) {
    stateBox.put('playlists', playlists.map((k, v) => MapEntry(k, v)));
  }

  static void addToPlaylist(String playlist, String path) {
    final all = playlists();
    all.putIfAbsent(playlist, () => []);
    if (!all[playlist]!.contains(path)) all[playlist]!.add(path);
    savePlaylists(all);
  }

  static void removePlaylist(String playlist) {
    final all = playlists();
    all.remove(playlist);
    savePlaylists(all);
  }
}
