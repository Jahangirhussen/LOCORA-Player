import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'video_index.dart';
import 'video_models.dart';
import 'video_player_page.dart';

enum _VideoTab { all, folders, recent, favorites }

enum _SortBy { name, date, size }

class VideoLibraryPage extends StatefulWidget {
  const VideoLibraryPage({super.key});

  @override
  State<VideoLibraryPage> createState() => _VideoLibraryPageState();
}

class _VideoLibraryPageState extends State<VideoLibraryPage> {
  List<VideoEntry> _all = [];
  bool _scanning = false;
  bool _grid = true;
  _VideoTab _tab = _VideoTab.all;
  _SortBy _sort = _SortBy.name;
  String _query = '';
  String? _folder;

  @override
  void initState() {
    super.initState();
    _all = VideoIndexService.cached();
    if (_all.isEmpty) _rescan();
  }

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    final found = await VideoIndexService.rescan();
    if (!mounted) return;
    setState(() {
      _all = found;
      _scanning = false;
    });
  }

  List<VideoEntry> get _filtered {
    var list = _all;
    if (_tab == _VideoTab.favorites) {
      list = list.where((v) => VideoIndexService.isFavorite(v.path)).toList();
    } else if (_tab == _VideoTab.recent) {
      list = list.where((v) => VideoIndexService.lastPlayed(v.path) != null).toList()
        ..sort((a, b) => VideoIndexService.lastPlayed(b.path)!.compareTo(VideoIndexService.lastPlayed(a.path)!));
      return list;
    } else if (_tab == _VideoTab.folders && _folder != null) {
      list = list.where((v) => v.folder == _folder).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((v) => v.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    list = [...list];
    switch (_sort) {
      case _SortBy.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortBy.date:
        list.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case _SortBy.size:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    return list;
  }

  List<String> get _folders {
    final set = <String>{};
    for (final v in _all) {
      set.add(v.folder);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _open(VideoEntry v) {
    VideoIndexService.recordPlayed(v.path);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerPage(entry: v)));
  }

  @override
  Widget build(BuildContext context) {
    final showFolderList = _tab == _VideoTab.folders && _folder == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Padding(padding: EdgeInsets.only(right: 10), child: Text('Videos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              _TabChip(label: 'All Videos', selected: _tab == _VideoTab.all, onTap: () => setState(() { _tab = _VideoTab.all; _folder = null; })),
              _TabChip(label: 'Folders', selected: _tab == _VideoTab.folders, onTap: () => setState(() { _tab = _VideoTab.folders; _folder = null; })),
              _TabChip(label: 'Recent', selected: _tab == _VideoTab.recent, onTap: () => setState(() { _tab = _VideoTab.recent; _folder = null; })),
              _TabChip(label: 'Favorites', selected: _tab == _VideoTab.favorites, onTap: () => setState(() { _tab = _VideoTab.favorites; _folder = null; })),
              IconButton(
                tooltip: 'Rescan library',
                icon: _scanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _scanning ? null : _rescan,
              ),
              IconButton(
                icon: Icon(_grid ? LucideIcons.list : LucideIcons.layoutGrid, size: 18),
                onPressed: () => setState(() => _grid = !_grid),
              ),
              PopupMenuButton<_SortBy>(
                icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _SortBy.name, child: Text('Sort: Name')),
                  PopupMenuItem(value: _SortBy.date, child: Text('Sort: Date')),
                  PopupMenuItem(value: _SortBy.size, child: Text('Sort: Size')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: const InputDecoration(isDense: true, hintText: 'Search videos...', prefixIcon: Icon(Icons.search, size: 18)),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        if (_folder != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, size: 16), onPressed: () => setState(() => _folder = null)),
                Expanded(child: Text(_folder!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        Expanded(
          child: _all.isEmpty && _scanning
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : showFolderList
                  ? _FolderList(folders: _folders, all: _all, onOpen: (f) => setState(() => _folder = f))
                  : _filtered.isEmpty
                      ? const Center(child: Text('No videos found', style: TextStyle(color: AppColors.textMuted)))
                      : _grid
                          ? _VideoGrid(items: _filtered, onOpen: _open)
                          : _VideoList(items: _filtered, onOpen: _open),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.accentMuted,
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _FolderList extends StatelessWidget {
  final List<String> folders;
  final List<VideoEntry> all;
  final void Function(String) onOpen;
  const _FolderList({required this.folders, required this.all, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: folders.length,
      itemBuilder: (context, i) {
        final f = folders[i];
        final count = all.where((v) => v.folder == f).length;
        return ListTile(
          leading: const Icon(LucideIcons.folder, color: AppColors.accent, size: 18),
          title: Text(f, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          subtitle: Text('$count videos', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          onTap: () => onOpen(f),
        );
      },
    );
  }
}

class _VideoGrid extends StatelessWidget {
  final List<VideoEntry> items;
  final void Function(VideoEntry) onOpen;
  const _VideoGrid({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final v = items[i];
        final fav = VideoIndexService.isFavorite(v.path);
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => onOpen(v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      const Center(child: Icon(LucideIcons.clapperboard, size: 24, color: AppColors.textMuted)),
                      if (fav)
                        const Positioned(top: 5, right: 5, child: Icon(Icons.star, size: 14, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(v.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(humanSize(v.sizeBytes), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        );
      },
    );
  }
}

class _VideoList extends StatelessWidget {
  final List<VideoEntry> items;
  final void Function(VideoEntry) onOpen;
  const _VideoList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final v = items[i];
        final fav = VideoIndexService.isFavorite(v.path);
        return ListTile(
          dense: true,
          leading: const Icon(LucideIcons.clapperboard, size: 18, color: AppColors.textSecondary),
          title: Text(v.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          subtitle: Text('${humanSize(v.sizeBytes)} · ${v.modified.toString().split(' ').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          trailing: fav ? const Icon(Icons.star, size: 16, color: AppColors.accent) : null,
          onTap: () => onOpen(v),
        );
      },
    );
  }
}
