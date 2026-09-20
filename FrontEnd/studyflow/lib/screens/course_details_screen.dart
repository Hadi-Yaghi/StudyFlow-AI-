import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../models/study_session_model.dart';
import '../models/course_material_model.dart';
import '../models/ai_study_plan_model.dart';
import '../services/course_service.dart';
import '../services/task_service.dart';
import '../services/schedule_service.dart';
import '../services/course_material_service.dart';
import '../services/ai_study_service.dart';
import '../utils/feature_gate.dart';
import 'task_details_screen.dart';

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
  List<CourseMaterial> _materials = [];

  bool _isLoading = true;
  bool _isUploading = false;
  double? _uploadProgress;
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

      // 4. Fetch course materials (viewable by both Free and Pro)
      List<CourseMaterial> materials = [];
      try {
        materials = await CourseMaterialService.instance.getMaterials(targetCourseId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _course = resolvedCourse;
          _tasks = tasks;
          _sessions = sessions;
          _materials = materials;
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
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TaskDetailsScreen(
                                  task: task,
                                  category: _course?.name ?? '',
                                ),
                              ),
                            );
                            _loadAllData();
                          },
                          child: _buildDeadlineItem(
                            date: _formatDateBadge(task.dueDate),
                            title: task.title,
                            subtitle: _formatRelativeDue(task.dueDate),
                          ),
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
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(
                                task: task,
                                category: _course?.name ?? '',
                              ),
                            ),
                          );
                          _loadAllData();
                        },
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

  int get _targetCourseId => widget.courseId != 0 ? widget.courseId : (_course?.id ?? 0);

  Widget _buildResourcesTab() {
    final bool canUpload = FeatureGate.access.canUploadCourseFiles;
    final bool canUseAi = FeatureGate.access.canUseAi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Card: Upload Material & AI Study Plan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3525CD).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.folder_shared_rounded,
                          color: Color(0xFF3525CD),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Course Materials",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_materials.length} ${_materials.length == 1 ? 'file' : 'files'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Upload course documents (PDF, DOCX, PPTX, TXT) to generate optimized, AI-powered study schedules.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Upload and AI Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _handleUploadMaterial,
                      icon: Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: canUpload ? const Color(0xFF3525CD) : Colors.grey.shade700,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isUploading ? "Uploading..." : "Upload File",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: canUpload ? const Color(0xFF3525CD) : Colors.grey.shade700,
                            ),
                          ),
                          if (!canUpload) ...[
                            const SizedBox(width: 6),
                            _buildProBadge(),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: canUpload ? const Color(0xFF3525CD).withOpacity(0.4) : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleAiStudyPlan,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "AI Study Plan",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (!canUseAi) ...[
                            const SizedBox(width: 6),
                            _buildProBadge(light: true),
                          ],
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3525CD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isUploading) ...[
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _uploadProgress != null && _uploadProgress! >= 1.0
                              ? "Finishing upload..."
                              : "Uploading course material...",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _uploadProgress != null
                              ? (_uploadProgress! >= 1.0 ? "100%" : "${(_uploadProgress! * 100).toInt()}%")
                              : "Processing...",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Materials List
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Uploaded Files",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              if (_materials.isEmpty)
                _buildEmptyItem("No files uploaded for this course yet.")
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _materials.length,
                  separatorBuilder: (context, index) => Divider(height: 16, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final material = _materials[index];
                    return _buildMaterialItem(material);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialItem(CourseMaterial material) {
    final ext = material.fileExtension;
    Color iconBg = Colors.grey.shade100;
    Color iconColor = Colors.grey.shade700;
    IconData iconData = Icons.insert_drive_file_rounded;

    if (ext == 'PDF') {
      iconBg = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      iconData = Icons.picture_as_pdf_rounded;
    } else if (ext == 'DOCX' || ext == 'DOC') {
      iconBg = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
      iconData = Icons.description_rounded;
    } else if (ext == 'PPTX' || ext == 'PPT') {
      iconBg = Colors.orange.shade50;
      iconColor = Colors.orange.shade800;
      iconData = Icons.slideshow_rounded;
    } else if (ext == 'TXT') {
      iconBg = Colors.teal.shade50;
      iconColor = Colors.teal.shade700;
      iconData = Icons.text_snippet_rounded;
    }

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(iconData, color: iconColor, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                material.originalFilename,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    material.formattedFileSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "•",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${material.uploadedAt.year}-${material.uploadedAt.month.toString().padLeft(2, '0')}-${material.uploadedAt.day.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
          tooltip: "Delete",
          onPressed: () => _confirmDeleteMaterial(material),
        ),
      ],
    );
  }

  Widget _buildProBadge({bool light = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: light ? Colors.amber.shade300 : Colors.amber.shade600,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "PRO",
        style: TextStyle(
          color: light ? Colors.black87 : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _handleUploadMaterial() async {
    final canUpload = FeatureGate.access.canUploadCourseFiles;

    // RULE: If Free user presses Upload File, do NOT open the file picker first. Show StudyFlow Pro required.
    if (!canUpload) {
      FeatureGate.requirePro(
        context,
        onUnlocked: () => _handleUploadMaterial(),
        featureName: "Course Material Uploads",
      );
      return;
    }

    // PRO USER: Open file picker
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx', 'txt'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final filePath = file.path;
      if (filePath == null) return;

      // Validate 25MB limit on frontend
      const maxBytes = 25 * 1024 * 1024;
      final fileOnDisk = File(filePath);
      if (await fileOnDisk.length() > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File exceeds maximum allowed size of 25 MB.")),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final newMaterial = await CourseMaterialService.instance.uploadMaterial(
        courseId: _targetCourseId,
        filePath: filePath,
        filename: file.name,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() {
              _uploadProgress = (sent / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      // Successfully uploaded: update list immediately so file appears with zero lag
      if (mounted) {
        setState(() {
          _materials.removeWhere((m) => m.id == newMaterial.id);
          _materials.insert(0, newMaterial);
          _isUploading = false;
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully uploaded '${file.name}'"),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      // Also refresh full list from backend to ensure complete synchronization
      try {
        final refreshed = await CourseMaterialService.instance.getMaterials(_targetCourseId);
        if (mounted && refreshed.isNotEmpty) {
          setState(() {
            _materials = refreshed;
          });
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });

        if (e.toString().contains('PREMIUM_REQUIRED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Course file upload requires an active StudyFlow Pro subscription on your account."),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload failed: ${e.toString().replaceAll('Exception: ', '')}"),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteMaterial(CourseMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Material"),
        content: Text("Are you sure you want to delete '${material.originalFilename}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CourseMaterialService.instance.deleteMaterial(_targetCourseId, material.id);
        final refreshed = await CourseMaterialService.instance.getMaterials(_targetCourseId);
        if (mounted) {
          setState(() {
            _materials = refreshed;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Material deleted successfully.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete: $e")),
          );
        }
      }
    }
  }

  Future<void> _handleAiStudyPlan() async {
    final canUseAi = FeatureGate.access.canUseAi;

    // RULE: If Free user taps AI feature -> show StudyFlow Pro upgrade/paywall.
    if (!canUseAi) {
      FeatureGate.requirePro(
        context,
        onUnlocked: () => _handleAiStudyPlan(),
        featureName: "AI Study Planning",
      );
      return;
    }

    if (_materials.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF3525CD)),
              SizedBox(width: 8),
              Text("Upload Materials First"),
            ],
          ),
          content: const Text(
            "Please upload at least one course material (syllabus, lecture slides, or readings) before running AI Study Planning.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleUploadMaterial();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3525CD),
                foregroundColor: Colors.white,
              ),
              child: const Text("Upload Document"),
            ),
          ],
        ),
      );
      return;
    }

    // PRO: Present AI Study Planning Sheet
    _showAiStudyPlanBottomSheet();
  }

  void _showAiStudyPlanBottomSheet() {
    final selectedMaterialIds = _materials.map((m) => m.id).toSet();
    final messenger = ScaffoldMessenger.of(context);
    bool isGenerating = false;
    String currentStep = "Ready";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3525CD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFF3525CD), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "AI Study Planner",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (!isGenerating)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Select course materials to analyze. StudyFlow AI will extract key topics, estimate study workload, and schedule sessions with zero time conflicts.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Materials to Analyze:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView(
                      shrinkWrap: true,
                      children: _materials.map((material) {
                        final isSelected = selectedMaterialIds.contains(material.id);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            material.originalFilename,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            material.formattedFileSize,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          value: isSelected,
                          activeColor: const Color(0xFF3525CD),
                          onChanged: isGenerating
                              ? null
                              : (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedMaterialIds.add(material.id);
                                    } else {
                                      if (selectedMaterialIds.length > 1) {
                                        selectedMaterialIds.remove(material.id);
                                      }
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isGenerating) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3525CD).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3525CD).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3525CD)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              currentStep,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3525CD),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setModalState(() {
                                isGenerating = true;
                                currentStep = "Extracting course text...";
                              });

                              try {
                                // Simulate multi-step progress feedback for responsive UX
                                await Future.delayed(const Duration(milliseconds: 600));
                                if (context.mounted) {
                                  setModalState(() {
                                    currentStep = "AI analyzing topics & study requirements...";
                                  });
                                }

                                final plan = await AiStudyService.instance.generatePlanForCourse(
                                  courseId: _targetCourseId,
                                  materialIds: selectedMaterialIds.toList(),
                                );

                                if (context.mounted) {
                                  setModalState(() {
                                    currentStep = "Generating conflict-free sessions...";
                                  });
                                }
                                await Future.delayed(const Duration(milliseconds: 400));

                                // Reload parent screen data
                                await _loadAllData();

                                if (context.mounted) {
                                  Navigator.pop(context); // Close sheet
                                  _showAiPlanSuccessDialog(plan);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setModalState(() {
                                    isGenerating = false;
                                  });
                                  Navigator.pop(context);
                                }
                                if (mounted) {
                                  String message = e.toString().replaceAll('Exception: ', '').trim();
                                  if (message.contains('models/') ||
                                      message.contains('gemini') ||
                                      message.contains('AI_PROCESSING') ||
                                      message.contains('AI_PROVIDER') ||
                                      message.contains('com.') ||
                                      message.contains('org.') ||
                                      message.contains('<EOL>') ||
                                      message.contains('500') ||
                                      message.contains('503') ||
                                      message.isEmpty) {
                                    message = "AI study planning is temporarily unavailable. Please try again.";
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3525CD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Analyze & Generate Schedule",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAiPlanSuccessDialog(AiStudyPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Study Plan Generated!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "StudyFlow AI successfully analyzed your materials and scheduled study sessions into your planner.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Topics Discovered", "${plan.topics.length}"),
                  const Divider(height: 14),
                  _buildSummaryRow("Study Sessions Created", "${plan.generatedSessionsCount}"),
                  const Divider(height: 14),
                  _buildSummaryRow("Total Study Time", "${plan.scheduledMinutes} minutes"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                selectedTab = "Sessions";
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3525CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("View Sessions"),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
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
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskDetailsScreen(
                      task: task,
                      category: _course?.name ?? '',
                    ),
                  ),
                );
                _loadAllData();
              },
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
