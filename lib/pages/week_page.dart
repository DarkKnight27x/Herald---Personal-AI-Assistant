import 'package:flutter/material.dart';

import '../due_time.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/empty_panel.dart';
import '../widgets/h_card.dart';
import '../widgets/pretty_when.dart';

class WeekPage extends StatefulWidget {
  const WeekPage({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  late bool next;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    next = now.weekday == DateTime.sunday && now.hour >= 18;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dated = store.items.where((e) => e.due.isNotEmpty).toList();
    final nextItems = dated.where((e) {
      final due = parseHeraldDue(e.due, rollPast: false);
      return due != null && _inNextWeek(due, now);
    }).toList();
    final nextEvents = store.events.where((e) {
      final due = parseHeraldDue(e.whenText, rollPast: false);
      return due != null && _inNextWeek(due, now);
    }).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'THE WIDER SHAPE',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: muted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Week',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E0D4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _seg(
                    'Done this week',
                    !next,
                    () => setState(() => next = false),
                  ),
                ),
                Expanded(
                  child: _seg(
                    'Next week',
                    next,
                    () => setState(() => next = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (!next) ...[
            const Text(
              'A QUIET TALLY',
              style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'You kept your word.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: navy,
                    ),
                  ),
                ),
                Text(
                  '${store.weeklyDone.length}',
                  style: const TextStyle(
                    fontSize: 34,
                    color: teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (store.weeklyDone.isEmpty)
              const EmptyPanel(
                'Your week is still open.',
                'Completed things gather here, without a score.',
              )
            else
              ...store.weeklyDone.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HCard(
                    child: Text(
                      e.text,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ] else ...[
            if (now.weekday == DateTime.sunday && now.hour >= 18)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sunday night — here is next week, quietly laid out.',
                  style: TextStyle(color: muted),
                ),
              ),
            if (nextItems.isEmpty && nextEvents.isEmpty)
              const EmptyPanel(
                'Nothing dated next week yet.',
                'Meetings and deadlines show here.',
              )
            else ...[
              ...nextItems.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HCard(
                    child: Text('• ${e.text} · ${prettyWhen(e.due)}'),
                  ),
                ),
              ),
              ...nextEvents.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HCard(
                    child: Text('• ${e.title} · ${prettyWhen(e.whenText)}'),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _inNextWeek(DateTime when, DateTime now) {
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    final nextStart = weekStart.add(const Duration(days: 7));
    final nextEnd = nextStart.add(const Duration(days: 7));
    return !when.isBefore(nextStart) && when.isBefore(nextEnd);
  }

  Widget _seg(String label, bool on, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: on ? navy : muted,
          ),
        ),
      ),
    );
  }
}
