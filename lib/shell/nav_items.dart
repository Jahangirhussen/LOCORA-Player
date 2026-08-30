import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/widgets.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String path;
  const NavItem(this.label, this.icon, this.path);
}

const List<NavItem> kNavItems = [
  NavItem('Home', LucideIcons.house, '/'),
  NavItem('Video', LucideIcons.clapperboard, '/video'),
  NavItem('Music', LucideIcons.music, '/music'),
  NavItem('Images', LucideIcons.image, '/images'),
  NavItem('Documents', LucideIcons.fileText, '/documents'),
  NavItem('PDF', LucideIcons.file, '/pdf'),
  NavItem('Files', LucideIcons.folder, '/files'),
  NavItem('Notes', LucideIcons.notebookPen, '/notes'),
  NavItem('Alarm', LucideIcons.alarmClock, '/alarm'),
  NavItem('Clock', LucideIcons.globe, '/clock'),
  NavItem('Favorites', LucideIcons.star, '/favorites'),
];

const NavItem kSettingsItem = NavItem('Settings', LucideIcons.settings, '/settings');
