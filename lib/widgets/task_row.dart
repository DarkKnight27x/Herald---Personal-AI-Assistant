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
    this.onDone,
  });

  final String type;
  final String title;
  final String due;
  final String note;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    TypePill(type),
                    if (note.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(note, style: const TextStyle(color: muted, fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navy)),
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