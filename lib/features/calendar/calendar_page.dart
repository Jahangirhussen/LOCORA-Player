import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

const String calendarBoxName = 'calendar_events';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Box _box;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _box = Hive.box(calendarBoxName);
  }

  List<Map> _eventsOn(DateTime day) {
    return _box.keys.map((k) => Map.from(_box.get(k) as Map)..['key'] = k).where((e) {
      final d = DateTime.parse(e['date']);
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList()
      ..sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
  }

  Future<void> _addEvent(DateTime day) async {
    final titleCtrl = TextEditingController();
    TimeOfDay? time;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setSt) {
        return AlertDialog(
          title: Text('New event · ${day.toString().split(' ').first}'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Event title')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text(time == null ? 'No time' : time!.format(context), style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setSt(() => time = picked);
                      },
                      child: const Text('Pick time'),
                    ),
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
    if (result == true && titleCtrl.text.isNotEmpty) {
      _box.put(const Uuid().v4(), {
        'title': titleCtrl.text,
        'date': day.toIso8601String(),
        'time': time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' : '',
      });
      setState(() {});
    }
  }

  void _deleteEvent(String key) {
    _box.delete(key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7; // 0=Sun
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Text('Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
              Text('${_monthName(_month.month)} ${_month.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;
            final calendarGrid = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))))).toList(),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
                          itemCount: startWeekday + daysInMonth,
                          itemBuilder: (context, i) {
                            if (i < startWeekday) return const SizedBox();
                            final day = DateTime(_month.year, _month.month, i - startWeekday + 1);
                            final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                            final isSelected = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;
                            final hasEvents = _eventsOn(day).isNotEmpty;
                            return InkWell(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                              onTap: () => setState(() => _selectedDay = day),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accentMuted : (isToday ? AppColors.card : null),
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                  border: Border.all(color: isToday ? AppColors.accent : Colors.transparent),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text('${day.day}', style: const TextStyle(fontSize: 13)),
                                    if (hasEvents) const Positioned(bottom: 4, child: Icon(Icons.circle, size: 4, color: AppColors.accent)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );

            final eventList = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: narrow ? MainAxisSize.min : MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: Text(_selectedDay.toString().split(' ').first, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          IconButton(icon: const Icon(Icons.add, size: 18, color: AppColors.accent), onPressed: () => _addEvent(_selectedDay)),
                        ],
                      ),
                    ),
                    if (narrow)
                      Column(
                        children: _eventsOn(_selectedDay)
                            .map((e) => ListTile(
                                  dense: true,
                                  title: Text(e['title'], style: const TextStyle(fontSize: 13)),
                                  subtitle: (e['time'] as String).isNotEmpty ? Text(e['time'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                                  trailing: IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => _deleteEvent(e['key'])),
                                ))
                            .toList(),
                      )
                    else
                      Expanded(
                        child: ListView(
                          children: _eventsOn(_selectedDay)
                              .map((e) => ListTile(
                                    dense: true,
                                    title: Text(e['title'], style: const TextStyle(fontSize: 13)),
                                    subtitle: (e['time'] as String).isNotEmpty ? Text(e['time'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                                    trailing: IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => _deleteEvent(e['key'])),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                );

            if (narrow) {
              return ListView(
                children: [
                  SizedBox(height: 380, child: calendarGrid),
                  const Divider(height: 1),
                  eventList,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: calendarGrid),
                SizedBox(width: 260, child: eventList),
              ],
            );
          }),
        ),
      ],
    );
  }

  String _monthName(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
}
