import 'dart:convert';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A single day's mood log

class MoodEntry {
  final String id; // date key: "yyyy-MM-dd"
  final DateTime timestamp;
  final int moodLevel;   // 1–5
  final int energyLevel; // 1–5
  final List<String> factors;
  final String note;

  MoodEntry({
    required this.id,
    required this.timestamp,
    required this.moodLevel,
    required this.energyLevel,
    required this.factors,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'moodLevel': moodLevel,
        'energyLevel': energyLevel,
        'factors': factors,
        'note': note,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        moodLevel: json['moodLevel'] as int,
        energyLevel: (json['energyLevel'] as int?) ?? 3,
        factors: List<String>.from((json['factors'] as List?) ?? []),
        note: (json['note'] as String?) ?? '',
      );
}

// 5-point mood scale — label, emoji, and colour for each level

const List<Map<String, Object>> _moodData = [
  {'label': 'Awful', 'emoji': '😔', 'color': Color(0xFFB71C1C)},
  {'label': 'Bad',   'emoji': '😞', 'color': Color(0xFFE65100)},
  {'label': 'Okay',  'emoji': '😐', 'color': Color(0xFFF9A825)},
  {'label': 'Good',  'emoji': '😊', 'color': Color(0xFF558B2F)},
  {'label': 'Great', 'emoji': '😄', 'color': Color(0xFF1B5E20)},
];

const List<String> _energyLabels = ['Drained', 'Low', 'Neutral', 'Good', 'Energised'];

// Life factors the user can tag — similar to Bearable / Daylio
const List<String> _factors = [
  '😴 Sleep', '🏃 Exercise', '🥗 Nutrition', '👥 Social',
  '💼 Work', '📚 Study', '🧘 Mindfulness', '🌿 Nature',
  '🎵 Music', '🎮 Gaming', '📺 Media', '❤️ Family',
  '💊 Medication', '☀️ Outdoors', '🍷 Alcohol', '😤 Conflict',
];

Color _moodColor(int level) => _moodData[level - 1]['color'] as Color;
String _moodEmoji(int level) => _moodData[level - 1]['emoji'] as String;
String _moodLabel(int level) => _moodData[level - 1]['label'] as String;

// Reads and writes entries from shared_preferences as JSON

const _prefsKey = 'mood_entries_v1';

Future<List<MoodEntry>> _loadEntries() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List;
    return (list.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)).toList())
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  } catch (_) {
    return [];
  }
}

