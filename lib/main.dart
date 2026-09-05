import 'package:flutter/material.dart';
import 'pages/shell.dart';
import 'theme.dart';

void main() => runApp(const HeraldApp());

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