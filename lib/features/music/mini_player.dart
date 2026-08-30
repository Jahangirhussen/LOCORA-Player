import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import 'music_index.dart';
import 'music_player_controller.dart';

/// Persistent bottom bar — stays visible across every section so music
/// keeps playing while the user browses videos, PDFs, notes, etc.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerController>(
      builder: (context, ctrl, _) {
        final song = ctrl.current;
        if (song == null) return const SizedBox.shrink();
        final fav = MusicIndexService.isFavorite(song.path);
        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              StreamBuilder<Duration>(
                stream: ctrl.player.stream.position,
                builder: (context, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final dur = ctrl.player.state.duration;
                  final ratio = dur.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / dur.inMilliseconds;
                  return LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 2,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  );
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(song.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(song.artist, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18, color: fav ? AppColors.accent : AppColors.textMuted),
                        onPressed: () => MusicIndexService.toggleFavorite(song.path),
                      ),
                      IconButton(icon: const Icon(Icons.skip_previous, color: AppColors.textPrimary), onPressed: ctrl.previous),
                      StreamBuilder<bool>(
                        stream: ctrl.player.stream.playing,
                        builder: (context, s) {
                          final playing = s.data ?? ctrl.player.state.playing;
                          return IconButton(
                            icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppColors.accent, size: 30),
                            onPressed: () => ctrl.player.playOrPause(),
                          );
                        },
                      ),
                      IconButton(icon: const Icon(Icons.skip_next, color: AppColors.textPrimary), onPressed: ctrl.next),
                      IconButton(
                        icon: Icon(Icons.shuffle, size: 18, color: ctrl.shuffle ? AppColors.accent : AppColors.textMuted),
                        onPressed: ctrl.toggleShuffle,
                      ),
                      IconButton(
                        icon: Icon(
                          ctrl.repeat == MusicRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                          size: 18,
                          color: ctrl.repeat == MusicRepeatMode.off ? AppColors.textMuted : AppColors.accent,
                        ),
                        onPressed: ctrl.cycleRepeat,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
