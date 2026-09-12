import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../services/course_service.dart';
import '../services/task_service.dart';
import '../widgets/home_header.dart';
import '../widgets/task_card.dart';
import 'add_new_course_screen.dart';
import 'task_details_screen.dart';
import '../services/ad_service.dart';
import '../widgets/ads/banner_ad_widget.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final CourseService _courseService = CourseService();

  String selectedFilter = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<TaskModel> _allTasks = [];
  List<CourseModel> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _taskService.getTasks(),
        _courseService.getCourses(),
      ]);

      if (mounted) {
        setState(() {
          _allTasks = results[0] as List<TaskModel>;
          _courses = results[1] as List<CourseModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allTasks = [];
          _courses = [];
          _isLoading = false;
        });
      }
    }
  }

  CourseModel? _getCourseForTask(int courseId) {
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
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

  String _mapTaskStatus(TaskModel task) {
    final status = task.status.toUpperCase();
    if (status == 'COMPLETED') return 'completed';

    if (task.dueDate.isNotEmpty) {
      try {
        final due = DateTime.parse(task.dueDate);
        final now = DateTime.now();
        final diff = due.difference(now).inDays;
        if (diff >= 0 && diff <= 3) {
          return 'due_soon';
        }
      } catch (_) {}
    }
    return 'active';
  }

  int _calculatePercent(TaskModel task) {
    if (task.status.toUpperCase() == 'COMPLETED') return 100;
    if (task.estimatedHours > 0) {
      return ((task.completedHours / task.estimatedHours) * 100).round().clamp(0, 100);
    }
    return 0;
  }

  List<TaskModel> get filteredTasks {
    return _allTasks.where((task) {
      final uiStatus = _mapTaskStatus(task);
      bool matchesFilter = true;
      if (selectedFilter == 'Active') {
        matchesFilter = uiStatus == 'active';
      } else if (selectedFilter == 'Due Soon') {
        matchesFilter = uiStatus == 'due_soon';
      } else if (selectedFilter == 'Completed') {
        matchesFilter = uiStatus == 'completed';
      }

      final course = _getCourseForTask(task.courseId);
      final courseName = course?.name ?? '';
      final courseCode = course?.code ?? '';

      bool matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          courseName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          courseCode.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _showAddTaskBottomSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final estHoursController = TextEditingController(text: "4");
    int? selectedCourseId = _courses.isNotEmpty ? _courses.first.id : null;
    String selectedType = "ASSIGNMENT";
    String selectedPriority = "HIGH";
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                          "Add New Task",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3525CD),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
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
                    if (_courses.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "No courses found. Please add a course first.",
                                style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const AddNewCourseScreen()),
                                );
                                _loadData();
                              },
                              child: const Text("Add Course"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
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
                              DropdownMenuItem(value: 'EXAM', child: Text('Exam')),
                              DropdownMenuItem(value: 'READING', child: Text('Reading')),
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

                    // Estimated Hours & Due Date Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: estHoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Est. Hours',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedDueDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Due Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about this task...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
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
                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Task title is required")),
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

                                  await _taskService.createTask(
                                    title: titleController.text.trim(),
                                    description: descriptionController.text.trim(),
                                    type: selectedType,
                                    priority: selectedPriority,
                                    dueDate: formattedDate,
                                    estimatedHours: int.tryParse(estHoursController.text) ?? 4,
                                    courseId: selectedCourseId!,
                                  );

                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text("Task created successfully!"),
                                        backgroundColor: Color(0xFF3525CD),
                                      ),
                                    );
                                    _loadData();
                                    AdService.instance.showInterstitialIfEligible(actionContext: 'task_created');
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceAll('Exception: ', '')),
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
                                "Create Task",
                                style: TextStyle(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const HomeHeader(),
                  ),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3525CD),
                            ),
                          )
                        : _allTasks.isEmpty
                            ? _buildEmptyState()
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),

                                    // Search Input Box
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (value) {
                                          setState(() {
                                            searchQuery = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: "Search tasks...",
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 15,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Colors.grey.shade500,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Filter Pills Bar
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: ['All', 'Active', 'Due Soon', 'Completed']
                                            .map((filter) {
                                          final bool isSelected = selectedFilter == filter;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 10),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedFilter = filter;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF3525CD)
                                                      : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(0xFF3525CD)
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  filter,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(0xFF4B5563),
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
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

                                    // Tasks List
                                    if (filteredTasks.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 40),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "No matching tasks found",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    else
                                      ...filteredTasks.map((task) {
                                        final course = _getCourseForTask(task.courseId);
                                        final categoryName = course != null
                                            ? "${course.code} - ${course.name}"
                                            : "Course #${task.courseId}";

                                        final uiStatus = _mapTaskStatus(task);
                                        final percent = _calculatePercent(task);

                                        return TaskCard(
                                          category: categoryName,
                                          categoryBgColor: const Color(0xFFEEECFE),
                                          categoryTextColor: const Color(0xFF3525CD),
                                          title: task.title,
                                          dueDate: _formatDueDate(task.dueDate),
                                          hoursEst: task.estimatedHours,
                                          hoursComp: task.completedHours,
                                          percent: percent,
                                          status: uiStatus,
                                          priority: task.priority,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => TaskDetailsScreen(
                                                  title: task.title,
                                                  category: categoryName,
                                                  dueDate: _formatDueDate(task.dueDate),
                                                  priority: task.priority,
                                                  hoursEst: task.estimatedHours,
                                                  hoursComp: task.completedHours,
                                                  percent: percent,
                                                  description: task.description.isNotEmpty
                                                      ? task.description
                                                      : "No description provided.",
                                                ),
                                              ),
                                            ).then((_) => _loadData());
                                          },
                                        );
                                      }),

                                    const SizedBox(height: 12),
                                    const BannerAdWidget(),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),

            // Floating Action Button when tasks exist
            if (_allTasks.isNotEmpty)
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: _showAddTaskBottomSheet,
                  backgroundColor: const Color(0xFF3525CD),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tasks Empty State Layout matching design screenshot 2
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large Circle with Clipboard & Plus Icon
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  Positioned(
                    bottom: 34,
                    right: 34,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_circle,
                        size: 26,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              "No tasks yet",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              "Create your first task to start planning your study schedule.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // + Add Task Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3525CD),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _showAddTaskBottomSheet,
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Add Task",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
