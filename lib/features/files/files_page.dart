import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../core/file_scanner.dart';
import 'files_index.dart';

enum _SortBy { name, date, size, type }

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
  bool _grid = false;
  _SortBy _sort = _SortBy.name;
  String _query = '';
  final Set<String> _selected = {};
  final List<Directory> _history = [];
  String? _clipboardPath;
  bool _clipboardCut = false;

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
      if (roots.isNotEmpty) _open(roots.first, pushHistory: false);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _open(Directory dir, {bool pushHistory = true}) async {
    if (pushHistory && _current != null) _history.add(_current!);
    setState(() {
      _loading = true;
      _current = dir;
      _error = null;
      _selected.clear();
    });
    try {
      final list = await dir.list().toList();
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Cannot access this folder';
        _entries = [];
        _loading = false;
      });
    }
  }

  void _back() {
    if (_history.isNotEmpty) _open(_history.removeLast(), pushHistory: false);
  }

  void _up() {
    final parent = _current?.parent;
    if (parent != null && parent.path != _current!.path) _open(parent);
  }

  List<String> get _breadcrumbSegments {
    if (_current == null) return [];
    return _current!.path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).toList();
  }

  void _goToBreadcrumb(int index) {
    final segs = _breadcrumbSegments;
    final path = Platform.isWindows ? segs.sublist(0, index + 1).join(Platform.pathSeparator) : '/${segs.sublist(0, index + 1).join(Platform.pathSeparator)}';
    _open(Directory(path));
  }

  List<FileSystemEntity> get _filtered {
    var list = _entries;
    if (_query.isNotEmpty) {
      list = list.where((e) => pathFileName(e.path).toLowerCase().contains(_query.toLowerCase())).toList();
    }
    list = [...list];
    list.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      switch (_sort) {
        case _SortBy.name:
          return pathFileName(a.path).toLowerCase().compareTo(pathFileName(b.path).toLowerCase());
        case _SortBy.date:
          return b.statSync().modified.compareTo(a.statSync().modified);
        case _SortBy.size:
          return b.statSync().size.compareTo(a.statSync().size);
        case _SortBy.type:
          return _extOf(a.path).compareTo(_extOf(b.path));
      }
    });
    return list;
  }

  String _extOf(String path) {
    final i = path.lastIndexOf('.');
    return i == -1 ? '' : path.substring(i).toLowerCase();
  }

  IconData _iconFor(FileSystemEntity e) {
    if (e is Directory) return LucideIcons.folder;
    final ext = _extOf(e.path).replaceFirst('.', '');
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) return LucideIcons.clapperboard;
    if (['mp3', 'wav', 'flac', 'aac', 'm4a'].contains(ext)) return LucideIcons.music;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) return LucideIcons.image;
    if (ext == 'pdf') return LucideIcons.file;
    if (['doc', 'docx', 'txt', 'rtf', 'csv', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) return LucideIcons.fileText;
    return LucideIcons.file;
  }

  Future<void> _rename(FileSystemEntity e) async {
    final oldName = pathFileName(e.path);
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final newPath = '${pathFolder(e.path, oldName)}${Platform.pathSeparator}$newName';
      try {
        await e.rename(newPath);
        _open(_current!, pushHistory: false);
      } catch (err) {
        _showError('Rename failed: $err');
      }
    }
  }

  Future<void> _delete(List<FileSystemEntity> items) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${items.length} item(s)?'),
        content: const Text('This cannot be undone from within the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final e in items) {
        try {
          await e.delete(recursive: e is Directory);
        } catch (err) {
          _showError('Could not delete ${pathFileName(e.path)}');
        }
      }
      setState(() => _selected.clear());
      _open(_current!, pushHistory: false);
    }
  }

  void _copy(FileSystemEntity e) => setState(() {
        _clipboardPath = e.path;
        _clipboardCut = false;
      });

  void _cut(FileSystemEntity e) => setState(() {
        _clipboardPath = e.path;
        _clipboardCut = true;
      });

  Future<void> _paste() async {
    if (_clipboardPath == null || _current == null) return;
    final name = pathFileName(_clipboardPath!);
    final destPath = '${_current!.path}${Platform.pathSeparator}$name';
    try {
      final srcFile = File(_clipboardPath!);
      if (await srcFile.exists()) {
        await srcFile.copy(destPath);
        if (_clipboardCut) await srcFile.delete();
      } else {
        final srcDir = Directory(_clipboardPath!);
        await _copyDirRecursive(srcDir, Directory(destPath));
        if (_clipboardCut) await srcDir.delete(recursive: true);
      }
      setState(() => _clipboardPath = null);
      _open(_current!, pushHistory: false);
    } catch (err) {
      _showError('Paste failed: $err');
    }
  }

  Future<void> _copyDirRecursive(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in src.list()) {
      final newPath = '${dest.path}${Platform.pathSeparator}${pathFileName(entity.path)}';
      if (entity is Directory) {
        await _copyDirRecursive(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Future<void> _newFolder() async {
    final ctrl = TextEditingController(text: 'New Folder');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create folder'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && _current != null) {
      try {
        await Directory('${_current!.path}${Platform.pathSeparator}$name').create();
        _open(_current!, pushHistory: false);
      } catch (err) {
        _showError('Could not create folder: $err');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  void _showProperties(FileSystemEntity e) {
    final stat = e.statSync();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(pathFileName(e.path)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${e is Directory ? 'Folder' : 'File'}'),
            if (e is File) Text('Size: ${humanSize(stat.size)}'),
            Text('Modified: ${stat.modified}'),
            Text('Created: ${stat.changed}'),
            const SizedBox(height: 8),
            Text('Location:\n${e.path}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showContextMenu(Offset position, FileSystemEntity e) async {
    final fav = FilesStateService.isFavorite(e.path);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: AppColors.cardElevated,
      items: [
        const PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(value: 'fav', child: Text(fav ? 'Remove from Favorites' : 'Add to Favorites')),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        const PopupMenuItem(value: 'cut', child: Text('Cut')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
        const PopupMenuItem(value: 'props', child: Text('Properties')),
      ],
    );
    switch (action) {
      case 'open':
        if (e is Directory) _open(e);
        break;
      case 'fav':
        FilesStateService.toggleFavorite(e.path);
        setState(() {});
        break;
      case 'rename':
        _rename(e);
        break;
      case 'copy':
        _copy(e);
        break;
      case 'cut':
        _cut(e);
        break;
      case 'delete':
        _delete([e]);
        break;
      case 'props':
        _showProperties(e);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
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
              const Spacer(),
              if (_selected.isNotEmpty) ...[
                Text('${_selected.length} selected', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _delete(_entries.where((e) => _selected.contains(e.path)).toList())),
              ],
              if (_clipboardPath != null) IconButton(icon: const Icon(Icons.paste, size: 18), tooltip: 'Paste', onPressed: _paste),
              IconButton(icon: const Icon(Icons.create_new_folder_outlined, size: 18), tooltip: 'New folder', onPressed: _newFolder),
              IconButton(icon: Icon(_grid ? LucideIcons.list : LucideIcons.layoutGrid, size: 18), onPressed: () => setState(() => _grid = !_grid)),
              PopupMenuButton<_SortBy>(
                icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _SortBy.name, child: Text('Sort: Name')),
                  PopupMenuItem(value: _SortBy.date, child: Text('Sort: Date')),
                  PopupMenuItem(value: _SortBy.size, child: Text('Sort: Size')),
                  PopupMenuItem(value: _SortBy.type, child: Text('Sort: Type')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, size: 16), onPressed: _history.isNotEmpty ? _back : null),
              IconButton(icon: const Icon(Icons.arrow_upward, size: 16), onPressed: _up),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _breadcrumbSegments.asMap().entries.map((entry) {
                      return Row(
                        children: [
                          if (entry.key > 0) const Text(' / ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          InkWell(
                            onTap: () => _goToBreadcrumb(entry.key),
                            child: Text(entry.value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(isDense: true, hintText: 'Search files...', prefixIcon: Icon(Icons.search, size: 18)),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textMuted)))
                  : list.isEmpty
                      ? const Center(child: Text('This folder is empty', style: TextStyle(color: AppColors.textMuted)))
                      : _grid
                          ? _buildGrid(list)
                          : _buildList(list),
        ),
      ],
    );
  }

  Widget _buildList(List<FileSystemEntity> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        final name = pathFileName(e.path);
        final selected = _selected.contains(e.path);
        final fav = FilesStateService.isFavorite(e.path);
        final stat = e.statSync();
        return GestureDetector(
          onSecondaryTapDown: (d) => _showContextMenu(d.globalPosition, e),
          child: Material(
            color: selected ? AppColors.accentMuted : Colors.transparent,
            child: ListTile(
              dense: true,
              leading: Icon(_iconFor(e), size: 18, color: e is Directory ? AppColors.accent : AppColors.textSecondary),
              title: Text(name, style: const TextStyle(fontSize: 13)),
              subtitle: e is File ? Text('${humanSize(stat.size)} · ${stat.modified.toString().split(' ').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
              trailing: fav ? const Icon(Icons.star, size: 14, color: AppColors.accent) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
              onTap: () {
                if (e is Directory) {
                  _open(e);
                } else {
                  FilesStateService.recordOpened(e.path);
                }
              },
              onLongPress: () => setState(() => selected ? _selected.remove(e.path) : _selected.add(e.path)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<FileSystemEntity> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        final name = pathFileName(e.path);
        final selected = _selected.contains(e.path);
        final fav = FilesStateService.isFavorite(e.path);
        return GestureDetector(
          onSecondaryTapDown: (d) => _showContextMenu(d.globalPosition, e),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            onTap: () {
              if (e is Directory) {
                _open(e);
              } else {
                FilesStateService.recordOpened(e.path);
              }
            },
            onLongPress: () => setState(() => selected ? _selected.remove(e.path) : _selected.add(e.path)),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppColors.accentMuted : AppColors.card,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(_iconFor(e), size: 30, color: e is Directory ? AppColors.accent : AppColors.textSecondary),
                      if (fav) const Positioned(top: -20, right: -30, child: Icon(Icons.star, size: 12, color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(name, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
