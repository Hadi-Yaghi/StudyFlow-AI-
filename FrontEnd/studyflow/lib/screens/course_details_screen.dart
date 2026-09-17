import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../models/study_session_model.dart';
import '../services/course_service.dart';
import '../services/task_service.dart';
import '../services/schedule_service.dart';

class CourseDetailsScreen extends StatefulWidget {
  final int courseId;
  final CourseModel? initialCourse;
  final String? courseCode;
  final String? courseTitle;

  const CourseDetailsScreen({
    this.courseId = 0,
    this.initialCourse,
    this.courseCode,
    this.courseTitle,
    super.key,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseService _courseService = CourseService();
  final TaskService _taskService = TaskService();
  final ScheduleService _scheduleService = ScheduleService();

  String selectedTab = "Overview";

  CourseModel? _course;
  List<TaskModel> _tasks = [];
  List<StudySessionModel> _sessions = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _course = widget.initialCourse;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int targetCourseId = widget.courseId != 0
          ? widget.courseId
          : (_course?.id ?? 0);

      // 1. Fetch course list to resolve course details & semester if needed
      CourseModel? resolvedCourse = _course;
      if (resolvedCourse == null || resolvedCourse.semesterName == null) {
        try {
          final courses = await _courseService.getCourses();
          final match = courses.firstWhere(
            (c) => c.id == targetCourseId,
            orElse: () => resolvedCourse ?? CourseModel(
              id: targetCourseId,
              name: widget.courseTitle ?? 'Course',
              code: widget.courseCode ?? '',
              instructor: '',
              creditHours: 3,
              color: '#3525CD',
              semesterId: 0,
            ),
          );
          resolvedCourse = match;
        } catch (_) {}
      }

      // 2. Fetch course tasks
      List<TaskModel> tasks = [];
      try {
        tasks = await _taskService.getCourseTasks(targetCourseId);
      } catch (e) {
        // Fallback: fetch all tasks and filter by courseId
        try {
          final allTasks = await _taskService.getTasks();
          tasks = allTasks.where((t) => t.courseId == targetCourseId).toList();
        } catch (_) {}
      }

      // 3. Fetch course study sessions
      List<StudySessionModel> sessions = [];
      try {
        sessions = await _scheduleService.getCourseSessions(targetCourseId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _course = resolvedCourse;
          _tasks = tasks;
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    final newStatus = task.status.toUpperCase() == 'COMPLETED' ? 'TODO' : 'COMPLETED';

    // Optimistic UI update
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = TaskModel(
          id: task.id,
          title: task.title,
          description: task.description,
          type: task.type,
          priority: task.priority,
          dueDate: task.dueDate,
          estimatedHours: task.estimatedHours,
          completedHours: newStatus == 'COMPLETED' ? task.estimatedHours : 0,
          status: newStatus,
          courseId: task.courseId,
        );
      }
    });

    try {
      await _taskService.updateTaskStatus(task.id, newStatus);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update task: $e"),
            backgroundColor: Colors.red,
          ),
        );
        _loadAllData();
      }
    }
  }

  // Helper to calculate progress
  double get _progress {
    if (_tasks.isEmpty) return 0.0;
    final completed = _tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    return (completed / _tasks.length).clamp(0.0, 1.0);
  }

  int get _progressPercent {
    return (_progress * 100).round();
  }

  // Helper to get pending tasks sorted by due date
  List<TaskModel> get _upcomingDeadlines {
    final pending = _tasks.where((t) => t.status.toUpperCase() != 'COMPLETED').toList();
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending;
  }

  // Helper to get active tasks
  List<TaskModel> get _activeTasks {
    return _tasks.where((t) => t.status.toUpperCase() != 'COMPLETED').toList();
  }

  // Helper to find next upcoming session
  StudySessionModel? get _nextSession {
    if (_sessions.isEmpty) return null;
    final now = DateTime.now();
    final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final upcoming = _sessions.where((s) {
      final isNotDone = s.status.toUpperCase() != 'COMPLETED' && s.status.toUpperCase() != 'MISSED';
      return isNotDone && (s.sessionDate.compareTo(todayStr) >= 0);
    }).toList();

    upcoming.sort((a, b) {
      final dateCmp = a.sessionDate.compareTo(b.sessionDate);
      if (dateCmp != 0) return dateCmp;
      return a.startTime.compareTo(b.startTime);
    });

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  String _formatDateBadge(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        final mStr = (m >= 1 && m <= 12) ? monthNames[m - 1] : parts[1];
        return "$mStr $d";
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatRelativeDue(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(parsed.year, parsed.month, parsed.day);
        final diffDays = due.difference(today).inDays;

        if (diffDays == 0) return "Due today";
        if (diffDays == 1) return "Due tomorrow";
        if (diffDays > 1) return "Due in $diffDays days";
        if (diffDays == -1) return "Due yesterday";
        if (diffDays < -1) return "Overdue by ${-diffDays} days";
      }
    } catch (_) {}
    return "Due: $dateStr";
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return const Color(0xFF3525CD);
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF3525CD);
    }
  }

  Map<String, Color> _getTypeBadgeColors(String type) {
    switch (type.toUpperCase()) {
      case 'ASSIGNMENT':
        return {
          'bg': const Color(0xFFE0F2FE),
          'text': const Color(0xFF0369A1),
        };
      case 'QUIZ':
      case 'EXAM':
      case 'MIDTERM':
      case 'FINAL':
        return {
          'bg': const Color(0xFFFEE2E2),
          'text': const Color(0xFFDC2626),
        };
      case 'PROJECT':
        return {
          'bg': const Color(0xFFFEF3C7),
          'text': const Color(0xFFD97706),
        };
      case 'LAB':
        return {
          'bg': const Color(0xFFDCFCE7),
          'text': const Color(0xFF16A34A),
        };
      case 'HOMEWORK':
      case 'READING':
      default:
        return {
          'bg': const Color(0xFFF3E8FF),
          'text': const Color(0xFF6B21A8),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(_course?.color);

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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3525CD),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadAllData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3525CD),
                                  ),
                                  child: const Text("Retry", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF3525CD),
                          onRefresh: _loadAllData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Course Hero Card
                                _buildCourseHeroCard(themeColor),
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

                                // Content View Based on Selected Tab
                                if (selectedTab == 'Overview')
                                  _buildOverviewTab()
                                else if (selectedTab == 'Tasks')
                                  _buildTasksTab()
                                else if (selectedTab == 'Sessions')
                                  _buildSessionsTab()
                                else if (selectedTab == 'Resources')
                                  _buildResourcesTab(),
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

  Widget _buildCourseHeroCard(Color themeColor) {
    final semesterText = _course?.semesterName != null && _course!.semesterName!.trim().isNotEmpty
        ? _course!.semesterName!.trim().toUpperCase()
        : "CURRENT SEMESTER";

    final codeText = _course?.code.isNotEmpty == true ? _course!.code : widget.courseCode;
    final titleText = _course?.name.isNotEmpty == true ? _course!.name : widget.courseTitle;
    final displayTitle = (codeText != null && codeText.isNotEmpty)
        ? "$codeText: $titleText"
        : (titleText ?? "Course Details");

    final instructorText = _course?.instructor != null && _course!.instructor.trim().isNotEmpty
        ? _course!.instructor.trim()
        : "Not specified";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor,
            Color.lerp(themeColor, Colors.indigo.shade800, 0.4) ?? const Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
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
            child: Text(
              semesterText,
              style: const TextStyle(
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
            displayTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Instructor Info
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                instructorText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Course Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Course Progress",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              Text(
                "$_progressPercent%",
                style: const TextStyle(
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
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final deadlines = _upcomingDeadlines;
    final active = _activeTasks;
    final next = _nextSession;

    return Column(
      children: [
        // Upcoming Deadlines Card
        _buildSectionCard(
          title: "Upcoming Deadlines",
          child: deadlines.isEmpty
              ? _buildEmptyItem("No upcoming deadlines")
              : Column(
                  children: List.generate(deadlines.length, (index) {
                    final task = deadlines[index];
                    return Column(
                      children: [
                        if (index > 0) Divider(color: Colors.grey.shade200),
                        _buildDeadlineItem(
                          date: _formatDateBadge(task.dueDate),
                          title: task.title,
                          subtitle: _formatRelativeDue(task.dueDate),
                        ),
                      ],
                    );
                  }),
                ),
        ),
        const SizedBox(height: 16),

        // Active Tasks Card
        _buildSectionCard(
          title: "Active Tasks",
          actionText: active.isNotEmpty ? "View All" : null,
          onActionPressed: () {
            setState(() {
              selectedTab = "Tasks";
            });
          },
          child: active.isEmpty
              ? _buildEmptyItem("No active tasks")
              : Column(
                  children: List.generate(active.length, (index) {
                    final task = active[index];
                    final badgeColors = _getTypeBadgeColors(task.type);
                    return Column(
                      children: [
                        if (index > 0) Divider(color: Colors.grey.shade200),
                        _buildTaskItem(
                          task: task,
                          title: task.title,
                          badgeText: task.type.toUpperCase(),
                          badgeColor: badgeColors['bg']!,
                          textColor: badgeColors['text']!,
                          onCheckboxTapped: () => _toggleTaskStatus(task),
                        ),
                      ],
                    );
                  }),
                ),
        ),
        const SizedBox(height: 16),

        // Next Session Card
        if (next != null) ...[
          _buildSectionCard(
            title: "Next Session",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next.taskTitle.isNotEmpty ? next.taskTitle : "Study Session",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatDateBadge(next.sessionDate)}, ${next.startTime} (${next.plannedMinutes} min)",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    next.status,
                    style: const TextStyle(
                      color: Color(0xFF3525CD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return _buildSectionCard(
        title: "All Tasks",
        child: _buildEmptyItem("No tasks for this course yet."),
      );
    }

    return _buildSectionCard(
      title: "All Tasks (${_tasks.length})",
      child: Column(
        children: List.generate(_tasks.length, (index) {
          final task = _tasks[index];
          final isCompleted = task.status.toUpperCase() == 'COMPLETED';
          final badgeColors = _getTypeBadgeColors(task.type);

          return Column(
            children: [
              if (index > 0) Divider(color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleTaskStatus(task),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCompleted ? const Color(0xFF3525CD) : Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey.shade500 : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRelativeDue(task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColors['bg'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.type.toUpperCase(),
                        style: TextStyle(
                          color: badgeColors['text'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return _buildSectionCard(
        title: "Study Sessions",
        child: _buildEmptyItem("No study sessions for this course."),
      );
    }

    return _buildSectionCard(
      title: "Course Study Sessions (${_sessions.length})",
      child: Column(
        children: List.generate(_sessions.length, (index) {
          final s = _sessions[index];
          final isCompleted = s.status.toUpperCase() == 'COMPLETED';

          return Column(
            children: [
              if (index > 0) Divider(color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDateBadge(s.sessionDate),
                        style: const TextStyle(
                          color: Color(0xFF3525CD),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.taskTitle.isNotEmpty ? s.taskTitle : "Study Session",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            "${s.startTime} - ${s.endTime} (${s.plannedMinutes} min)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.status,
                        style: TextStyle(
                          color: isCompleted ? Colors.green.shade700 : const Color(0xFF3525CD),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return _buildSectionCard(
      title: "Course Resources",
      child: _buildEmptyItem("No resources available."),
    );
  }

  Widget _buildEmptyItem(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? actionText,
    VoidCallback? onActionPressed,
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
                  onPressed: onActionPressed,
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
    required TaskModel task,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color textColor,
    required VoidCallback onCheckboxTapped,
  }) {
    final isCompleted = task.status.toUpperCase() == 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onCheckboxTapped,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? const Color(0xFF3525CD) : Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey.shade500 : const Color(0xFF1F2937),
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
}
