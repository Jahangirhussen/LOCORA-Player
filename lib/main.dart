import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'router.dart';
import 'features/notes/notes_page.dart' show notesBoxName, notesTrashBoxName;
import 'features/alarm/alarm_page.dart';
import 'features/video/video_index.dart';
import 'features/music/music_index.dart';
import 'features/music/music_player_controller.dart';
import 'features/video/video_player_controller.dart';
import 'features/images/image_index.dart';
import 'features/pdf/pdf_index.dart';
import 'features/files/files_index.dart';
import 'features/tasks/tasks_page.dart' show tasksBoxName;
import 'features/calendar/calendar_page.dart' show calendarBoxName;
import 'core/library_folders.dart';
import 'features/storage_access/storage_access_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(notesBoxName);
  await Hive.openBox(notesTrashBoxName);
  await Hive.openBox(alarmsBoxName);
  await Hive.openBox(videoIndexBox);
  await Hive.openBox(videoStateBox);
  await Hive.openBox(musicIndexBox);
  await Hive.openBox(musicStateBox);
  await Hive.openBox(imageIndexBox);
  await Hive.openBox(imageStateBox);
  await Hive.openBox(pdfIndexBox);
  await Hive.openBox(pdfStateBox);
  await Hive.openBox(filesStateBox);
  await Hive.openBox(tasksBoxName);
  await Hive.openBox(calendarBoxName);
  await Hive.openBox(libraryFoldersBox);
  runApp(const AllInOneApp());
}

class AllInOneApp extends StatefulWidget {
  const AllInOneApp({super.key});

  @override
  State<AllInOneApp> createState() => _AllInOneAppState();
}

class _AllInOneAppState extends State<AllInOneApp> {
  late bool _onboarded = LibraryFoldersService.hasCompletedOnboarding;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicPlayerController()),
        ChangeNotifierProxyProvider<MusicPlayerController, VideoPlayerController>(
          create: (context) => VideoPlayerController(music: context.read<MusicPlayerController>()),
          update: (context, music, video) {
            video ??= VideoPlayerController(music: music);
            music.pauseOtherMedia = () {
              if (video!.player.state.playing) video.player.pause();
            };
            return video;
          },
        ),
      ],
      child: MaterialApp(
        title: 'LOCORA Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: _onboarded
            ? Router.withConfig(config: appRouter)
            : Scaffold(
                backgroundColor: AppColors.background,
                body: SafeArea(child: StorageAccessPage(onDone: () => setState(() => _onboarded = true))),
              ),
      ),
    );
  }
}
