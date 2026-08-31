import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../core/file_scanner.dart';
import 'video_index.dart';
import 'video_player_controller.dart';

const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

/// Full-screen player UI — reads from the app-wide VideoPlayerController so
/// closing this screen (back button) just minimizes to the mini player bar
/// rather than stopping playback.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  double _speed = 1.0;

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showInfo(VideoPlayerController ctrl) {
    final v = ctrl.current;
    if (v == null) return;
    final track = ctrl.player.state.track;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(v.name),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size: ${humanSize(v.sizeBytes)}'),
              Text('Duration: ${humanDuration(ctrl.player.state.duration)}'),
              Text('Modified: ${v.modified}'),
              Text('Audio track: ${track.audio.title ?? track.audio.id}'),
              Text('Subtitle: ${track.subtitle.title ?? track.subtitle.id}'),
              const SizedBox(height: 8),
              Text('Location:\n${v.path}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _pickAudioTrack(VideoPlayerController ctrl) async {
    final tracks = ctrl.player.state.tracks.audio;
    final picked = await showModalBottomSheet<AudioTrack>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: tracks.map((t) => ListTile(title: Text(t.title ?? t.id), onTap: () => Navigator.pop(context, t))).toList(),
      ),
    );
    if (picked != null) await ctrl.player.setAudioTrack(picked);
  }

  Future<void> _pickSubtitleTrack(VideoPlayerController ctrl) async {
    final tracks = ctrl.player.state.tracks.subtitle;
    final picked = await showModalBottomSheet<SubtitleTrack>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Off')),
          ...tracks.map((t) => ListTile(title: Text(t.title ?? t.id), onTap: () => Navigator.pop(context, t))),
        ],
      ),
    );
    if (picked != null) {
      await ctrl.player.setSubtitleTrack(picked);
    } else {
      await ctrl.player.setSubtitleTrack(SubtitleTrack.no());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerController>(
      builder: (context, ctrl, _) {
        final entry = ctrl.current;
        if (entry == null) return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
        final fav = VideoIndexService.isFavorite(entry.path);
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) ctrl.minimize();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: MouseRegion(
              onHover: (_) => _resetHideTimer(),
              child: GestureDetector(
                onTap: _resetHideTimer,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (ctrl.audioOnly)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note, color: AppColors.accent, size: 64),
                            const SizedBox(height: 16),
                            Text(entry.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            const Text('Audio Only', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      Video(controller: ctrl.videoController, controls: NoVideoControls),
                    AnimatedOpacity(
                      opacity: _controlsVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_controlsVisible,
                        child: _Controls(
                          player: ctrl.player,
                          title: entry.name,
                          fav: fav,
                          speed: _speed,
                          audioOnly: ctrl.audioOnly,
                          onBack: () => Navigator.of(context).pop(),
                          onInfo: () => _showInfo(ctrl),
                          onAudio: () => _pickAudioTrack(ctrl),
                          onSubtitle: () => _pickSubtitleTrack(ctrl),
                          onFav: () {
                            VideoIndexService.toggleFavorite(entry.path);
                            setState(() {});
                          },
                          onSpeed: (s) {
                            ctrl.player.setRate(s);
                            setState(() => _speed = s);
                          },
                          onToggleAudioOnly: () => ctrl.setAudioOnly(!ctrl.audioOnly),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final Player player;
  final String title;
  final bool fav;
  final double speed;
  final bool audioOnly;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  final VoidCallback onAudio;
  final VoidCallback onSubtitle;
  final VoidCallback onFav;
  final void Function(double) onSpeed;
  final VoidCallback onToggleAudioOnly;

  const _Controls({
    required this.player,
    required this.title,
    required this.fav,
    required this.speed,
    required this.audioOnly,
    required this.onBack,
    required this.onInfo,
    required this.onAudio,
    required this.onSubtitle,
    required this.onFav,
    required this.onSpeed,
    required this.onToggleAudioOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
          stops: [0, 0.2, 0.7, 1],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: Icon(fav ? Icons.star : Icons.star_border, color: AppColors.accent), onPressed: onFav),
                  IconButton(
                    icon: Icon(audioOnly ? Icons.videocam_outlined : Icons.music_note, color: Colors.white, size: 18),
                    tooltip: audioOnly ? 'Switch to Video' : 'Audio Only',
                    onPressed: onToggleAudioOnly,
                  ),
                  IconButton(icon: const Icon(LucideIcons.music, color: Colors.white, size: 18), tooltip: 'Audio track', onPressed: onAudio),
                  IconButton(icon: const Icon(Icons.subtitles_outlined, color: Colors.white), tooltip: 'Subtitle', onPressed: onSubtitle),
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed, color: Colors.white),
                    color: AppColors.cardElevated,
                    onSelected: onSpeed,
                    itemBuilder: (_) => _speeds.map((s) => PopupMenuItem(value: s, child: Text('${s}x', style: TextStyle(color: s == speed ? AppColors.accent : Colors.white)))).toList(),
                  ),
                  IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: onInfo),
                ],
              ),
            ),
          ),
          const Spacer(),
          StreamBuilder<Duration>(
            stream: player.stream.position,
            builder: (context, snap) {
              final pos = snap.data ?? Duration.zero;
              final dur = player.state.duration;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.accent,
                        trackHeight: 3,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: pos.inMilliseconds.clamp(0, dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds).toDouble(),
                        max: dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds.toDouble(),
                        onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(humanDuration(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => player.seek(pos - const Duration(seconds: 10))),
                              StreamBuilder<bool>(
                                stream: player.stream.playing,
                                builder: (context, s) {
                                  final playing = s.data ?? player.state.playing;
                                  return IconButton(
                                    iconSize: 36,
                                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
                                    onPressed: () => player.playOrPause(),
                                  );
                                },
                              ),
                              IconButton(icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => player.seek(pos + const Duration(seconds: 10))),
                            ],
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
