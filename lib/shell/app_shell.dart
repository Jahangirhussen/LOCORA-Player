import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'nav_items.dart';

/// Persistent shell: sidebar (desktop) / bottom nav (mobile) + top bar.
/// Every feature page renders inside [child] so the whole app shares one
/// sidebar, top bar, spacing and design language.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final void Function(String path) onNavigate;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) _Sidebar(currentPath: currentPath, onNavigate: onNavigate),
            Expanded(
              child: Column(
                children: [
                  _TopBar(showLogo: !isDesktop),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _BottomNav(currentPath: currentPath, onNavigate: onNavigate),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showLogo;
  const _TopBar({required this.showLogo});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            const Icon(Icons.grid_view_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text('All-in-One', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search everything...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentPath;
  final void Function(String path) onNavigate;
  const _Sidebar({required this.currentPath, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: const [
                Icon(Icons.grid_view_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text('All-in-One', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: kNavItems.map((item) => _NavTile(item: item, selected: currentPath == item.path, onTap: () => onNavigate(item.path))).toList(),
            ),
          ),
          const Divider(height: 1),
          _NavTile(item: kSettingsItem, selected: currentPath == kSettingsItem.path, onTap: () => onNavigate(kSettingsItem.path)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.accentMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentPath;
  final void Function(String path) onNavigate;
  const _BottomNav({required this.currentPath, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [...kNavItems.take(5)];
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: items.map((item) {
          final selected = currentPath == item.path;
          return Expanded(
            child: InkWell(
              onTap: () => onNavigate(item.path),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 20, color: selected ? AppColors.accent : AppColors.textMuted),
                  const SizedBox(height: 2),
                  Text(item.label, style: TextStyle(fontSize: 10, color: selected ? AppColors.accent : AppColors.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
