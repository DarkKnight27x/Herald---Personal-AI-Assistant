import 'package:flutter/material.dart';

import '../theme.dart';
import 'h_card.dart';

class EmptyPanel extends StatelessWidget {
  const EmptyPanel(this.title, this.body, {super.key});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return HCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
