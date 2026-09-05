import 'package:flutter/material.dart';
import '../herald_api.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/h_card.dart';
import '../widgets/task_row.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final typed = TextEditingController();

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  Future<void> _send([String? value]) async {
    final text = value ?? typed.text;
    store.add(text);
    typed.clear();
    setState(() {});
    widget.onChanged();
    await sendChunk(text);
    setState(() {});
    widget.onChanged();
  }

  String get _greet {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning.';
    if (h < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: navy,
                child: const Text('h', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HERALD', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: navy)),
                  Text('on this phone only', style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(_greet, style: const TextStyle(color: muted)),
          const SizedBox(height: 8),
          const Text('Keep the good\nthings in mind.',
              style: TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w600, color: teal)),
          const SizedBox(height: 12),
          const Text('Your private AI. On this phone only.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: navy, height: 1.25)),
          const SizedBox(height: 8),
          const Text('A quiet place for what you say, promise, and mean to remember.',
              style: TextStyle(color: muted, height: 1.4)),
          const SizedBox(height: 20),
          HCard(
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: mint, child: Icon(Icons.verified_user, color: teal)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Day Mode', style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                      Text(store.dayOn ? 'On — Herald is listening' : 'Off until you need it',
                          style: const TextStyle(color: muted, fontSize: 13)),
                    ],
                  ),
                ),
                Switch(
                  value: store.dayOn,
                  activeThumbColor: teal,
                  onChanged: (v) {
                    setState(() => store.dayOn = v);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.graphic_eq, size: 16, color: muted),
                    SizedBox(width: 6),
                    Text('LAST HEARD', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  store.last.isEmpty ? 'Nothing yet today.' : '“${store.last}”',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: navy, height: 1.3),
                ),
                const SizedBox(height: 6),
                const Text('Held on this phone only', style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('A SMALL NUDGE', style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text("What's on your mind?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: navy)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: navy),
                onPressed: () => _ask(),
                child: const Text('Ask'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() => store.dayOn = !store.dayOn);
                    widget.onChanged();
                  },
                  icon: Icon(store.dayOn ? Icons.stop : Icons.mic_none),
                  label: Text(store.dayOn ? 'Stop Herald' : 'Start Herald'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: line),
                  ),
                  onPressed: () => _composer(),
                  child: const Icon(Icons.add, color: navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Text('In your orbit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: navy)),
              const Spacer(),
              Text('${store.items.length} items', style: const TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 10),
          if (store.items.isEmpty)
            const Text('Nothing in orbit yet.', style: TextStyle(color: muted))
          else
            ...store.items.take(3).map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskRow(
                  type: e.type,
                  title: e.text,
                  due: e.due,
                  onDone: () {
                    store.markDone(e.id);
                    markDoneRemote(e.id);
                    widget.onChanged();
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Nothing leaves this phone.', style: TextStyle(color: muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _composer() async {
    typed.clear();
    await showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typed,
              autofocus: true,
              decoration: const InputDecoration(hintText: "I'll send Rahul the database tonight"),
              onSubmitted: (v) {
                Navigator.pop(ctx);
                _send(v);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: teal),
              onPressed: () {
                Navigator.pop(ctx);
                _send();
              },
              child: const Text('Send to Herald'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ask() async {
    final ask = TextEditingController();
    var answer = '';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: cardBg,
          title: const Text('Ask Herald'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ask, decoration: const InputDecoration(hintText: 'What did I promise?')),
              if (answer.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(answer)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: navy),
              onPressed: () => setD(() => answer = store.ask(ask.text)),
              child: const Text('Ask'),
            ),
          ],
        ),
      ),
    );
    ask.dispose();
  }
}