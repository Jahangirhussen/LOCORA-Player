import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class TimerStopwatchPage extends StatefulWidget {
  const TimerStopwatchPage({super.key});

  @override
  State<TimerStopwatchPage> createState() => _TimerStopwatchPageState();
}

class _TimerStopwatchPageState extends State<TimerStopwatchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Text('Timer & Stopwatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Timer'), Tab(text: 'Stopwatch')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_TimerTab(), _StopwatchTab()],
          ),
        ),
      ],
    );
  }
}

class _TimerTab extends StatefulWidget {
  const _TimerTab();

  @override
  State<_TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<_TimerTab> {
  Duration _remaining = const Duration(minutes: 25);
  Duration _initial = const Duration(minutes: 25);
  Timer? _ticker;
  bool _running = false;

  static const _presets = [1, 5, 10, 15, 25, 45, 60];

  void _start() {
    if (_remaining.inSeconds <= 0) return;
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.inSeconds <= 1) {
        t.cancel();
        setState(() {
          _remaining = Duration.zero;
          _running = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timer completed')));
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _remaining = _initial;
      _running = false;
    });
  }

  void _setPreset(int minutes) {
    _ticker?.cancel();
    setState(() {
      _initial = Duration(minutes: minutes);
      _remaining = _initial;
      _running = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final text = h > 0 ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: _presets.map((p) => ActionChip(label: Text('${p}m'), onPressed: () => _setPreset(p))).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _running ? _pause : _start,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh), label: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopwatchTab extends StatefulWidget {
  const _StopwatchTab();

  @override
  State<_StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<_StopwatchTab> {
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = [];

  void _startPause() {
    if (_sw.isRunning) {
      _sw.stop();
      _ticker?.cancel();
    } else {
      _sw.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) => setState(() {}));
    }
    setState(() {});
  }

  void _reset() {
    _sw.stop();
    _sw.reset();
    _ticker?.cancel();
    setState(() => _laps.clear());
  }

  void _lap() {
    setState(() => _laps.insert(0, _sw.elapsed));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final ms = (d.inMilliseconds % 1000) ~/ 10;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(_fmt(_sw.elapsed), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(onPressed: _startPause, icon: Icon(_sw.isRunning ? Icons.pause : Icons.play_arrow), label: Text(_sw.isRunning ? 'Pause' : 'Start')),
            const SizedBox(width: 12),
            OutlinedButton.icon(onPressed: _sw.isRunning ? _lap : _reset, icon: Icon(_sw.isRunning ? Icons.flag : Icons.refresh), label: Text(_sw.isRunning ? 'Lap' : 'Reset')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: _laps.length,
            itemBuilder: (context, i) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lap ${_laps.length - i}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(_fmt(_laps[i]), style: const TextStyle(fontSize: 13, fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
