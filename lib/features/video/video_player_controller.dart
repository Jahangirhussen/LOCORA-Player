import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../music/music_player_controller.dart';
import 'video_index.dart';
import 'video_models.dart';

/// App-wide persistent video player — lives above the router (same pattern
/// as MusicPlayerController) so playback/audio survives navigating to other
/// sections, and a mini player bar can stay visible. Audio-Only mode keeps
/// the same Player/audio pipeline running and simply stops rendering the
/// Video widget — media_kit doesn't decode-and-discard frames when the
/// Video widget isn't in the tree, so this also cuts the render cost.
class VideoPlayerController extends ChangeNotifier {
  final Player player = Player();
  late final VideoController videoController = VideoController(player);
  VideoEntry? current;
  bool audioOnly = false;
  bool minimized = true; // true = only mini-bar showing, not the full player screen
  Timer? _saveTimer;

  final MusicPlayerController? music;
  VideoPlayerController({this.music}) {
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (current != null) VideoIndexService.saveResumePosition(current!.path, player.state.position);
    });
  }

  Future<void> open(VideoEntry entry, {bool audioOnlyMode = false}) async {
    // Enforce single active media source: starting video stops music.
    if (music?.player.state.playing == true) {
      music!.player.pause();
    }
    current = entry;
    audioOnly = audioOnlyMode;
    minimized = false;
    notifyListeners();
    await player.open(Media(entry.path));
    final resume = VideoIndexService.resumePosition(entry.path);
    if (resume != null && resume.inSeconds > 3) {
      await player.seek(resume);
    }
    VideoIndexService.recordPlayed(entry.path);
  }

  void setAudioOnly(bool value) {
    audioOnly = value;
    notifyListeners();
  }

  void minimize() {
    minimized = true;
    notifyListeners();
  }

  void expand() {
    minimized = false;
    notifyListeners();
  }

  void close() {
    if (current != null) VideoIndexService.saveResumePosition(current!.path, player.state.position);
    player.pause();
    current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    player.dispose();
    super.dispose();
  }
}
