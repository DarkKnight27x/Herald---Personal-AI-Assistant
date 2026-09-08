import 'package:flutter/material.dart';
import 'pages/shell.dart';
import 'theme.dart';
import 'herald_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.restore();
  runApp(const HeraldApp());
}

class HeraldApp extends StatelessWidget {
  const HeraldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Herald',
      theme: heraldTheme(),
      home: const Shell(),
    );
  }
}