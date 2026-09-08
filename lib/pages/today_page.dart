import 'package:flutter/material.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/empty_panel.dart';
import '../widgets/task_row.dart';
import '../herald_api.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(_todayLabel(), style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: muted)),
          const SizedBox(height: 6),
          const Text('Today', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: navy)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR PACE', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text('One thing at a time.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('A gentle list, not a demand.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Text('${store.items.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text('WORKING ITEMS', style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted)),
              const Spacer(),
              Text('${store.items.length}', style: const TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 10),
          if (store.items.isEmpty)
            const EmptyPanel('Your plate is clear.', 'Send a sentence from Home.')
          else
            ...store.items.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskRow(
                  type: e.type,
                  title: e.text,
                  due: e.due,
                  onDone: () {
                    store.markDone(e.id);
                    markDoneRemote(e.id);
                    onChanged();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _todayLabel() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}'.toUpperCase();
  }
}
