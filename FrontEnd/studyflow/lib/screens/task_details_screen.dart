import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/study_session_model.dart';
import '../models/task_model.dart';
import '../services/course_service.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../services/task_service.dart';
import 'study_session_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel? task;
  final String title;
  final String category;
  final String dueDate;
  final String priority;
  final int hoursEst;
  final int hoursComp;
  final int percent;
  final String description;

  const TaskDetailsScreen({
    this.task,
    this.title = "Build REST API",
    this.category = "Software Engineering",
    this.dueDate = "Aug 15, 23:59",
    this.priority = "High",
    this.hoursEst = 8,
    this.hoursComp = 5,
    this.percent = 62,
    this.description =
        "Design and implement the main RESTful endpoints for the user authentication and profile management modules. Ensure all routes are documented using Swagger and covered by unit tests. Remember to follow the MVC architecture discussed in week 4.",
    super.key,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final CourseService _courseService = CourseService();
  final ScheduleService _scheduleService = ScheduleService();

  TaskModel? _currentTask;
  String _categoryName = "";
  List<CourseModel> _courses = [];
  List<StudySessionModel> _linkedSessions = [];
  bool _isLoadingSessions = false;
  bool _hasChanges = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _categoryName = widget.category;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load courses to resolve course names and support editing
    try {
      final courses = await _courseService.getCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          if (_currentTask != null) {
            final courseMatch = _courses.where((c) => c.id == _currentTask!.courseId).toList();
            if (courseMatch.isNotEmpty) {
              _categoryName = courseMatch.first.name;
            }
          }
        });
      }
    } catch (_) {}

    // Load linked sessions for real task
    if (_currentTask != null) {
      _loadLinkedSessions();
    }
  }

  Future<void> _loadLinkedSessions() async {
    if (_currentTask == null) return;
    setState(() {
      _isLoadingSessions = true;
    });
    try {
      final sessions = await _scheduleService.getTaskSessions(_currentTask!.id);
      if (mounted) {
        setState(() {
          _linkedSessions = sessions;
          _isLoadingSessions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  String _formatDueDate(String rawDate) {
    if (rawDate.isEmpty) return "No Due Date";
    try {
      final parsed = DateTime.parse(rawDate);
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "Due ${monthNames[parsed.month - 1]} ${parsed.day}";
    } catch (_) {
      return "Due $rawDate";
    }
  }

  Map<String, Color> _getPriorityColors(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return {
          'bg': const Color(0xFFFEE2E2),
          'text': const Color(0xFFDC2626),
          'icon': const Color(0xFFDC2626),
        };
      case 'LOW':
        return {
          'bg': const Color(0xFFDCFCE7),
          'text': const Color(0xFF16A34A),
          'icon': const Color(0xFF16A34A),
        };
      case 'MEDIUM':
      default:
        return {
          'bg': const Color(0xFFFEF3C7),
          'text': const Color(0xFFD97706),
          'icon': const Color(0xFFD97706),
        };
    }
  }

  void _handlePop() {
    if (_hasChanges) {
      Navigator.of(context).pop({'updated': true, 'task': _currentTask});
    } else {
      Navigator.of(context).pop();
    }
  }

  // ==========================================
  // EDIT TASK MODAL
  // ==========================================
  void _showEditTaskModal() {
    if (_currentTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot edit preview task without database record")),
      );
      return;
    }

    final task = _currentTask!;
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final estHoursController = TextEditingController(text: task.estimatedHours.toString());
    final compHoursController = TextEditingController(text: task.completedHours.toString());

    int? selectedCourseId = task.courseId != 0 ? task.courseId : (_courses.isNotEmpty ? _courses.first.id : null);
    final supportedTypes = ['ASSIGNMENT', 'HOMEWORK', 'QUIZ', 'MIDTERM', 'FINAL', 'EXAM', 'PROJECT', 'LAB', 'READING', 'OTHER'];
    String selectedType = task.type.isNotEmpty ? task.type.toUpperCase() : "ASSIGNMENT";
    if (!supportedTypes.contains(selectedType)) {
      selectedType = 'ASSIGNMENT';
    }

    String selectedPriority = task.priority.isNotEmpty ? task.priority.toUpperCase() : "HIGH";
    if (!['HIGH', 'MEDIUM', 'LOW'].contains(selectedPriority)) {
      selectedPriority = 'HIGH';
    }

    String selectedStatus = task.status.isNotEmpty ? task.status.toUpperCase() : "TODO";
    if (!['TODO', 'IN_PROGRESS', 'COMPLETED'].contains(selectedStatus)) {
      selectedStatus = 'TODO';
    }

    DateTime selectedDueDate;
    try {
      selectedDueDate = DateTime.parse(task.dueDate);
    } catch (_) {
      selectedDueDate = DateTime.now().add(const Duration(days: 7));
    }

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Edit Task",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3525CD),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'e.g., Build REST API',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Course Selector
                    if (_courses.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        value: selectedCourseId,
                        decoration: InputDecoration(
                          labelText: 'Course *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _courses.map((course) {
                          return DropdownMenuItem<int>(
                            value: course.id,
                            child: Text("${course.code} - ${course.name}"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedCourseId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Type & Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ASSIGNMENT', child: Text('Assignment')),
                              DropdownMenuItem(value: 'HOMEWORK', child: Text('Homework')),
                              DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                              DropdownMenuItem(value: 'MIDTERM', child: Text('Midterm')),
                              DropdownMenuItem(value: 'FINAL', child: Text('Final')),
                              DropdownMenuItem(value: 'EXAM', child: Text('Exam')),
                              DropdownMenuItem(value: 'PROJECT', child: Text('Project')),
                              DropdownMenuItem(value: 'LAB', child: Text('Lab')),
                              DropdownMenuItem(value: 'READING', child: Text('Reading')),
                              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedType = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'HIGH', child: Text('High')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                              DropdownMenuItem(value: 'LOW', child: Text('Low')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedPriority = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TODO', child: Text('To Do')),
                        DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Estimated Hours & Completed Hours Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: estHoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Est. Hours *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: compHoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Completed Hours',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Due Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF3525CD)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about this task...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3525CD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting || selectedCourseId == null
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Task title is required")),
                                  );
                                  return;
                                }

                                final estHours = int.tryParse(estHoursController.text.trim());
                                if (estHours == null || estHours <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Estimated hours must be at least 1")),
                                  );
                                  return;
                                }

                                final compHours = int.tryParse(compHoursController.text.trim()) ?? 0;
                                if (compHours < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Completed hours cannot be negative")),
                                  );
                                  return;
                                }

                                if (compHours > estHours) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Completed hours cannot exceed estimated hours")),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final formattedDate =
                                      "${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}";

                                  final updated = await _taskService.updateTask(
                                    taskId: task.id,
                                    title: title,
                                    description: descriptionController.text.trim(),
                                    type: selectedType,
                                    priority: selectedPriority,
                                    dueDate: formattedDate,
                                    estimatedHours: estHours,
                                    completedHours: compHours,
                                    status: selectedStatus,
                                    courseId: selectedCourseId!,
                                  );

                                  if (sheetCtx.mounted) {
                                    Navigator.of(sheetCtx).pop();
                                  }

                                  if (mounted) {
                                    setState(() {
                                      _currentTask = updated;
                                      _hasChanges = true;
                                      final courseMatch = _courses.where((c) => c.id == updated.courseId).toList();
                                      if (courseMatch.isNotEmpty) {
                                        _categoryName = courseMatch.first.name;
                                      }
                                    });

                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text("Task updated successfully!"),
                                        backgroundColor: Color(0xFF3525CD),
                                      ),
                                    );

                                    // Refresh linked sessions and device notifications
                                    _loadLinkedSessions();
                                    NotificationService.instance.syncNotificationsWithDatabase();
                                  }
                                } catch (e) {
                                  if (sheetCtx.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                  if (mounted) {
                                    String msg = e.toString().replaceAll('Exception: ', '').trim();
                                    if (msg.contains('Cannot deserialize') ||
                                        msg.contains('TaskType') ||
                                        msg.contains('Invalid task type') ||
                                        msg.contains('com.') ||
                                        msg.contains('org.') ||
                                        msg.contains('<EOL>')) {
                                      msg = "Unable to save the task. Please check the task type and try again.";
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // DELETE TASK CONFIRMATION
  // ==========================================
  Future<void> _confirmAndDeleteTask() async {
    if (_currentTask == null || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Delete task?",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: Color(0xFF111827),
            ),
          ),
          content: const Text(
            "This will permanently delete this task and remove its future planned study sessions.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final taskId = _currentTask!.id;

    try {
      await _taskService.deleteTask(taskId);

      // Cancel local scheduled notifications
      await NotificationService.instance.cancelTaskNotification(taskId);
      for (final s in _linkedSessions) {
        await NotificationService.instance.cancelSessionNotifications(s.id);
      }
      NotificationService.instance.syncNotificationsWithDatabase();

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Task deleted successfully"),
            backgroundColor: Color(0xFF3525CD),
          ),
        );
        Navigator.of(context).pop({'deleted': true, 'taskId': taskId});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text("Failed to delete task: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve display values
    final String displayTitle = _currentTask?.title ?? widget.title;
    final String displayCategory = _categoryName.isNotEmpty ? _categoryName : widget.category;
    final String displayDueDate = _currentTask != null ? _formatDueDate(_currentTask!.dueDate) : widget.dueDate;
    final String displayPriority = _currentTask?.priority ?? widget.priority;
    final int displayEst = _currentTask?.estimatedHours ?? widget.hoursEst;
    final int displayComp = _currentTask?.completedHours ?? widget.hoursComp;
    final int hoursRemaining = displayEst - displayComp > 0 ? displayEst - displayComp : 0;
    final int displayPercent = displayEst > 0
        ? ((displayComp / displayEst) * 100).round().clamp(0, 100)
        : widget.percent;
    final String displayDesc = _currentTask != null
        ? (_currentTask!.description.isNotEmpty ? _currentTask!.description : "No description provided.")
        : widget.description;

    final priorityColors = _getPriorityColors(displayPriority);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: _handlePop,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            displayCategory,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isDeleting)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      )
                    else
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF1F2937),
                        ),
                        onSelected: (value) {
                          if (value == 'Edit') {
                            _showEditTaskModal();
                          } else if (value == 'Delete') {
                            _confirmAndDeleteTask();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1F2937)),
                                SizedBox(width: 10),
                                Text('Edit Task'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'Delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                SizedBox(width: 10),
                                Text(
                                  'Delete Task',
                                  style: TextStyle(color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      // Top Row Cards: Deadline Card & Priority Card
                      Row(
                        children: [
                          // Deadline Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
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
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Color(0xFFDC2626),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Deadline",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    displayDueDate,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Priority Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
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
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.priority_high,
                                            size: 16,
                                            color: priorityColors['icon'],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Priority",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: priorityColors['bg'],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          displayPriority.toUpperCase(),
                                          style: TextStyle(
                                            color: priorityColors['text'],
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    displayPriority.toUpperCase() == 'HIGH'
                                        ? "Must Complete"
                                        : (displayPriority.toUpperCase() == 'LOW' ? "Optional" : "Normal"),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Overall Progress Card
                      Container(
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Overall Progress",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "$displayPercent%",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF3525CD),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (displayPercent / 100.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3525CD),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Tracking Card
                      Container(
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
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Time Tracking",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 24,
                              color: Colors.grey.shade200,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "${displayComp}h",
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          " / ${displayEst}h",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Completed vs Estimated",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${hoursRemaining}h",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Remaining",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (displayPercent / 100.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3525CD),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description Card
                      Container(
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
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayDesc,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Study Sessions Card
                      Container(
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 20,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Study Sessions",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            if (_isLoadingSessions)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Text(
                                _currentTask != null
                                    ? "${_linkedSessions.length} linked"
                                    : "2 linked",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Full-Width Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
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
                      final sessionTitle = _linkedSessions.isNotEmpty
                          ? _linkedSessions.first.taskTitle
                          : displayTitle;
                      final timeInfo = _linkedSessions.isNotEmpty
                          ? "${_linkedSessions.first.startTime} - ${_linkedSessions.first.endTime} (${_linkedSessions.first.plannedMinutes} min)"
                          : "18:00 - 19:30 (90 min)";

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudySessionScreen(
                            courseTitle: displayCategory,
                            sessionTitle: sessionTitle,
                            timeInfo: timeInfo,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: const Text(
                      "Start Linked Session",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
