import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';

const String notesBoxName = 'notes';
const String notesTrashBoxName = 'notes_trash';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Box _box;
  late Box _trash;
  String? _selectedKey;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _query = '';
  bool _showTrash = false;

  @override
  void initState() {
    super.initState();
    _box = Hive.box(notesBoxName);
    _trash = Hive.box(notesTrashBoxName);
  }

  void _newNote() {
    final key = const Uuid().v4();
    _box.put(key, {
      'title': 'Untitled',
      'body': '',
      'tags': '',
      'pinned': false,
      'favorite': false,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    });
    _select(key);
  }

  void _select(String key) {
    final note = _box.get(key) as Map;
    setState(() => _selectedKey = key);
    _titleCtrl.text = note['title'] ?? '';
    _bodyCtrl.text = note['body'] ?? '';
    _tagsCtrl.text = note['tags'] ?? '';
  }

  void _save() {
    if (_selectedKey == null) return;
    final existing = _box.get(_selectedKey) as Map;
    _box.put(_selectedKey, {
      ...existing,
      'title': _titleCtrl.text.isEmpty ? 'Untitled' : _titleCtrl.text,
      'body': _bodyCtrl.text,
      'tags': _tagsCtrl.text,
      'updated': DateTime.now().toIso8601String(),
    });
    setState(() {});
  }

  void _togglePin(String key) {
    final note = Map.from(_box.get(key) as Map);
    note['pinned'] = !(note['pinned'] ?? false);
    _box.put(key, note);
    setState(() {});
  }

  void _toggleFavorite(String key) {
    final note = Map.from(_box.get(key) as Map);
    note['favorite'] = !(note['favorite'] ?? false);
    _box.put(key, note);
    setState(() {});
  }

  void _moveToTrash(String key) {
    _trash.put(key, _box.get(key));
    _box.delete(key);
    if (_selectedKey == key) {
      setState(() {
        _selectedKey = null;
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _tagsCtrl.clear();
      });
    } else {
      setState(() {});
    }
  }

  void _restore(String key) {
    _box.put(key, _trash.get(key));
    _trash.delete(key);
    setState(() {});
  }

  void _deleteForever(String key) {
    _trash.delete(key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sourceBox = _showTrash ? _trash : _box;
    var keys = sourceBox.keys.cast<String>().toList();
    if (_query.isNotEmpty && !_showTrash) {
      keys = keys.where((k) {
        final n = _box.get(k) as Map;
        final q = _query.toLowerCase();
        return (n['title'] ?? '').toLowerCase().contains(q) || (n['tags'] ?? '').toLowerCase().contains(q) || (n['body'] ?? '').toLowerCase().contains(q);
      }).toList();
    }
    keys.sort((a, b) {
      final na = sourceBox.get(a) as Map;
      final nb = sourceBox.get(b) as Map;
      if (!_showTrash) {
        final pinA = na['pinned'] ?? false;
        final pinB = nb['pinned'] ?? false;
        if (pinA != pinB) return pinA ? -1 : 1;
      }
      return (nb['updated'] as String).compareTo(na['updated'] as String);
    });

    final listPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(_showTrash ? 'Trash' : 'Notes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(_showTrash ? Icons.notes : Icons.delete_outline, size: 18),
                      tooltip: _showTrash ? 'Back to notes' : 'Trash',
                      onPressed: () => setState(() => _showTrash = !_showTrash),
                    ),
                    if (!_showTrash)
                      IconButton(icon: const Icon(Icons.add, color: AppColors.accent), onPressed: _newNote, tooltip: 'New note'),
                  ],
                ),
              ),
              if (!_showTrash)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: const InputDecoration(isDense: true, hintText: 'Search notes, tags...', prefixIcon: Icon(Icons.search, size: 16)),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: keys.length,
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final note = sourceBox.get(key) as Map;
                    final selected = key == _selectedKey;
                    final pinned = note['pinned'] ?? false;
                    final fav = note['favorite'] ?? false;
                    return Material(
                      color: selected ? AppColors.accentMuted : Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: pinned ? const Icon(Icons.push_pin, size: 14, color: AppColors.accent) : null,
                        title: Text(note['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(_relTime(note['updated']), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        onTap: _showTrash ? null : () => _select(key),
                        trailing: _showTrash
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.restore, size: 16), onPressed: () => _restore(key)),
                                  IconButton(icon: const Icon(Icons.delete_forever, size: 16, color: AppColors.danger), onPressed: () => _deleteForever(key)),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: Icon(fav ? Icons.star : Icons.star_border, size: 16, color: fav ? AppColors.accent : AppColors.textMuted), onPressed: () => _toggleFavorite(key)),
                                  IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted), onPressed: () => _moveToTrash(key)),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );

    final editorPanel = _selectedKey == null || _showTrash
        ? const Center(child: Text('Select or create a note', style: TextStyle(color: AppColors.textMuted)))
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: 'Title'),
                        onChanged: (_) => _save(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.push_pin_outlined), onPressed: () => _togglePin(_selectedKey!)),
                  ],
                ),
                TextField(
                  controller: _tagsCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Tags (comma separated)', isDense: true),
                  onChanged: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _bodyCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Start writing...'),
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
          );

    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 700;
      if (narrow) {
        if (_selectedKey != null && !_showTrash) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, size: 18), onPressed: () => setState(() => _selectedKey = null)),
                    const Text('Back to notes', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Expanded(child: editorPanel),
            ],
          );
        }
        return listPanel;
      }
      return Row(
        children: [
          SizedBox(width: 300, child: listPanel),
          const VerticalDivider(width: 1),
          Expanded(child: editorPanel),
        ],
      );
    });
  }

  String _relTime(String iso) {
    final t = DateTime.tryParse(iso) ?? DateTime.now();
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
