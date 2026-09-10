import 'package:flutter/material.dart';

import '../theme.dart';
import 'h_card.dart';
import 'pretty_when.dart';
import 'type_pill.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.type,
    required this.title,
    this.due = '',
    this.note = '',
    this.theirs = false,
    this.onDone,
  });

  final String type;
  final String title;
  final String due;
  final String note;
  final bool theirs;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final showTheirs = theirs || note.toLowerCase() == 'theirs';
    return HCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: line, width: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TypePill(type),
                    if (showTheirs)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A6B4F),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'THEIRS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),
                if (due.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    prettyWhen(due),
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}