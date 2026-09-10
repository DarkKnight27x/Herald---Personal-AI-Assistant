import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:herald/due_time.dart';
import 'package:herald/herald_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('classifies the demo sentences into local cards and a proposal', () {
    final herald = HeraldStore();
    herald.add("I'll send Rahul the database tonight.");
    herald.add("Let's meet tomorrow at 4.");
    herald.add('The project deadline is Friday.');

    expect(herald.items, hasLength(3));
    expect(herald.items.map((item) => item.type),
        containsAll(<String>['commitment', 'meeting', 'deadline']));
    expect(herald.events, hasLength(1));
    expect(herald.events.single.confirmed, isFalse);

    herald.add('Remind me to call Mom tonight.');
    expect(herald.items.where((item) => item.type == 'reminder'), hasLength(1));
  });

  test('does not add the same commitment for the same due day twice', () {
    final herald = HeraldStore();
    herald.add("I'll send Rahul the database tonight.");
    herald.add("I'll send Rahul the database tonight.");

    expect(herald.items, hasLength(1));
  });

  test('done moves an item to the weekly record', () {
    final herald = HeraldStore();
    herald.add('Remind me to call Mom tonight.');
    final id = herald.items.single.id;

    herald.markDone(id);

    expect(herald.items, isEmpty);
    expect(herald.weeklyDone, hasLength(1));
    expect(herald.weeklyDone.single.done, isTrue);
  });

  test('ask answers promises, tomorrow, open work, and decisions', () {
    final herald = HeraldStore();
    herald.add("I'll send Rahul the database tonight.");
    herald.add("Let's meet tomorrow at 4.");
    herald.add('We decided to keep the data on this phone.');

    expect(herald.ask('What did I promise?'), contains('Send Rahul'));
    expect(herald.ask('What do I need tomorrow?'), contains('Meet tomorrow'));
    expect(herald.ask("What's open?"), contains('Send Rahul'));
    expect(herald.ask('What did we decide?'), contains('Keep the data'));
  });

  test('JSON round trip keeps the local store', () {
    final source = HeraldStore();
    source.add("I'll send Rahul the database tonight.");
    source.add("Let's meet tomorrow at 4.");
    source.add('We decided to keep the data on this phone.');
    source.markDone(source.items.first.id);

    final restored = HeraldStore()..loadJson(source.toJson());

    expect(restored.last, source.last);
    expect(restored.lines, source.lines);
    expect(restored.items.length, source.items.length);
    expect(restored.events.length, source.events.length);
    expect(restored.weeklyDone.length, source.weeklyDone.length);
    expect(restored.memories, source.memories);
  });

  test('parses Herald due labels without an emulator', () {
    final now = DateTime(2026, 9, 9, 10);
    expect(parseHeraldDue('Tonight 8:00', now: now), DateTime(2026, 9, 9, 20));
    expect(parseHeraldDue('Tomorrow 4:00', now: now), DateTime(2026, 9, 10, 16));
    expect(parseHeraldDue('Friday 6:00', now: now), DateTime(2026, 9, 11, 18));
    expect(parseHeraldDue('9 PM', now: now), DateTime(2026, 9, 9, 21));
  });
}
