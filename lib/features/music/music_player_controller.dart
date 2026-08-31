import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'music_index.dart';
import 'music_models.dart';

enum MusicRepeatMode { off, all, one }

/// App-wide persistent audio player — lives above the router so a mini
/// player bar can stay visible while the user navigates other sections.
class MusicPlayerController extends ChangeNotifier {
  final Player player = Player();
  List<SongEntry> queue = [];
  int currentIndex = -1;
  bool shuffle = false;
  MusicRepeatMode repeat = MusicRepeatMode.off;
  final List<int> _shuffleOrder = [];

  /// Wired from main.dart once the video controller also exists — enforces
  /// "only one media source plays at a time" without a circular import.
  VoidCallback? pauseOtherMedia;

  SongEntry? get current => currentIndex >= 0 && currentIndex < queue.length ? queue[currentIndex] : null;

  MusicPlayerController() {
    player.stream.completed.listen((done) {
      if (done) _onSongEnd();
    });
  }

  void _onSongEnd() {
    if (repeat == MusicRepeatMode.one) {
      player.seek(Duration.zero);
      player.play();
      return;
    }
    next();
  }

  Future<void> playQueue(List<SongEntry> songs, int startIndex) async {
    queue = songs;
    currentIndex = startIndex;
    _rebuildShuffleOrder();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final song = current;
    if (song == null) return;
    pauseOtherMedia?.call();
    await player.open(Media(song.path));
    MusicIndexService.recordPlayed(song.path);
    notifyListeners();
  }

  void _rebuildShuffleOrder() {
    _shuffleOrder.clear();
    _shuffleOrder.addAll(List.generate(queue.length, (i) => i)..shuffle(Random()));
  }

  Future<void> next() async {
    if (queue.isEmpty) return;
    if (shuffle) {
      final pos = _shuffleOrder.indexOf(currentIndex);
      if (pos + 1 < _shuffleOrder.length) {
        currentIndex = _shuffleOrder[pos + 1];
      } else if (repeat == MusicRepeatMode.all) {
        currentIndex = _shuffleOrder.first;
      } else {
        return;
      }
    } else {
      if (currentIndex + 1 < queue.length) {
        currentIndex++;
      } else if (repeat == MusicRepeatMode.all) {
        currentIndex = 0;
      } else {
        return;
      }
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = queue.length - 1;
    }
    await _playCurrent();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    _rebuildShuffleOrder();
    notifyListeners();
  }

  void cycleRepeat() {
    repeat = MusicRepeatMode.values[(repeat.index + 1) % MusicRepeatMode.values.length];
    notifyListeners();
  }

  void addToQueueNext(SongEntry song) {
    queue.insert(currentIndex + 1, song);
    notifyListeners();
  }

  void addToQueueEnd(SongEntry song) {
    queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index == currentIndex) return;
    queue.removeAt(index);
    if (index < currentIndex) currentIndex--;
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    if (oldIndex == currentIndex) {
      currentIndex = newIndex;
    }
    notifyListeners();
  }
}
