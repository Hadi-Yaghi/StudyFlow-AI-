import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../services/course_service.dart';
import '../services/task_service.dart';
import '../widgets/home_header.dart';
import '../widgets/course_card.dart';
import 'course_details_screen.dart';
import 'add_new_course_screen.dart';
import 'courses_setup_screen.dart';
import '../widgets/ads/banner_ad_widget.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CourseService _courseService = CourseService();
  final TaskService _taskService = TaskService();

  List<CourseModel> _courses = [];
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _courseService.getCourses(),
        _taskService.getTasks(),
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0] as List<CourseModel>;
          _tasks = results[1] as List<TaskModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _courses = [];
          _tasks = [];
          _isLoading = false;
        });
      }
    }
  }

  int _getPendingTasksCount(int courseId) {
    return _tasks
        .where((t) => t.courseId == courseId && t.status.toUpperCase() != 'COMPLETED')
        .length;
  }

  int _getCourseCompletionPercent(int courseId) {
    final courseTasks = _tasks.where((t) => t.courseId == courseId).toList();
    if (courseTasks.isEmpty) return 0;
    final completed =
        courseTasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    return ((completed / courseTasks.length) * 100).round().clamp(0, 100);
  }

  Future<void> _openAddNewCourseScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddNewCourseScreen(),
      ),
    );

    if (result == true) {
      _loadCourses();
    }
  }

  void _openCoursesSetupScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CoursesSetupScreen(),
          ),
        )
        .then((_) => _loadCourses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCourses,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                // Loading or Course Cards List
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3525CD),
                      ),
                    ),
                  )
                else if (_courses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 20),
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
                    final pendingCount = _getPendingTasksCount(course.id);
                    final percent = _getCourseCompletionPercent(course.id);

                    return CourseCard(
                      code: course.code,
                      title: course.name,
                      instructor: course.instructor.isNotEmpty ? course.instructor : "Instructor",
                      pendingTasksCount: pendingCount,
                      percent: percent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CourseDetailsScreen(
                              courseId: course.id,
                              initialCourse: course,
                              courseCode: course.code,
                              courseTitle: course.name,
                            ),
                          ),
                        ).then((_) => _loadCourses());
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

                const SizedBox(height: 16),
                const BannerAdWidget(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
