import 'package:flutter/material.dart';

import '../day_listen.dart';
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
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
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
                  subtitle: Text(
                    store.voiceEnrolled
                        ? 'On — promises you say stay yours'
                        : 'Off — enroll a phrase to separate you from them',
                  ),
                  trailing: Switch(
                    value: store.knowMyVoice && store.voiceEnrolled,
                    activeThumbColor: teal,
                    onChanged: (v) async {
                      if (v) {
                        await _enroll(context);
                      } else {
                        store.knowMyVoice = false;
                        await store.persist();
                      }
                      onChanged();
                    },
                  ),
                ),
                if (store.voiceEnrolled && store.voicePhrase.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enrolled phrase: “${store.voicePhrase}”',
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
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
            'PRIVACY DASHBOARD',
            style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 8),
          HCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.airplanemode_active, color: teal),
                  title: const Text('Airplane-mode demo'),
                  subtitle: Text(
                    store.airplaneDemo
                        ? 'Laptop join is off. Typed + voice stay on device.'
                        : 'Optional laptop brain on 127.0.0.1:8765',
                  ),
                  trailing: Switch(
                    value: store.airplaneDemo,
                    activeThumbColor: teal,
                    onChanged: (v) async {
                      store.airplaneDemo = v;
                      if (v) store.laptopJoin = false;
                      if (!v) store.laptopJoin = true;
                      await store.persist();
                      onChanged();
                    },
                  ),
                ),
                const Divider(color: line),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cable, color: teal),
                  title: const Text('Join laptop brain'),
                  subtitle: Text(
                    store.lastLaptopAt.isEmpty
                        ? 'No snapshot received yet'
                        : 'Last snapshot ${_ago(store.lastLaptopAt)}',
                  ),
                  trailing: Switch(
                    value: store.laptopJoin && !store.airplaneDemo,
                    activeThumbColor: teal,
                    onChanged: store.airplaneDemo
                        ? null
                        : (v) async {
                            store.laptopJoin = v;
                            await store.persist();
                            onChanged();
                          },
                  ),
                ),
                const Divider(color: line),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.mic_none, color: teal),
                  title: Text('Microphone audio'),
                  subtitle: Text('Never uploaded. Vosk runs on this phone.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'MEMORY THREAD',
            style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
          ),
          const SizedBox(height: 8),
          HCard(
            child: store.thread.isEmpty
                ? const Text(
                    'Nothing held yet. Say “I’ll send Rahul the database tonight.”',
                    style: TextStyle(color: muted, height: 1.4),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${store.chat.length} lines · ${store.memories.length} facts · tap a line',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      ...store.thread.map((beat) => _threadRow(context, beat)),
                    ],
                  ),
          ),
          if (store.memories.isNotEmpty) ...[
            const SizedBox(height: 10),
            HCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIFE MEMORY',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...store.memories.take(6).map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $m'),
                        ),
                      ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          HCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: teal),
              title: const Text('Kept on this device'),
              subtitle: Text(
                'Tasks ${store.items.length} · Events ${store.events.length} · Done ${store.weeklyDone.length} · Day Mode ${store.dayOn ? "ON" : "OFF"}',
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

Widget _threadRow(BuildContext context, Map<String, String> beat) {
  return InkWell(
    onTap: () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          title: Text(beat['text'] ?? ''),
          content: Text(
            '${beat['clock']} · ${beat['who']}\n\n${beat['why']}',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${beat['clock']}  ${beat['who']}  ${beat['text']}',
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '→ ${beat['why']}',
            style: const TextStyle(color: muted, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    ),
  );
}

Future<void> _enroll(BuildContext context) async {
  final typed = TextEditingController();
  var status = 'Say or type a sentence only you would say.';
  await showModalBottomSheet(
    context: context,
    backgroundColor: cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Know my voice',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(color: muted)),
            const SizedBox(height: 12),
            TextField(
              controller: typed,
              decoration: const InputDecoration(
                hintText: 'This is Saarthak, keep my promises as mine',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setS(() => status = 'Listening on this phone…');
                      final heard = await listenOnce();
                      if (heard.startsWith('Voice') ||
                          heard.startsWith('Voice recognition')) {
                        setS(() => status = heard);
                        return;
                      }
                      if (heard.trim().isEmpty) {
                        setS(() => status = 'Nothing heard. Type the phrase.');
                        return;
                      }
                      store.voicePhrase = heard.trim();
                      store.voiceEnrolled = true;
                      store.knowMyVoice = true;
                      await store.persist();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.mic_none),
                    label: const Text('Speak it'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: teal),
                    onPressed: () async {
                      final phrase = typed.text.trim();
                      if (phrase.isEmpty) {
                        setS(() => status = 'Type a phrase first.');
                        return;
                      }
                      store.voicePhrase = phrase;
                      store.voiceEnrolled = true;
                      store.knowMyVoice = true;
                      await store.persist();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save phrase'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  typed.dispose();
}

String _ago(String iso) {
  final at = DateTime.tryParse(iso);
  if (at == null) return iso;
  final diff = DateTime.now().difference(at.toLocal());
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}