import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'pwa_install.dart';

const String kReleasesUrl = 'https://github.com/Jahangirhussen/LOCORA-Player/releases/latest';

enum _Os { windows, mac, android, ios, linux }

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) PwaInstall.listen();
  }

  _Os? _detectOs() {
    if (kIsWeb) {
      final ua = defaultTargetPlatform;
      switch (ua) {
        case TargetPlatform.windows:
          return _Os.windows;
        case TargetPlatform.macOS:
          return _Os.mac;
        case TargetPlatform.android:
          return _Os.android;
        case TargetPlatform.iOS:
          return _Os.ios;
        case TargetPlatform.linux:
          return _Os.linux;
        default:
          return null;
      }
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return _Os.windows;
      case TargetPlatform.macOS:
        return _Os.mac;
      case TargetPlatform.android:
        return _Os.android;
      case TargetPlatform.iOS:
        return _Os.ios;
      case TargetPlatform.linux:
        return _Os.linux;
      default:
        return null;
    }
  }

  static const _cards = [
    (_Os.windows, Icons.desktop_windows_outlined, 'Windows', '.exe installer'),
    (_Os.mac, Icons.laptop_mac_outlined, 'macOS', '.dmg installer'),
    (_Os.android, Icons.android, 'Android', '.apk file'),
    (_Os.linux, Icons.terminal, 'Linux', '.AppImage / .deb'),
  ];

  @override
  Widget build(BuildContext context) {
    final detected = _detectOs();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Download LOCORA Player', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Runs 100% offline once installed. No account, no cloud.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 24),
          if (kIsWeb)
            ValueListenableBuilder<bool>(
              valueListenable: PwaInstall.canInstall,
              builder: (context, canInstall, _) {
                if (!canInstall) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: PwaInstall.promptInstall,
                    icon: const Icon(Icons.install_desktop, size: 18),
                    label: const Text('Install App (offline, this device)'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                );
              },
            ),
          if (detected != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentMuted, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppColors.accent)),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('We detected you\'re on ${_labelFor(detected)} — recommended download below.', style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _cards.map((c) => _DownloadCard(os: c.$1, icon: c.$2, label: c.$3, subtitle: c.$4, recommended: c.$1 == detected)).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Native Windows/macOS/Android/Linux installers below aren\'t built yet — those cards link to GitHub Releases, which is currently empty.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 24),
          const Text('All builds come from the same open-source code — nothing is uploaded, nothing tracked.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  String _labelFor(_Os os) => switch (os) {
        _Os.windows => 'Windows',
        _Os.mac => 'macOS',
        _Os.android => 'Android',
        _Os.ios => 'iOS',
        _Os.linux => 'Linux',
      };
}

class _DownloadCard extends StatelessWidget {
  final _Os os;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool recommended;
  const _DownloadCard({required this.os, required this.icon, required this.label, required this.subtitle, required this.recommended});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => launchUrl(Uri.parse(kReleasesUrl), webOnlyWindowName: '_blank'),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: recommended ? AppColors.accent : AppColors.border, width: recommended ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: recommended ? AppColors.accent : AppColors.textSecondary, size: 28),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            if (recommended)
              const Text('RECOMMENDED', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700))
            else
              const Text('Download', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
