import 'package:flutter/material.dart';

class ScheduleBox extends StatelessWidget {
  final String time;
  final String duration;
  final String subject;
  final String description;
  final String status;
  final double? progress;
  final VoidCallback? onTap;

  const ScheduleBox({
    required this.time,
    required this.duration,
    required this.subject,
    required this.description,
    required this.status,
    this.progress,
    this.onTap,
    super.key,
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF5B55C9);

      case 'in progress':
        return const Color(0xFF3525CD);

      case 'missed':
        return const Color(0xFFD45B55);

      case 'planned':
        return const Color(0xFF7B8190);

      default:
        return const Color(0xFF7B8190);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDE - TIME AND DURATION
        SizedBox(
          width: 145,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF464555),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                duration,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF707584),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 15),

        // RIGHT SIDE - CARD
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),

            child: Row(
              children: [
                // LEFT COLORED LINE
                Container(
                  width: 5,
                  height: progress != null ? 255 : 190,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STATUS + THREE BARS
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status.toLowerCase() ==
                                      'in progress')
                                    Container(
                                      width: 9,
                                      height: 9,
                                      margin:
                                          const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),

                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // THREE SMALL BARS
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),

                                const SizedBox(width: 4),

                                Container(
                                  width: 5,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.6),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),

                                const SizedBox(width: 4),

                                Container(
                                  width: 5,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.3),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // SUBJECT
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF252631),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // DESCRIPTION
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF707584),
                          ),
                        ),

                        // PROGRESS SECTION
                        if (progress != null) ...[
                          const SizedBox(height: 25),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF707584),
                                ),
                              ),

                              Text(
                                '${(progress! * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF707584),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  const Color(0xFFE1E3E8),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }
}