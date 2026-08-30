import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../core/file_scanner.dart';
import 'pdf_index.dart';
import 'pdf_models.dart';
import 'pdf_viewer_page.dart';

enum _Tab { all, folders, recent, favorites }
enum _SortBy { name, date, size }

class PdfLibraryPage extends StatefulWidget {
  const PdfLibraryPage({super.key});

  @override
  State<PdfLibraryPage> createState() => _PdfLibraryPageState();
}

class _PdfLibraryPageState extends State<PdfLibraryPage> {
  List<PdfEntry> _all = [];
  bool _scanning = false;
  _Tab _tab = _Tab.all;
  _SortBy _sort = _SortBy.name;
  String _query = '';
  String? _folder;

  @override
  void initState() {
    super.initState();
    _all = PdfIndexService.cached();
    if (_all.isEmpty) _rescan();
  }

  Future<void> _rescan() async {
    setState(() => _scanning = true);
    final found = await PdfIndexService.rescan();
    if (!mounted) return;
    setState(() {
      _all = found;
      _scanning = false;
    });
  }

  List<PdfEntry> get _filtered {
    var list = _all;
    if (_tab == _Tab.favorites) {
      list = list.where((p) => PdfIndexService.isFavorite(p.path)).toList();
    } else if (_tab == _Tab.recent) {
      list = list.where((p) => PdfIndexService.lastOpened(p.path) != null).toList()
        ..sort((a, b) => PdfIndexService.lastOpened(b.path)!.compareTo(PdfIndexService.lastOpened(a.path)!));
      return list;
    } else if (_tab == _Tab.folders && _folder != null) {
      list = list.where((p) => p.folder == _folder).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
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
    for (final p in _all) {
      set.add(p.folder);
    }
    return set.toList()..sort();
  }

  void _open(PdfEntry p) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerPage(entry: p)));
  }

  @override
  Widget build(BuildContext context) {
    final showFolderList = _tab == _Tab.folders && _folder == null;
    final list = _filtered;

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
              const Padding(padding: EdgeInsets.only(right: 10), child: Text('PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              _TabChip(label: 'All PDFs', selected: _tab == _Tab.all, onTap: () => setState(() { _tab = _Tab.all; _folder = null; })),
              _TabChip(label: 'Folders', selected: _tab == _Tab.folders, onTap: () => setState(() { _tab = _Tab.folders; _folder = null; })),
              _TabChip(label: 'Continue Reading', selected: _tab == _Tab.recent, onTap: () => setState(() { _tab = _Tab.recent; _folder = null; })),
              _TabChip(label: 'Favorites', selected: _tab == _Tab.favorites, onTap: () => setState(() { _tab = _Tab.favorites; _folder = null; })),
              IconButton(
                tooltip: 'Rescan library',
                icon: _scanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _scanning ? null : _rescan,
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
            decoration: const InputDecoration(isDense: true, hintText: 'Search PDFs...', prefixIcon: Icon(Icons.search, size: 18)),
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
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _folders.length,
                      itemBuilder: (context, i) {
                        final f = _folders[i];
                        final count = _all.where((p) => p.folder == f).length;
                        return ListTile(
                          leading: const Icon(LucideIcons.folder, color: AppColors.accent, size: 18),
                          title: Text(f, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          subtitle: Text('$count PDFs', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          onTap: () => setState(() => _folder = f),
                        );
                      },
                    )
                  : list.isEmpty
                      ? const Center(child: Text('No PDFs found', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final p = list[i];
                            final fav = PdfIndexService.isFavorite(p.path);
                            return ListTile(
                              dense: true,
                              leading: const Icon(LucideIcons.file, size: 18, color: AppColors.textSecondary),
                              title: Text(p.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                              subtitle: Text('${humanSize(p.sizeBytes)} · ${p.modified.toString().split(' ').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              trailing: fav ? const Icon(Icons.star, size: 16, color: AppColors.accent) : null,
                              onTap: () => _open(p),
                            );
                          },
                        ),
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
