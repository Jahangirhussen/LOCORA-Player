import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';

const String notesBoxName = 'notes';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Box _box;
  String? _selectedKey;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _box = Hive.box(notesBoxName);
  }

  void _newNote() {
    final key = const Uuid().v4();
    _box.put(key, {
      'title': 'Untitled',
      'body': '',
      'updated': DateTime.now().toIso8601String(),
    });
    setState(() => _selectedKey = key);
    _titleCtrl.text = 'Untitled';
    _bodyCtrl.text = '';
  }

  void _select(String key) {
    final note = _box.get(key) as Map;
    setState(() => _selectedKey = key);
    _titleCtrl.text = note['title'] ?? '';
    _bodyCtrl.text = note['body'] ?? '';
  }

  void _save() {
    if (_selectedKey == null) return;
    _box.put(_selectedKey, {
      'title': _titleCtrl.text.isEmpty ? 'Untitled' : _titleCtrl.text,
      'body': _bodyCtrl.text,
      'updated': DateTime.now().toIso8601String(),
    });
    setState(() {});
  }

  void _delete(String key) {
    _box.delete(key);
    if (_selectedKey == key) {
      setState(() {
        _selectedKey = null;
        _titleCtrl.clear();
        _bodyCtrl.clear();
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _box.keys.cast<String>().toList()
      ..sort((a, b) {
        final ua = (_box.get(a) as Map)['updated'] as String;
        final ub = (_box.get(b) as Map)['updated'] as String;
        return ub.compareTo(ua);
      });

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.accent),
                      onPressed: _newNote,
                      tooltip: 'New note',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: keys.length,
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final note = _box.get(key) as Map;
                    final selected = key == _selectedKey;
                    return Material(
                      color: selected ? AppColors.accentMuted : Colors.transparent,
                      child: ListTile(
                        dense: true,
                        title: Text(note['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(_relTime(note['updated']), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        onTap: () => _select(key),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                          onPressed: () => _delete(key),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedKey == null
              ? const Center(child: Text('Select or create a note', style: TextStyle(color: AppColors.textMuted)))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: 'Title'),
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
                ),
        ),
      ],
    );
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
