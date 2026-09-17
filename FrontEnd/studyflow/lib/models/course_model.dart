class CourseModel {
  final int id;
  final String name;
  final String code;
  final String instructor;
  final int creditHours;
  final String color;
  final int semesterId;
  final String? semesterName;

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.instructor,
    required this.creditHours,
    required this.color,
    required this.semesterId,
    this.semesterName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      instructor: json['instructor'] ?? '',
      creditHours: json['creditHours'] ?? 3,
      color: json['color'] ?? '#3525CD',
      semesterId: json['semesterId'] ?? 0,
      semesterName: json['semesterName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'instructor': instructor,
      'creditHours': creditHours,
      'color': color,
      'semesterId': semesterId,
      'semesterName': semesterName,
    };
  }
}
