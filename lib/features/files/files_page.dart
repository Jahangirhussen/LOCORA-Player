import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Local file browser. Uses dart:io directly — no need for an external
/// library here, the platform filesystem APIs are already sufficient.
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  Directory? _current;
  List<Directory> _roots = [];
  List<FileSystemEntity> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoots();
  }

  Future<void> _loadRoots() async {
    try {
      List<Directory> roots = [];
      if (Platform.isWindows) {
        for (var letter in 'CDEFGHIJ'.split('')) {
          final d = Directory('$letter:\\');
          if (await d.exists()) roots.add(d);
        }
      } else {
        roots = [Directory(Platform.environment['HOME'] ?? '/')];
      }
      setState(() => _roots = roots);
      if (roots.isNotEmpty) _open(roots.first);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _open(Directory dir) async {
    setState(() {
      _loading = true;
      _current = dir;
      _error = null;
    });
    try {
      final list = await dir.list().toList();
      list.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Cannot access this folder (${e.runtimeType})';
        _entries = [];
        _loading = false;
      });
    }
  }

  IconData _iconFor(FileSystemEntity e) {
    if (e is Directory) return LucideIcons.folder;
    final ext = e.path.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) return LucideIcons.clapperboard;
    if (['mp3', 'wav', 'flac', 'aac', 'm4a'].contains(ext)) return LucideIcons.music;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) return LucideIcons.image;
    if (ext == 'pdf') return LucideIcons.file;
    if (['doc', 'docx', 'txt', 'rtf', 'csv', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) return LucideIcons.fileText;
    return LucideIcons.file;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Text('Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              ..._roots.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(r.path, style: const TextStyle(fontSize: 12)),
                      backgroundColor: _current?.path == r.path ? AppColors.accentMuted : AppColors.card,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () => _open(r),
                    ),
                  )),
            ],
          ),
        ),
        if (_current != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(_current!.path, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final e = _entries[i];
                        final name = e.path.split(Platform.pathSeparator).last;
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: Icon(_iconFor(e), size: 18, color: e is Directory ? AppColors.accent : AppColors.textSecondary),
                            title: Text(name, style: const TextStyle(fontSize: 13)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                            onTap: e is Directory ? () => _open(e) : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
