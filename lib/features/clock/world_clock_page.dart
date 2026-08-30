import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Uses the `timezone` package's bundled IANA database — fully offline,
/// no network lookups for timezone conversion.
class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  List<String> _cities = ['UTC', 'America/New_York', 'Europe/London', 'Asia/Dhaka', 'Asia/Tokyo'];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _ready = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _addCity() async {
    final all = tz.timeZoneDatabase.locations.keys.toList()..sort();
    String query = '';
    final picked = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSt) {
          final filtered = all.where((z) => z.toLowerCase().contains(query.toLowerCase())).take(50).toList();
          return AlertDialog(
            title: const Text('Add city / timezone'),
            content: SizedBox(
              width: 360,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search timezone...'),
                    onChanged: (v) => setSt(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (c, i) => ListTile(
                        dense: true,
                        title: Text(filtered[i], style: const TextStyle(fontSize: 13)),
                        onTap: () => Navigator.pop(context, filtered[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (picked != null && !_cities.contains(picked)) {
      setState(() => _cities.add(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text('World Clock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addCity,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add city'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _cities.length,
            itemBuilder: (context, i) {
              final name = _cities[i];
              tz.TZDateTime? time;
              try {
                time = tz.TZDateTime.from(_now, tz.getLocation(name));
              } catch (_) {}
              final isNight = time != null && (time.hour < 6 || time.hour >= 19);
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
                    Icon(isNight ? Icons.nightlight_round : Icons.wb_sunny_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (time != null)
                            Text('${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (time != null)
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                      onPressed: () => setState(() => _cities.removeAt(i)),
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
