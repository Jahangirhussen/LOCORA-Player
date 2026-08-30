import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import 'video_index.dart';
import 'video_models.dart';

const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

class VideoPlayerPage extends StatefulWidget {
  final VideoEntry entry;
  const VideoPlayerPage({super.key, required this.entry});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  Timer? _hideTimer;
  Timer? _saveTimer;
  bool _controlsVisible = true;
  double _speed = 1.0;
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _fav = VideoIndexService.isFavorite(widget.entry.path);
    _open();
    _resetHideTimer();
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      VideoIndexService.saveResumePosition(widget.entry.path, _player.state.position);
    });
  }

  Future<void> _open() async {
    await _player.open(Media(widget.entry.path));
    final resume = VideoIndexService.resumePosition(widget.entry.path);
    if (resume != null && resume.inSeconds > 3) {
      await _player.seek(resume);
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  @override
  void dispose() {
    VideoIndexService.saveResumePosition(widget.entry.path, _player.state.position);
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _showInfo() {
    final v = widget.entry;
    final track = _player.state.track;
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
              Text('Duration: ${humanDuration(_player.state.duration)}'),
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

  Future<void> _pickAudioTrack() async {
    final tracks = _player.state.tracks.audio;
    final picked = await showModalBottomSheet<AudioTrack>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: tracks.map((t) => ListTile(title: Text(t.title ?? t.id), onTap: () => Navigator.pop(context, t))).toList(),
      ),
    );
    if (picked != null) await _player.setAudioTrack(picked);
  }

  Future<void> _pickSubtitleTrack() async {
    final tracks = _player.state.tracks.subtitle;
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
      await _player.setSubtitleTrack(picked);
    } else {
      await _player.setSubtitleTrack(SubtitleTrack.no());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: (_) => _resetHideTimer(),
        child: GestureDetector(
          onTap: _resetHideTimer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(controller: _controller, controls: NoVideoControls),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _Controls(
                    player: _player,
                    title: widget.entry.name,
                    fav: _fav,
                    speed: _speed,
                    onBack: () => Navigator.of(context).pop(),
                    onInfo: _showInfo,
                    onAudio: _pickAudioTrack,
                    onSubtitle: _pickSubtitleTrack,
                    onFav: () {
                      VideoIndexService.toggleFavorite(widget.entry.path);
                      setState(() => _fav = !_fav);
                    },
                    onSpeed: (s) {
                      _player.setRate(s);
                      setState(() => _speed = s);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final Player player;
  final String title;
  final bool fav;
  final double speed;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  final VoidCallback onAudio;
  final VoidCallback onSubtitle;
  final VoidCallback onFav;
  final void Function(double) onSpeed;

  const _Controls({
    required this.player,
    required this.title,
    required this.fav,
    required this.speed,
    required this.onBack,
    required this.onInfo,
    required this.onAudio,
    required this.onSubtitle,
    required this.onFav,
    required this.onSpeed,
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: Colors.white, size: 20),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white),
                                onPressed: () {
                                  if (isDesktopPlatform) {
                                    // handled by OS window manager; toggling handled elsewhere if needed
                                  }
                                },
                              ),
                            ],
                          ),
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

bool get isDesktopPlatform => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
