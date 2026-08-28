import 'package:flutter/material.dart';

class MissedSessionCard extends StatelessWidget {
  final String subject;
  final String title;
  final String timeRange;

  const MissedSessionCard({
    required this.subject,
    required this.title,
    required this.timeRange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strikethrough Subject
          Text(
            subject,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // Assignment / Title Row
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Strikethrough Time Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
