import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_page.dart';
import 'today_page.dart';
import 'calendar_page.dart';
import 'week_page.dart';
import 'you_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onChanged: () => setState(() {})),
      TodayPage(onChanged: () => setState(() {})),
      CalendarPage(onChanged: () => setState(() {})),
      WeekPage(onChanged: () => setState(() {})),
      YouPage(onChanged: () => setState(() {})),
    ];
    return Scaffold(
      backgroundColor: cream,
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: cream,
        indicatorColor: teal,
        indicatorShape: const CircleBorder(),
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Colors.white),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Colors.white),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            selectedIcon: Icon(Icons.schedule, color: Colors.white),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'You',
          ),
        ],
      ),
    );
  }
}