import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class TaskItemData {
  final String id;
  final String category;
  final Color categoryBgColor;
  final Color categoryTextColor;
  final String title;
  final String dueDate;
  final int hoursEst;
  final int hoursComp;
  final int percent;
  final String status; // 'active', 'due_soon', 'completed'
  final String? priority; // 'HIGH', 'MEDIUM', 'LOW'

  TaskItemData({
    required this.id,
    required this.category,
    required this.categoryBgColor,
    required this.categoryTextColor,
    required this.title,
    required this.dueDate,
    required this.hoursEst,
    required this.hoursComp,
    required this.percent,
    required this.status,
    this.priority,
  });
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String selectedFilter = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<TaskItemData> _allTasks = [
    TaskItemData(
      id: '1',
      category: 'Software Engineering',
      categoryBgColor: const Color(0xFFEEECFE),
      categoryTextColor: const Color(0xFF3525CD),
      title: 'Build REST API',
      dueDate: 'Due Aug 15',
      hoursEst: 8,
      hoursComp: 5,
      percent: 62,
      status: 'active',
      priority: 'HIGH',
    ),
    TaskItemData(
      id: '2',
      category: 'Data Structures',
      categoryBgColor: const Color(0xFFFFF3E0),
      categoryTextColor: const Color(0xFF7C2D12),
      title: 'Implement Red-Black Tree',
      dueDate: 'Due Aug 18',
      hoursEst: 4,
      hoursComp: 1,
      percent: 25,
      status: 'due_soon',
      priority: null,
    ),
    TaskItemData(
      id: '3',
      category: 'UX Design',
      categoryBgColor: const Color(0xFFF3E8FF),
      categoryTextColor: const Color(0xFF6B21A8),
      title: 'Wireframe Dashboard',
      dueDate: 'Completed Aug 10',
      hoursEst: 3,
      hoursComp: 3,
      percent: 100,
      status: 'completed',
      priority: null,
    ),
  ];

  List<TaskItemData> get filteredTasks {
    return _allTasks.where((task) {
      bool matchesFilter = true;
      if (selectedFilter == 'Active') {
        matchesFilter = task.status == 'active';
      } else if (selectedFilter == 'Due Soon') {
        matchesFilter = task.status == 'due_soon';
      } else if (selectedFilter == 'Completed') {
        matchesFilter = task.status == 'completed';
      }

      bool matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.category.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _showAddTaskBottomSheet() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Course / Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3525CD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _allTasks.insert(
                          0,
                          TaskItemData(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            category: categoryController.text.trim().isEmpty
                                ? 'General'
                                : categoryController.text.trim(),
                            categoryBgColor: const Color(0xFFEEECFE),
                            categoryTextColor: const Color(0xFF3525CD),
                            title: titleController.text.trim(),
                            dueDate: 'Due Aug 25',
                            hoursEst: 4,
                            hoursComp: 0,
                            percent: 0,
                            status: 'active',
                            priority: 'HIGH',
                          ),
                        );
                      });
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text(
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
            Column(
              children: [
                // Top Custom Navigation Header matching design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const HomeHeader(),
                ),

                Expanded(
                  child: _allTasks.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
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
                                  return TaskCard(
                                    category: task.category,
                                    categoryBgColor: task.categoryBgColor,
                                    categoryTextColor: task.categoryTextColor,
                                    title: task.title,
                                    dueDate: task.dueDate,
                                    hoursEst: task.hoursEst,
                                    hoursComp: task.hoursComp,
                                    percent: task.percent,
                                    status: task.status,
                                    priority: task.priority,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailsScreen(
                                            title: task.title,
                                            category: task.category,
                                            dueDate: task.dueDate,
                                            priority: task.priority ?? 'High',
                                            hoursEst: task.hoursEst,
                                            hoursComp: task.hoursComp,
                                            percent: task.percent,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                ),
              ],
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
          ],
        ),
      ),
    );
  }
}
