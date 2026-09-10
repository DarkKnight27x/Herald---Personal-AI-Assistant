import 'package:flutter/material.dart';

import '../herald_api.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/empty_panel.dart';
import '../widgets/h_card.dart';
import '../widgets/pretty_when.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime month;
  late DateTime selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
    selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = store.eventsOn(selected);
    final dayItems = store.itemsOn(selected);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'YOUR TIME, GENTLY ARRANGED',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: muted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Calendar',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nothing is added to your phone calendar until you confirm.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 18),
          HCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        month = DateTime(month.year, month.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_left, color: navy),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        month = DateTime(month.year, month.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_right, color: navy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    _Dow('M'),
                    _Dow('T'),
                    _Dow('W'),
                    _Dow('T'),
                    _Dow('F'),
                    _Dow('S'),
                    _Dow('S'),
                  ],
                ),
                const SizedBox(height: 6),
                ..._weeks().map(
                  (week) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: week
                          .map((day) => Expanded(child: _dayCell(day)))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ON ${_prettyDay(selected)}',
            style: const TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 10),
          if (dayEvents.isEmpty && dayItems.isEmpty)
            const EmptyPanel(
              'Nothing on this day.',
              'Say “let’s meet tomorrow at 4”.',
            )
          else ...[
            ...dayEvents.map(_eventCard),
            ...dayItems
                .where((i) => i.type != 'meeting')
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HCard(
                      child: Text(
                        '${i.type.toUpperCase()} · ${i.text}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          const Text(
            'COMING UP',
            style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 10),
          if (store.events.isEmpty)
            const EmptyPanel(
              'No meetings yet.',
              'Say “let’s meet tomorrow at 4”.',
            )
          else
            ...store.events.map(_eventCard),
        ],
      ),
    );
  }

  Widget _eventCard(HeraldEvent ev) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ev.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                ),
                Text(
                  ev.confirmed ? 'CONFIRMED' : 'PROPOSED',
                  style: TextStyle(
                    color: ev.confirmed ? teal : const Color(0xFFB0892A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(prettyWhen(ev.whenText), style: const TextStyle(color: muted)),
            if (!ev.confirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: teal),
                      onPressed: () {
                        store.confirmEvent(ev.id);
                        confirmRemote(ev.id);
                        widget.onChanged();
                        setState(() {});
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        store.dismissEvent(ev.id);
                        dismissRemote(ev.id);
                        widget.onChanged();
                        setState(() {});
                      },
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayCell(DateTime? day) {
    if (day == null) return const SizedBox(height: 40);
    final isSelected = day.year == selected.year &&
        day.month == selected.month &&
        day.day == selected.day;
    final isToday = _sameDate(day, DateTime.now());
    final marked =
        store.eventsOn(day).isNotEmpty || store.itemsOn(day).isNotEmpty;
    return GestureDetector(
      onTap: () => setState(() => selected = day),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? teal : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? teal
                        : navy,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            if (marked)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : teal,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<List<DateTime?>> _weeks() {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(startOffset, null),
      ...List.generate(
        daysInMonth,
        (i) => DateTime(month.year, month.month, i + 1),
      ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<DateTime?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    return weeks;
  }

  String _monthLabel(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _prettyDay(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[d.weekday - 1]} ${d.day}';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
