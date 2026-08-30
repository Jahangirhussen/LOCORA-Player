import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/app_theme.dart';
import 'router.dart';
import 'features/notes/notes_page.dart';
import 'features/alarm/alarm_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(notesBoxName);
  await Hive.openBox(alarmsBoxName);
  runApp(const AllInOneApp());
}

class AllInOneApp extends StatelessWidget {
  const AllInOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'All-in-One',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
