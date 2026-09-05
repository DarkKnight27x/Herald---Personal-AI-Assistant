import 'package:flutter/material.dart';
import '../theme.dart';

class HCard extends StatelessWidget {
  const HCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: child,
    );
  }
}