import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/icon/logo.png', width: 72, height: 72),
            ),
            const SizedBox(height: 16),
            const Text('LOCORA Player', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Text('Offline media, files, documents & productivity — one unified app', style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Developer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('Jahangir Hussen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      SelectableText('jahangirhussen.programmer@gmail.com', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('100% offline. No account. No cloud sync. No telemetry.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
