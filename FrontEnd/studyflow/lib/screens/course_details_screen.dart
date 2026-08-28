import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseCode;
  final String courseTitle;

  const CourseDetailsScreen({
    this.courseCode = "CS401",
    this.courseTitle = "Database Systems",
    super.key,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  String selectedTab = "Overview";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1F2937),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage('assets/images/study_flow_logo.png'),
                      ),
                    ],
                  ),
                  const Text(
                    "StudyFlow",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3525CD),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Hero Purple Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3525CD), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3525CD).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Semester Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "FALL 2024",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            "${widget.courseCode}: ${widget.courseTitle}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Instructor & Schedule Info
                          Row(
                            children: const [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Prof. Elena Rodriguez",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "MWF 10:00 AM - 11:30 AM",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Course Progress",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                "65%",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Overview', 'Tasks', 'Sessions', 'Resources'].map((tab) {
                          final bool isSelected = selectedTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTab = tab;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3525CD)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF3525CD)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  tab,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content View Based on Tab
                    if (selectedTab == 'Overview') ...[
                      // Upcoming Deadlines Card
                      _buildSectionCard(
                        title: "Upcoming Deadlines",
                        child: Column(
                          children: [
                            _buildDeadlineItem(
                              date: "Nov 12",
                              title: "Milestone 2: Schema Design",
                              subtitle: "Due in 2 days",
                            ),
                            Divider(color: Colors.grey.shade200),
                            _buildDeadlineItem(
                              date: "Nov 15",
                              title: "Quiz 4: Normalization",
                              subtitle: "Friday, 10:00 AM",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Tasks Card
                      _buildSectionCard(
                        title: "Active Tasks",
                        actionText: "View All",
                        child: Column(
                          children: [
                            _buildTaskItem(
                              title: "Read Chapter 5: Relational Algebra",
                              badgeText: "READING",
                              badgeColor: const Color(0xFFE0F2FE),
                              textColor: const Color(0xFF0369A1),
                            ),
                            Divider(color: Colors.grey.shade200),
                            _buildTaskItem(
                              title: "Review lecture notes on B-Trees",
                              badgeText: "REVIEW",
                              badgeColor: const Color(0xFFF3E8FF),
                              textColor: const Color(0xFF6B21A8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Performance Metrics Card
                      _buildSectionCard(
                        title: "Performance",
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile("Current Grade", "A-"),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                            ),
                            Expanded(
                              child: _buildMetricTile("Attendance", "92%"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Session Card
                      _buildSectionCard(
                        title: "Next Session",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Lecture 12: Indexing Structures",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Wednesday, 10:00 AM",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3525CD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Joining Zoom Room..."),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.videocam, color: Colors.white),
                                label: const Text(
                                  "Join Zoom Room",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Text(
                          "$selectedTab content for ${widget.courseCode}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? actionText,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              if (actionText != null)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Color(0xFF3525CD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDeadlineItem({
    required String date,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              date,
              style: const TextStyle(
                color: Color(0xFF3525CD),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3525CD),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
