import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/week_day_selector.dart';
import '../widgets/schedule_box.dart';
import 'session_missed_screen.dart';
import 'study_session_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() {
    return _ScheduleScreenState();
  }
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedIndex = 0;

  void _navigateToSession(String subject, String description, String status) {
    if (status.toLowerCase() == 'missed') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SessionMissedScreen(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StudySessionScreen(
            courseTitle: subject,
            sessionTitle: description,
            timeInfo: "18:00 - 19:30 (90 min)",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                const SizedBox(height: 25),
                const Text(
                  "Schedule",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Your academic focus for the week.",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const WeekDaySelector(),
                const SizedBox(height: 20),

                // Schedule Items List
                ScheduleBox(
                  time: "09:00 AM",
                  duration: "1.5h",
                  subject: "Data Structures",
                  description: "Review Binary Trees & Heaps",
                  status: "Completed",
                  onTap: () => _navigateToSession("Data Structures", "Review Binary Trees & Heaps", "Completed"),
                ),
                const SizedBox(height: 15),

                ScheduleBox(
                  time: "11:00 AM",
                  duration: "2h",
                  subject: "Calculus III",
                  description: "Assignment 4: Multiple Integrals",
                  status: "In Progress",
                  progress: 0.45,
                  onTap: () => _navigateToSession("Calculus III", "Assignment 4: Multiple Integrals", "In Progress"),
                ),
                const SizedBox(height: 15),

                ScheduleBox(
                  time: "02:30 PM",
                  duration: "1h",
                  subject: "Physics Lab",
                  description: "Read experiment manual",
                  status: "Planned",
                  onTap: () => _navigateToSession("Physics Lab", "Read experiment manual", "Planned"),
                ),
                const SizedBox(height: 15),

                ScheduleBox(
                  time: "04:00 PM",
                  duration: "30m",
                  subject: "Spanish 101",
                  description: "Vocab Flashcards",
                  status: "Missed",
                  onTap: () => _navigateToSession("Spanish 101", "Vocab Flashcards", "Missed"),
                ),
                const SizedBox(height: 30),

                // Generate Schedule Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3525CD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SessionMissedScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Generate Schedule",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}