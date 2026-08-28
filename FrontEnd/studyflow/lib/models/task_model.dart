class TaskModel {
  final int id;
  final String title;
  final String description;
  final String type; // e.g. ASSIGNMENT, EXAM, READING
  final String priority; // HIGH, MEDIUM, LOW
  final String dueDate;
  final int estimatedHours;
  final int completedHours;
  final String status; // TODO, IN_PROGRESS, COMPLETED
  final int courseId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.dueDate,
    required this.estimatedHours,
    required this.completedHours,
    required this.status,
    required this.courseId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'ASSIGNMENT',
      priority: json['priority'] ?? 'HIGH',
      dueDate: json['dueDate'] ?? '',
      estimatedHours: json['estimatedHours'] ?? 0,
      completedHours: json['completedHours'] ?? 0,
      status: json['status'] ?? 'TODO',
      courseId: json['courseId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'dueDate': dueDate,
      'estimatedHours': estimatedHours,
      'courseId': courseId,
    };
  }
}