Future<void> _persistEntry(MoodEntry entry, List<MoodEntry> existing) async {
  final prefs = await SharedPreferences.getInstance();
  // One entry per day — overwrite if the user re-logs the same day
  final updated = [entry, ...existing.where((e) => e.id != entry.id)];
  await prefs.setString(_prefsKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
}

// Shared utility functions

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

int _calcStreak(List<MoodEntry> entries) {
  if (entries.isEmpty) return 0;
  final byDay = {for (final e in entries) e.id: true};
  var streak = 0;
  var day = DateTime.now();
  while (byDay.containsKey(_dateKey(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

// The main mood tracker screen

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  List<MoodEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _loadEntries();
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  MoodEntry? get _todayEntry {
    final key = _dateKey(DateTime.now());
    try {
      return _entries.firstWhere((e) => e.id == key);
    } catch (_) {
      return null;
    }
  }

  int get _averageMoodLevel {
    if (_entries.isEmpty) return 3;
    return (_entries.fold(0, (s, e) => s + e.moodLevel) / _entries.length)
        .round()
        .clamp(1, 5);
  }

  void _openLogSheet([MoodEntry? prefill]) async {
    final result = await showModalBottomSheet<MoodEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogMoodSheet(prefill: prefill),
    );
    if (result != null) {
      await _persistEntry(result, _entries);
      _load();
    }
  }

  // Shows today's logged mood, or a prompt if nothing's been logged yet
  Widget _buildTodayCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = _todayEntry;

    if (today == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling today?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text("You haven't logged your mood yet.",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_reaction_rounded),
                label: const Text("Log Today's Mood"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openLogSheet(today),
      child: _Card(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _moodColor(today.moodLevel).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_moodEmoji(today.moodLevel),
                    style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today — ${_moodLabel(today.moodLevel)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _moodColor(today.moodLevel),
                          )),
                  if (today.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(today.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  const SizedBox(height: 4),
                  Text('Tap to update',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.outline)),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  // Quick-glance stats: streak, total days, and average mood
  Widget _buildStats(BuildContext context) {
    final streak = _calcStreak(_entries);
    final totalDays = {for (final e in _entries) e.id}.length;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFE65100),
            value: '$streak',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_month_rounded,
            iconColor: scheme.primary,
            value: '$totalDays',
            label: 'Days Logged',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.mood_rounded,
            iconColor: _moodColor(_averageMoodLevel),
            value: _entries.isEmpty ? '—' : _moodEmoji(_averageMoodLevel),
            label: 'Avg Mood',
            valueIsEmoji: true,
          ),
        ),
      ],
    );
  }

  // Each day of the current week as an emoji or empty circle
  Widget _buildWeekStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = {for (final e in _entries) e.id: e};
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final key = _dateKey(d);
              final entry = byDay[key];
              final isToday = key == _dateKey(DateTime.now());
              return Column(
                children: [
                  Text(
                    DateFormat('EEE').format(d),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isToday ? scheme.primary : scheme.outline,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry != null
                          ? _moodColor(entry.moodLevel).withOpacity(0.2)
                          : scheme.surfaceContainerHighest,
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: entry != null
                          ? Text(_moodEmoji(entry.moodLevel),
                              style: const TextStyle(fontSize: 19))
                          : Text(
                              d.day.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.outline),
                            ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Colour-coded bar chart for the last 30 days
  Widget _buildTrendChart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = {for (final e in _entries) e.id: e};
    final today = DateTime.now();
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-Day Mood Trend',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Each bar = one day. Tap to see details.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.outline)),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final entry = byDay[_dateKey(d)];
                final level = entry?.moodLevel ?? 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: entry != null
                          ? '${DateFormat('MMM d').format(d)}: ${_moodLabel(level)}'
                          : DateFormat('MMM d').format(d),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            height: level == 0 ? 3 : (level / 5) * 72,
                            decoration: BoxDecoration(
                              color: level == 0
                                  ? scheme.surfaceContainerHighest
                                  : _moodColor(level),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d').format(today.subtract(const Duration(days: 29))),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.outline),
              ),
              Text(
                'Today',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.outline),
              ),
            ],
          ),

          // Colour key below the chart
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: List.generate(5, (i) {
              final level = i + 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _moodColor(level),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _moodLabel(level),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.outline),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // How often each mood level was logged, as a percentage
  Widget _buildDistribution(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final counts = List.filled(5, 0);
    for (final e in _entries) counts[e.moodLevel - 1]++;
    final total = _entries.length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood Distribution',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...List.generate(5, (i) {
            final level = 5 - i; // show Great first
            final count = counts[level - 1];
            final pct = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(_moodEmoji(level),
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(_moodLabel(level),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_moodColor(level)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${(pct * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Last 10 entries — tap any to edit
  Widget _buildRecentEntries(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text('Recent Entries',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        ..._entries.take(10).map((e) => _EntryTile(
              entry: e,
              onTap: () => _openLogSheet(e),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayCard(context),
                    const SizedBox(height: 16),
                    _buildStats(context),
                    const SizedBox(height: 16),
                    _buildWeekStrip(context),
                    const SizedBox(height: 16),
                    _buildTrendChart(context),
                    const SizedBox(height: 16),
                    _buildDistribution(context),
                    const SizedBox(height: 20),
                    _buildRecentEntries(context),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogSheet(_todayEntry),
        icon: const Icon(Icons.add_reaction_rounded),
        label: Text(_todayEntry == null ? 'Log Mood' : 'Update Mood'),
      ),
    );
  }
}

// Bottom sheet for logging or updating a mood entry

class _LogMoodSheet extends StatefulWidget {
  final MoodEntry? prefill;
  const _LogMoodSheet({this.prefill});

  @override
  State<_LogMoodSheet> createState() => _LogMoodSheetState();
}

class _LogMoodSheetState extends State<_LogMoodSheet> {
  int _mood = 3;
  int _energy = 3;
  final Set<String> _selectedFactors = {};
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _mood = widget.prefill!.moodLevel;
      _energy = widget.prefill!.energyLevel;
      _selectedFactors.addAll(widget.prefill!.factors);
    }
    _noteCtrl = TextEditingController(text: widget.prefill?.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, max(20.0, bottom + 20)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pull-to-dismiss handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.prefill != null ? "Update Today's Mood" : 'How are you feeling?',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 24),

            // Tap one of the five emoji cards to pick a mood
            Text('Mood',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final level = i + 1;
                final selected = _mood == level;
                return GestureDetector(
                  onTap: () => setState(() => _mood = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 68,
                    decoration: BoxDecoration(
                      color: selected
                          ? _moodColor(level).withOpacity(0.18)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _moodColor(level) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_moodEmoji(level),
                            style: TextStyle(fontSize: selected ? 28 : 22)),
                        const SizedBox(height: 2),
                        Text(
                          _moodLabel(level),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? _moodColor(level)
                                    : scheme.outline,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // How much energy the user has today
            Text('Energy Level',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_energyLabels.first,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.outline)),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: _energy.toDouble(),
                    label: _energyLabels[_energy - 1],
                    activeColor: scheme.primary,
                    onChanged: (v) => setState(() => _energy = v.round()),
                  ),
                ),
                Text(_energyLabels.last,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.outline)),
              ],
            ),
            const SizedBox(height: 20),

            // Multi-select chips for what's been affecting them
            Text("What's been affecting you?",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _factors.map((f) {
                final sel = _selectedFactors.contains(f);
                return FilterChip(
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  showCheckmark: false,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedFactors.add(f);
                    } else {
                      _selectedFactors.remove(f);
                    }
                  }),
                  selectedColor: scheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Optional free-text note
            Text('Notes (optional)',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 16),

            // Pops the sheet back with the finished entry
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final entry = MoodEntry(
                    id: _dateKey(DateTime.now()),
                    timestamp: DateTime.now(),
                    moodLevel: _mood,
                    energyLevel: _energy,
                    factors: _selectedFactors.toList(),
                    note: _noteCtrl.text.trim(),
                  );
                  Navigator.pop(context, entry);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.prefill != null ? 'Update Entry' : 'Save Entry',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared UI widgets used across the page

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool valueIsEmoji;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueIsEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: valueIsEmoji
                ? const TextStyle(fontSize: 22)
                : Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onTap;
  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _moodColor(entry.moodLevel).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_moodEmoji(entry.moodLevel),
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _moodLabel(entry.moodLevel),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _moodColor(entry.moodLevel),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      // Small energy badge next to the mood label
                      const SizedBox(width: 8),
                      Icon(Icons.bolt_rounded,
                          size: 14, color: scheme.outline),
                      Text(
                        _energyLabels[entry.energyLevel - 1],
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: scheme.outline),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d').format(entry.timestamp),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                  if (entry.factors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.factors.take(4).join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Tracker"),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "How are you feeling today?",
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 32),

                /// Mood Selection
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Mood Selection"),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (index) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// 7 Day Streak
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Past 7 Days"),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          7,
                          (index) => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// Graph Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Monthly Mood Overview"),

                      const SizedBox(height: 20),

                      AspectRatio(
                        aspectRatio: 4/3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// Mood Distribution
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Mood Distribution",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 20),

                      /// Happy
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Mood1"),
                              Text("60%"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.6,
                              color: Colors.green,
                              minHeight: 8,
                              backgroundColor: Color(0xFFE0E0E0),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// Neutral
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Mood2"),
                              Text("25%"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.25,
                              minHeight: 8,
                              color: Colors.green,
                              backgroundColor: Color(0xFFE0E0E0),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// Sad
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Mood3"),
                              Text("15%"),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.15,
                              minHeight: 8,
                              color: Colors.green,
                              backgroundColor: Color(0xFFE0E0E0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
