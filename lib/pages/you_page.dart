import 'package:flutter/material.dart';
import '../herald_store.dart';
import '../theme.dart';
import '../widgets/h_card.dart';

class YouPage extends StatelessWidget {
  const YouPage({super.key, required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'YOUR HERALD',
            style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: muted),
          ),
          const SizedBox(height: 6),
          const Text(
            'You',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: navy),
          ),
          const SizedBox(height: 16),
          HCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: mint,
                      child: Icon(Icons.person_outline, color: teal),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Herald',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: navy,
                            ),
                          ),
                          Text(
                            'A private memory, in progress',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Your notes, voice, and memories live on this phone. Herald has no account to sign into.',
                    style: TextStyle(color: muted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'HOW HERALD KNOWS YOU',
            style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 8),
          HCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.graphic_eq, color: teal),
                  title: const Text('Know my voice'),
                  subtitle: const Text('Off — keep it general'),
                  trailing: Switch(value: false, onChanged: (_) {}),
                ),
                const Divider(color: line),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_user_outlined, color: teal),
                  title: Text('Why this stays private'),
                  subtitle: Text('No cloud AI · No cloud DB · No account'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'MEMORY & DEVICE',
            style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 8),
          HCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.headset_mic_outlined, color: teal),
              title: const Text('Chat & memory thread'),
              subtitle: Text(
                '${store.lines.length} lines · ${store.memories.length} facts',
              ),
            ),
          ),
          const SizedBox(height: 10),
          HCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: teal),
              title: const Text('Kept on this device'),
              subtitle: Text(
                'Tasks ${store.items.length} · Done ${store.weeklyDone.length} · Day Mode ${store.dayOn ? "ON" : "OFF"}',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Herald is a small promise: remember more, send less.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}