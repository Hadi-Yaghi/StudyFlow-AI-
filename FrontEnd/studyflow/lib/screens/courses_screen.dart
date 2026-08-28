import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/course_card.dart';
import 'course_details_screen.dart';
import 'add_new_course_screen.dart';
import 'courses_setup_screen.dart';

class CourseItemData {
  final String code;
  final String title;
  final String instructor;
  final int pendingTasksCount;
  final int percent;

  CourseItemData({
    required this.code,
    required this.title,
    required this.instructor,
    required this.pendingTasksCount,
    required this.percent,
  });
}

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<CourseItemData> _courses = [
    CourseItemData(
      code: 'CS401',
      title: 'Database Systems',
      instructor: 'Dr. Smith',
      pendingTasksCount: 6,
      percent: 72,
    ),
    CourseItemData(
      code: 'CS302',
      title: 'Algorithms',
      instructor: 'Dr. Brown',
      pendingTasksCount: 4,
      percent: 45,
    ),
  ];

  Future<void> _openAddNewCourseScreen() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => const AddNewCourseScreen(),
      ),
    );

    if (result != null && result['title'] != null) {
      setState(() {
        _courses.add(
          CourseItemData(
            code: result['code'] ?? 'CS100',
            title: result['title']!,
            instructor: result['instructor'] ?? 'Instructor',
            pendingTasksCount: 0,
            percent: 0,
          ),
        );
      });
    }
  }

  void _openCoursesSetupScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CoursesSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching HomeHeader
              const HomeHeader(),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Courses",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCoursesSetupScreen,
                    icon: const Icon(Icons.settings_suggest_outlined, size: 18),
                    label: const Text("Setup Flow"),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                "Manage your active semesters and track progress.",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Course Cards List
              if (_courses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        "No courses added yet. Add one below to get started.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                )
              else
                ..._courses.map((course) {
                  return CourseCard(
                    code: course.code,
                    title: course.title,
                    instructor: course.instructor,
                    pendingTasksCount: course.pendingTasksCount,
                    percent: course.percent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CourseDetailsScreen(
                            courseCode: course.code,
                            courseTitle: course.title,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Add New Course Card
              InkWell(
                onTap: _openAddNewCourseScreen,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 26,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Add New Course",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
