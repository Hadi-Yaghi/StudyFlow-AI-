import 'package:flutter/material.dart';
import '../services/course_service.dart';

class AddNewCourseScreen extends StatefulWidget {
  const AddNewCourseScreen({super.key});

  @override
  State<AddNewCourseScreen> createState() => _AddNewCourseScreenState();
}

class _AddNewCourseScreenState extends State<AddNewCourseScreen> {
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();

  String? _selectedSemester = 'Fall 2026';
  final List<String> _semesters = ['Fall 2026', 'Spring 2027', 'Summer 2027'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSemesters();
  }

  Future<void> _loadUserSemesters() async {
    try {
      final userSems = await _courseService.getSemesters();
      if (mounted && userSems.isNotEmpty) {
        setState(() {
          for (final sem in userSems) {
            final name = sem['name']?.toString();
            if (name != null && name.isNotEmpty && !_semesters.contains(name)) {
              _semesters.insert(0, name);
            }
          }
          final activeSem = userSems.firstWhere(
            (s) => s['active'] == true,
            orElse: () => {},
          );
          if (activeSem.isNotEmpty && activeSem['name'] != null) {
            _selectedSemester = activeSem['name'].toString();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _submitCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSemester == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a semester term."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _courseService.createCourse(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          instructor: _instructorController.text.trim().isEmpty
              ? 'Dr. Smith'
              : _instructorController.text.trim(),
          creditHours: 3,
          color: '#3525CD',
          semesterName: _selectedSemester,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Course created successfully!"),
              backgroundColor: Color(0xFF3525CD),
            ),
          );
          Navigator.of(context).pop(true);
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
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Back arrow + Centered StudyFlow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Title
                      const Text(
                        "Add New Course",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        "Enter the academic details below to register a new course to your active semester schedule.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form White Card Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Purple Accent Line
                              Container(
                                height: 4,
                                color: const Color(0xFF3525CD),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Course Code *
                                    const Row(
                                      children: [
                                        Text(
                                          "Course Code",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        Text(
                                          " *",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _codeController,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a course code';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: "# E.G., CS401",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Semester * Dropdown Selector
                                    const Row(
                                      children: [
                                        Text(
                                          "Semester",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        Text(
                                          " *",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedSemester,
                                      hint: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Select Term...",
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      items: _semesters.map((term) {
                                        return DropdownMenuItem<String>(
                                          value: term,
                                          child: Text(term),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSemester = val;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Course Name *
                                    const Row(
                                      children: [
                                        Text(
                                          "Course Name",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        Text(
                                          " *",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _nameController,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a course name';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.menu_book_outlined,
                                          size: 18,
                                          color: Colors.grey.shade500,
                                        ),
                                        hintText: "e.g., Database Systems",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Instructor
                                    const Text(
                                      "Instructor",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _instructorController,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          size: 18,
                                          color: Colors.grey.shade500,
                                        ),
                                        hintText: "e.g., Dr. Smith",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Divider(color: Colors.grey.shade200),
                                    const SizedBox(height: 15),

                                    // Buttons: Cancel & Add Course
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Color(0xFF4B5563),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF3525CD),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _isLoading ? null : _submitCourse,
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            _isLoading ? "Adding..." : "Add Course",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
