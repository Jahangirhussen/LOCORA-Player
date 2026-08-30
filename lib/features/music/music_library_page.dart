import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../core/file_scanner.dart';
import 'music_index.dart';
import 'music_models.dart';
import 'music_player_controller.dart';

enum _Tab { all, artists, albums, folders, recent, favorites, playlists }
enum _SortBy { name, artist, album, date, duration }

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  List<SongEntry> _all = [];
  bool _scanning = false;
  bool _grid = true;
  _Tab _tab = _Tab.all;
  _SortBy _sort = _SortBy.name;
  String _query = '';
  String? _drillKey; // selected artist/album/folder/playlist name

  @override
  void initState() {
    super.initState();
    _all = MusicIndexService.cached();
    if (_all.isEmpty) _rescan();
  }

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    final found = await MusicIndexService.rescan();
    if (!mounted) return;
    setState(() {
      _all = found;
      _scanning = false;
    });
  }

  List<SongEntry> get _base {
    switch (_tab) {
      case _Tab.favorites:
        return _all.where((s) => MusicIndexService.isFavorite(s.path)).toList();
      case _Tab.recent:
        final list = _all.where((s) => MusicIndexService.lastPlayed(s.path) != null).toList();
        list.sort((a, b) => MusicIndexService.lastPlayed(b.path)!.compareTo(MusicIndexService.lastPlayed(a.path)!));
        return list;
      case _Tab.artists:
        if (_drillKey != null) return _all.where((s) => s.artist == _drillKey).toList();
        return _all;
      case _Tab.albums:
        if (_drillKey != null) return _all.where((s) => s.album == _drillKey).toList();
        return _all;
      case _Tab.folders:
        if (_drillKey != null) return _all.where((s) => s.folder == _drillKey).toList();
        return _all;
      case _Tab.playlists:
        if (_drillKey != null) {
          final paths = MusicIndexService.playlists()[_drillKey] ?? [];
          return _all.where((s) => paths.contains(s.path)).toList();
        }
        return _all;
      case _Tab.all:
        return _all;
    }
  }

  List<SongEntry> get _filtered {
    var list = _base;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q) || s.album.toLowerCase().contains(q)).toList();
    }
    list = [...list];
    switch (_sort) {
      case _SortBy.name:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortBy.artist:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case _SortBy.album:
        list.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
        break;
      case _SortBy.date:
        list.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case _SortBy.duration:
        list.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }
    return list;
  }

  List<String> get _groupKeys {
    final set = <String>{};
    for (final s in _all) {
      if (_tab == _Tab.artists) set.add(s.artist);
      if (_tab == _Tab.albums) set.add(s.album);
      if (_tab == _Tab.folders) set.add(s.folder);
    }
    if (_tab == _Tab.playlists) return MusicIndexService.playlists().keys.toList()..sort();
    return set.toList()..sort();
  }

  void _play(SongEntry song) {
    final list = _filtered;
    final ctrl = context.read<MusicPlayerController>();
    ctrl.playQueue(list, list.indexOf(song));
    ctrl.player.play();
  }

  bool get _needsGrouping => (_tab == _Tab.artists || _tab == _Tab.albums || _tab == _Tab.folders || _tab == _Tab.playlists) && _drillKey == null;

  Future<void> _newPlaylist() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Playlist name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final all = MusicIndexService.playlists();
      all.putIfAbsent(name, () => []);
      MusicIndexService.savePlaylists(all);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Padding(padding: EdgeInsets.only(right: 10), child: Text('Music', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              _TabChip(label: 'All Songs', selected: _tab == _Tab.all, onTap: () => setState(() { _tab = _Tab.all; _drillKey = null; })),
              _TabChip(label: 'Artists', selected: _tab == _Tab.artists, onTap: () => setState(() { _tab = _Tab.artists; _drillKey = null; })),
              _TabChip(label: 'Albums', selected: _tab == _Tab.albums, onTap: () => setState(() { _tab = _Tab.albums; _drillKey = null; })),
              _TabChip(label: 'Folders', selected: _tab == _Tab.folders, onTap: () => setState(() { _tab = _Tab.folders; _drillKey = null; })),
              _TabChip(label: 'Recent', selected: _tab == _Tab.recent, onTap: () => setState(() { _tab = _Tab.recent; _drillKey = null; })),
              _TabChip(label: 'Favorites', selected: _tab == _Tab.favorites, onTap: () => setState(() { _tab = _Tab.favorites; _drillKey = null; })),
              _TabChip(label: 'Playlists', selected: _tab == _Tab.playlists, onTap: () => setState(() { _tab = _Tab.playlists; _drillKey = null; })),
              const Spacer(),
              if (_tab == _Tab.playlists && _drillKey == null)
                IconButton(icon: const Icon(Icons.add, size: 18), tooltip: 'New playlist', onPressed: _newPlaylist),
              IconButton(
                tooltip: 'Rescan library',
                icon: _scanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _scanning ? null : _rescan,
              ),
              IconButton(icon: Icon(_grid ? LucideIcons.list : LucideIcons.layoutGrid, size: 18), onPressed: () => setState(() => _grid = !_grid)),
              PopupMenuButton<_SortBy>(
                icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _SortBy.name, child: Text('Sort: Name')),
                  PopupMenuItem(value: _SortBy.artist, child: Text('Sort: Artist')),
                  PopupMenuItem(value: _SortBy.album, child: Text('Sort: Album')),
                  PopupMenuItem(value: _SortBy.date, child: Text('Sort: Date added')),
                  PopupMenuItem(value: _SortBy.duration, child: Text('Sort: Duration')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: const InputDecoration(isDense: true, hintText: 'Search songs, artists, albums...', prefixIcon: Icon(Icons.search, size: 18)),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        if (_drillKey != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, size: 16), onPressed: () => setState(() => _drillKey = null)),
                Expanded(child: Text(_drillKey!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        Expanded(
          child: _all.isEmpty && _scanning
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _needsGrouping
                  ? _GroupList(keys: _groupKeys, onOpen: (k) => setState(() => _drillKey = k))
                  : _filtered.isEmpty
                      ? const Center(child: Text('No songs found', style: TextStyle(color: AppColors.textMuted)))
                      : _grid
                          ? _SongGrid(items: _filtered, onOpen: _play)
                          : _SongList(items: _filtered, onOpen: _play),
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
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentMuted,
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<String> keys;
  final void Function(String) onOpen;
  const _GroupList({required this.keys, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) return const Center(child: Text('Nothing here yet', style: TextStyle(color: AppColors.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: keys.length,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(LucideIcons.disc3, color: AppColors.accent, size: 18),
        title: Text(keys[i], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
        onTap: () => onOpen(keys[i]),
      ),
    );
  }
}

class _SongGrid extends StatelessWidget {
  final List<SongEntry> items;
  final void Function(SongEntry) onOpen;
  const _SongGrid({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final s = items[i];
        final fav = MusicIndexService.isFavorite(s.path);
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => onOpen(s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: MusicIndexService.coverArt(s.path),
                          builder: (context, snap) {
                            if (snap.data != null) return Image.memory(snap.data!, fit: BoxFit.cover);
                            return const Center(child: Icon(Icons.music_note, size: 30, color: AppColors.textMuted));
                          },
                        ),
                        if (fav) const Positioned(top: 6, right: 6, child: Icon(Icons.favorite, size: 14, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(s.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(s.artist, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

class _SongList extends StatelessWidget {
  final List<SongEntry> items;
  final void Function(SongEntry) onOpen;
  const _SongList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final s = items[i];
        final fav = MusicIndexService.isFavorite(s.path);
        return ListTile(
          dense: true,
          leading: const Icon(Icons.music_note, size: 18, color: AppColors.textSecondary),
          title: Text(s.title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          subtitle: Text('${s.artist} · ${s.album} · ${humanDuration(s.duration)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          trailing: fav ? const Icon(Icons.favorite, size: 16, color: AppColors.accent) : null,
          onTap: () => onOpen(s),
        );
      },
    );
  }
}
