import 'package:flutter/material.dart';
import 'package:studyflow/widgets/progress_card.dart';
import 'package:studyflow/widgets/scheduale_item.dart';
import 'package:studyflow/widgets/statistics_card.dart';
import 'package:studyflow/widgets/study_session_card.dart';
import 'package:studyflow/widgets/bottom_navigation.dart';
import '../models/course_model.dart';
import '../models/study_session_model.dart';
import '../models/task_model.dart';
import '../services/course_service.dart';
import '../services/schedule_service.dart';
import '../services/task_service.dart';
import '../widgets/home_header.dart';
import 'add_new_course_screen.dart';
import 'schedule_screen.dart';
import 'tasks_screen.dart';
import 'courses_screen.dart';
import 'profile_screen.dart';
import '../core/storage/token_storage.dart';
import '../services/ad_service.dart';
import '../widgets/ads/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String _userName = "Student";

  final CourseService _courseService = CourseService();
  final TaskService _taskService = TaskService();
  final ScheduleService _scheduleService = ScheduleService();

  List<CourseModel> _courses = [];
  List<TaskModel> _tasks = [];
  List<StudySessionModel> _todaySessions = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDashboardData();
  }

  Future<void> _loadUser() async {
    final userData = await TokenStorage.getUserData();
    if (mounted && userData['name'] != null && userData['name']!.isNotEmpty) {
      setState(() {
        _userName = userData['name']!;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _courseService.getCourses(),
        _taskService.getTasks(),
        _scheduleService.getSessionsByDate(DateTime.now()),
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0] as List<CourseModel>;
          _tasks = results[1] as List<TaskModel>;
          _todaySessions = results[2] as List<StudySessionModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGenerateSchedule() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      await _scheduleService.generateSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Schedule generated successfully!"),
            backgroundColor: Color(0xFF3525CD),
          ),
        );
        await _loadDashboardData();
        AdService.instance.showInterstitialIfEligible(actionContext: 'generate_schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return "00:00";
    final parts = rawTime.split(':');
    if (parts.length >= 2) {
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }
    return rawTime;
  }

  StudySessionModel? get _nextSession {
    if (_todaySessions.isEmpty) return null;
    final inProgressOrPlanned = _todaySessions.where((s) {
      final status = s.status.toUpperCase();
      return status == 'IN_PROGRESS' || status == 'PLANNED';
    }).toList();

    return inProgressOrPlanned.isNotEmpty ? inProgressOrPlanned.first : _todaySessions.first;
  }

  Widget _buildDashboardContent() {
    final bool isPlanEmpty = _courses.isEmpty && _tasks.isEmpty && _todaySessions.isEmpty;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(
            color: Color(0xFF3525CD),
          ),
        ),
      );
    }

    if (isPlanEmpty) {
      return _buildEmptyStudyPlan();
    }

    // Dynamic calculations
    final completedSessions = _todaySessions.where((s) => s.status.toUpperCase() == 'COMPLETED').length;
    final totalSessions = _todaySessions.length;

    final completedMinutes = _todaySessions.fold<int>(
      0,
      (sum, s) => sum + (s.status.toUpperCase() == 'COMPLETED' ? s.plannedMinutes : s.completedMinutes),
    );
    final totalMinutes = _todaySessions.fold<int>(0, (sum, s) => sum + s.plannedMinutes);

    final completedTasksCount = _tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;

    final double progressPercent = totalMinutes > 0
        ? (completedMinutes / totalMinutes)
        : (totalSessions > 0 ? (completedSessions / totalSessions) : 0.0);

    final nextSession = _nextSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeHeader(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Good Morning, $_userName",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Here's your study plan for today.",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Dynamic Progress Card
        ProgressCard(
          completedSessions: completedSessions,
          totalSessions: totalSessions,
          completedMinutes: completedMinutes,
          totalMinutes: totalMinutes,
          progressPercent: progressPercent,
        ),
        const SizedBox(height: 16),

        // Dynamic Next Study Session Card
        if (nextSession != null) ...[
          StudySessionCard(
            subject: nextSession.taskTitle.isNotEmpty ? nextSession.taskTitle : "Task #${nextSession.taskId}",
            chapter: "Planned Duration: ${nextSession.plannedMinutes} min",
            duration: "${_formatTime(nextSession.startTime)} - ${_formatTime(nextSession.endTime)} (${nextSession.plannedMinutes} min)",
            status: nextSession.status.toLowerCase(),
          ),
          const SizedBox(height: 16),
        ],

        // Dynamic Statistics Row
        Row(
          children: [
            Expanded(
              child: StatisticsCard(
                icon: Icons.check_circle_outline,
                label: 'completed\nsessions',
                value: '$completedSessions',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatisticsCard(
                icon: Icons.timer_outlined,
                label: 'Study\nminutes',
                value: '$completedMinutes',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatisticsCard(
                icon: Icons.task_alt,
                label: 'Tasks\ncompleted',
                value: '$completedTasksCount',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dynamic Today's Schedule Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 15),
                if (_todaySessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            "No study sessions scheduled for today.",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._todaySessions.map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SchedualeItem(
                        subject: "${session.plannedMinutes} min (${session.status.toLowerCase()})",
                        title: session.taskTitle.isNotEmpty ? session.taskTitle : "Task #${session.taskId}",
                        time: _formatTime(session.startTime),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const BannerAdWidget(),
        const SizedBox(height: 20),
      ],
    );
  }

  // Home Empty Study Plan matching design screenshot 3
  Widget _buildEmptyStudyPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const HomeHeader(),
        const SizedBox(height: 25),

        // Illustration Container
        Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFF3F4F6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/study_flow_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Title
        const Text(
          "Your study plan is empty.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Add your courses and tasks, then generate your personalized study schedule.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Action Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Add Course Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEECFE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddNewCourseScreen(),
                      ),
                    );
                    _loadDashboardData();
                  },
                  icon: const Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFF3525CD),
                    size: 20,
                  ),
                  label: const Text(
                    "Add Course",
                    style: TextStyle(
                      color: Color(0xFF3525CD),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Add Task Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEECFE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedIndex = 2; // Navigate to Tasks tab
                    });
                  },
                  icon: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF3525CD),
                    size: 20,
                  ),
                  label: const Text(
                    "Add Task",
                    style: TextStyle(
                      color: Color(0xFF3525CD),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Generate Schedule Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3525CD),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isGenerating ? null : _handleGenerateSchedule,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    _isGenerating ? "Generating..." : "Generate Schedule",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const BannerAdWidget(),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget buildBody() {
    if (selectedIndex == 0) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: _buildDashboardContent(),
          ),
        ),
      );
    }
    if (selectedIndex == 1) {
      return const ScheduleScreen();
    }
    if (selectedIndex == 2) {
      return const TasksScreen();
    }
    if (selectedIndex == 3) {
      return const CoursesScreen();
    }
    if (selectedIndex == 4) {
      return const ProfileScreen();
    }
    return const Center(
      child: Text("Unknown screen"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody(),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
          if (index == 0) {
            _loadUser();
            _loadDashboardData();
          }
        },
      ),
    );
  }
}