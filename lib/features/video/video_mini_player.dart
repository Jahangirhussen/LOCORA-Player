import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import 'video_index.dart';
import 'video_player_controller.dart';
import 'video_player_page.dart';

/// Compact bar shown whenever a video is loaded but its full-screen player
/// isn't open — playback (and audio) keeps running underneath while the
/// user browses other sections.
class VideoMiniPlayer extends StatelessWidget {
  const VideoMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerController>(
      builder: (context, ctrl, _) {
        final entry = ctrl.current;
        if (entry == null || !ctrl.minimized) return const SizedBox.shrink();
        return Container(
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ctrl.expand();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoPlayerPage()));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                  child: ctrl.audioOnly
                      ? const Icon(Icons.music_note, color: AppColors.textMuted, size: 18)
                      : ClipRRect(borderRadius: BorderRadius.circular(6), child: Video(controller: ctrl.videoController, controls: NoVideoControls)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(entry.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              StreamBuilder<bool>(
                stream: ctrl.player.stream.playing,
                builder: (context, s) {
                  final playing = s.data ?? ctrl.player.state.playing;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: AppColors.textPrimary),
                    onPressed: () => ctrl.player.playOrPause(),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.fullscreen, color: AppColors.textPrimary), onPressed: () {
                ctrl.expand();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoPlayerPage()));
              }),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () {
                  VideoIndexService.saveResumePosition(entry.path, ctrl.player.state.position);
                  ctrl.close();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
