import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

const String tasksBoxName = 'tasks';
enum _Filter { today, upcoming, completed }

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Box _box;
  _Filter _filter = _Filter.today;

  @override
  void initState() {
    super.initState();
    _box = Hive.box(tasksBoxName);
  }

  Future<void> _addTask() async {
    final ctrl = TextEditingController();
    DateTime? due;
    int priority = 1;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: const Text('New task'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Task title')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(due == null ? 'No due date' : due.toString().split(' ').first, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
                        if (picked != null) setSt(() => due = picked);
                      },
                      child: const Text('Pick date'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Priority:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    ...List.generate(3, (i) => ChoiceChip(
                          label: Text(['Low', 'Med', 'High'][i], style: const TextStyle(fontSize: 11)),
                          selected: priority == i,
                          onSelected: (_) => setSt(() => priority = i),
                        )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        );
      }),
    );
    if (result == true && ctrl.text.isNotEmpty) {
      final key = const Uuid().v4();
      _box.put(key, {
        'title': ctrl.text,
        'due': due?.toIso8601String(),
        'priority': priority,
        'completed': false,
        'created': DateTime.now().toIso8601String(),
      });
      setState(() {});
    }
  }

  void _toggle(String key) {
    final t = Map.from(_box.get(key) as Map);
    t['completed'] = !(t['completed'] ?? false);
    _box.put(key, t);
    setState(() {});
  }

  void _delete(String key) {
    _box.delete(key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var keys = _box.keys.cast<String>().toList();

    keys = keys.where((k) {
      final t = _box.get(k) as Map;
      final completed = t['completed'] ?? false;
      if (_filter == _Filter.completed) return completed;
      if (completed) return false;
      final due = t['due'] != null ? DateTime.tryParse(t['due']) : null;
      if (_filter == _Filter.today) {
        return due == null || !DateTime(due.year, due.month, due.day).isAfter(today);
      }
      return due != null && DateTime(due.year, due.month, due.day).isAfter(today);
    }).toList();

    keys.sort((a, b) {
      final ta = _box.get(a) as Map;
      final tb = _box.get(b) as Map;
      return (tb['priority'] ?? 0).compareTo(ta['priority'] ?? 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Text('Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _addTask, icon: const Icon(Icons.add, size: 16), label: const Text('New task')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ChoiceChip(label: const Text('Today'), selected: _filter == _Filter.today, onSelected: (_) => setState(() => _filter = _Filter.today)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Upcoming'), selected: _filter == _Filter.upcoming, onSelected: (_) => setState(() => _filter = _Filter.upcoming)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Completed'), selected: _filter == _Filter.completed, onSelected: (_) => setState(() => _filter = _Filter.completed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: keys.isEmpty
              ? const Center(child: Text('No tasks here', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: keys.length,
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final t = _box.get(key) as Map;
                    final completed = t['completed'] ?? false;
                    final priority = t['priority'] ?? 0;
                    final due = t['due'] != null ? DateTime.tryParse(t['due']) : null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppColors.border)),
                      child: CheckboxListTile(
                        value: completed,
                        onChanged: (_) => _toggle(key),
                        activeColor: AppColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(t['title'] ?? '', style: TextStyle(fontSize: 14, decoration: completed ? TextDecoration.lineThrough : null, color: completed ? AppColors.textMuted : AppColors.textPrimary)),
                        subtitle: due != null ? Text(due.toString().split(' ').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (priority == 2) const Icon(Icons.flag, size: 14, color: AppColors.danger),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted), onPressed: () => _delete(key)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
