import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'shell/app_shell.dart';
import 'shell/placeholder_page.dart';
import 'features/home/home_page.dart';
import 'features/files/files_page.dart';
import 'features/notes/notes_page.dart';
import 'features/clock/world_clock_page.dart';
import 'features/alarm/alarm_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(
          currentPath: state.uri.path,
          onNavigate: (path) => context.go(path),
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/', builder: (c, s) => HomePage(onNavigate: (p) => c.go(p))),
        GoRoute(path: '/video', builder: (c, s) => const PlaceholderPage(title: 'Video Player', icon: LucideIcons.clapperboard)),
        GoRoute(path: '/music', builder: (c, s) => const PlaceholderPage(title: 'Music Player', icon: LucideIcons.music)),
        GoRoute(path: '/images', builder: (c, s) => const PlaceholderPage(title: 'Image Viewer', icon: LucideIcons.image)),
        GoRoute(path: '/documents', builder: (c, s) => const PlaceholderPage(title: 'Document Viewer', icon: LucideIcons.fileText)),
        GoRoute(path: '/pdf', builder: (c, s) => const PlaceholderPage(title: 'PDF Viewer', icon: LucideIcons.file)),
        GoRoute(path: '/files', builder: (c, s) => const FilesPage()),
        GoRoute(path: '/notes', builder: (c, s) => const NotesPage()),
        GoRoute(path: '/alarm', builder: (c, s) => const AlarmPage()),
        GoRoute(path: '/clock', builder: (c, s) => const WorldClockPage()),
        GoRoute(path: '/favorites', builder: (c, s) => const PlaceholderPage(title: 'Favorites', icon: LucideIcons.star)),
        GoRoute(path: '/settings', builder: (c, s) => const PlaceholderPage(title: 'Settings', icon: LucideIcons.settings)),
      ],
    ),
  ],
);
