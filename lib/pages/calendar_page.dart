import 'package:flutter/material.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/empty_panel.dart';
import '../widgets/h_card.dart';
import '../widgets/pretty_when.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('YOUR TIME, GENTLY ARRANGED', style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: muted)),
          const SizedBox(height: 6),
          const Text('Calendar', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: navy)),
          const SizedBox(height: 8),
          const Text('Nothing is added to your phone calendar until you confirm.', style: TextStyle(color: muted)),
          const SizedBox(height: 18),
          const Text('COMING UP', style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted)),
          const SizedBox(height: 10),
          if (store.events.isEmpty)
            const EmptyPanel('No meetings yet.', 'Say “let’s meet tomorrow at 4”.')
          else
            ...store.events.map(
                  (ev) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(ev.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: navy))),
                          Text(
                            ev.confirmed ? 'CONFIRMED' : 'PROPOSED',
                            style: TextStyle(color: ev.confirmed ? teal : const Color(0xFFB0892A), fontSize: 11, fontWeight: FontWeight.w800),
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
                                  onChanged();
                                },
                                child: const Text('Confirm'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  store.dismissEvent(ev.id);
                                  onChanged();
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
              ),
            ),
        ],
      ),
    );
  }
}