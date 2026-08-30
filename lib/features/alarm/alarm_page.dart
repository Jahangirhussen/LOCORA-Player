import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

const String alarmsBoxName = 'alarms';
const List<String> weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late Box _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box(alarmsBoxName);
  }

  Future<void> _addOrEdit({String? key}) async {
    final existing = key != null ? _box.get(key) as Map : null;
    TimeOfDay time = existing != null
        ? TimeOfDay(hour: existing['hour'], minute: existing['minute'])
        : TimeOfDay.now();
    String label = existing?['label'] ?? 'Alarm';
    List<bool> days = existing != null ? List<bool>.from(existing['days']) : List.filled(7, false);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final labelCtrl = TextEditingController(text: label);
        return StatefulBuilder(builder: (context, setSt) {
          return AlertDialog(
            title: Text(key == null ? 'New alarm' : 'Edit alarm'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(time.format(context), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.edit, size: 16),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: time);
                      if (picked != null) setSt(() => time = picked);
                    },
                  ),
                  TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      return FilterChip(
                        label: Text(weekdayLabels[i]),
                        selected: days[i],
                        onSelected: (v) => setSt(() => days[i] = v),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  label = labelCtrl.text;
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (result == true) {
      final k = key ?? const Uuid().v4();
      _box.put(k, {
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
        'days': days,
        'enabled': existing?['enabled'] ?? true,
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _box.keys.cast<String>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text('Alarm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _addOrEdit(), icon: const Icon(Icons.add, size: 16), label: const Text('New alarm')),
            ],
          ),
        ),
        Expanded(
          child: keys.isEmpty
              ? const Center(child: Text('No alarms yet', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: keys.length,
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final a = _box.get(key) as Map;
                    final days = List<bool>.from(a['days']);
                    final repeatLabel = days.every((d) => !d)
                        ? 'Once'
                        : days.every((d) => d)
                            ? 'Every day'
                            : List.generate(7, (j) => days[j] ? weekdayLabels[j] : null).whereType<String>().join(' ');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _addOrEdit(key: key),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a['hour'].toString().padLeft(2, '0')}:${a['minute'].toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                                  ),
                                  Text('${a['label']} · $repeatLabel', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                          Switch(
                            value: a['enabled'] ?? true,
                            activeThumbColor: AppColors.accent,
                            onChanged: (v) {
                              _box.put(key, {...a, 'enabled': v});
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _box.delete(key);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
