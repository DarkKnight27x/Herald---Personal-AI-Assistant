import 'package:flutter/material.dart';

class TypePill extends StatelessWidget {
  const TypePill(this.type, {super.key});
  final String type;

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    late Color c;
    switch (t) {
      case 'deadline':
        c = const Color(0xFF8B2942);
        break;
      case 'meeting':
        c = const Color(0xFF1D4E89);
        break;
      case 'reminder':
        c = const Color(0xFFB0892A);
        break;
      case 'followup':
      case 'follow-up':
        c = const Color(0xFF9A6B4F);
        break;
      default:
        c = const Color(0xFF1F6B57);
    }
    return Text(
      t.toUpperCase(),
      style: TextStyle(
        color: c,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}
