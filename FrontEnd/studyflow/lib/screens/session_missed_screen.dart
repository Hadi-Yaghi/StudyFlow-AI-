import 'package:flutter/material.dart';
import '../widgets/missed_session_card.dart';
import '../widgets/rescheduled_session_card.dart';

class SessionMissedScreen extends StatelessWidget {
  const SessionMissedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Close Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 26,
                    color: Color(0xFF1F2937),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Red Circle Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE8E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy_outlined,
                        size: 40,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Large Title
                    const Text(
                      "Session missed",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      "No need to stress. We've adjusted your schedule to keep you on track.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Old Missed Session Card
                    const MissedSessionCard(
                      subject: "Database Systems",
                      title: "ER Diagram Assignment",
                      timeRange: "18:00 - 19:30",
                    ),

                    // Vertical Dashed Connector + Sparkle Pill Badge
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Color(0xFF3525CD),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "This session was automatically rescheduled",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),

                    // New Rescheduled Session Card
                    const RescheduledSessionCard(
                      dateBadge: "AUG 12",
                      subject: "Database Systems",
                      title: "ER Diagram Assignment",
                      newTimeRange: "19:45 - 21:15",
                      duration: "1h 30m",
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Full Width Purple Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3525CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "View New Session",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
