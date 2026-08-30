import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  final void Function(String path) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  static const _cards = [
    (LucideIcons.clapperboard, 'Videos', '/video'),
    (LucideIcons.music, 'Music', '/music'),
    (LucideIcons.image, 'Images', '/images'),
    (LucideIcons.fileText, 'Documents', '/documents'),
    (LucideIcons.folder, 'Files', '/files'),
    (LucideIcons.notebookPen, 'Notes', '/notes'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Good to see you', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('What do you want to use?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 500 ? 2 : 3;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: _cards.map((c) => _HomeCard(icon: c.$1, label: c.$2, onTap: () => onNavigate(c.$3))).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text('Continue where you left', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            height: 90,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('Nothing opened yet — recently used files will show here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HomeCard({required this.icon, required this.label, required this.onTap});

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover ? AppColors.cardElevated : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: _hover ? AppColors.accent : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, color: AppColors.accent, size: 26),
                const Spacer(),
                Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
