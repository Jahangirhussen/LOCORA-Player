import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/app_theme.dart';
import 'router.dart';
import 'features/notes/notes_page.dart';
import 'features/alarm/alarm_page.dart';
import 'features/video/video_index.dart';
import 'features/music/music_index.dart';
import 'features/music/music_player_controller.dart';
import 'features/images/image_index.dart';
import 'features/pdf/pdf_index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(notesBoxName);
  await Hive.openBox(alarmsBoxName);
  await Hive.openBox(videoIndexBox);
  await Hive.openBox(videoStateBox);
  await Hive.openBox(musicIndexBox);
  await Hive.openBox(musicStateBox);
  await Hive.openBox(imageIndexBox);
  await Hive.openBox(imageStateBox);
  await Hive.openBox(pdfIndexBox);
  await Hive.openBox(pdfStateBox);
  runApp(const AllInOneApp());
}

class AllInOneApp extends StatelessWidget {
  const AllInOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicPlayerController(),
      child: MaterialApp.router(
        title: 'All-in-One',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
